import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ImportApiService {
  /// Imports Chart of Accounts (GL Master) records from CSV bytes.
  /// Parses each row, maps columns per [mappings], resolves glCatCd by name,
  /// and POSTs each record to /gl-master individually.
  Future<Map<String, dynamic>> importCompanyGlData(
    Uint8List bytes,
    String filename,
    String eUser,
    String duplicateHandling,
    Map<String, String?> mappings,
  ) async {
    try {
      // ── 1. Decode CSV ──────────────────────────────────────────────────
      final csvString = utf8.decode(bytes);
      final rows = _parseCSV(csvString);
      if (rows.length < 2) {
        return {'status': 'ERROR', 'message': 'File has no data rows to import.'};
      }

      final headers  = rows.first;
      final dataRows = rows.skip(1).toList();

      print('📤 Import: ${dataRows.length} data rows from "$filename"');

      // ── 2. Load GL Categories for name→id lookup ───────────────────────
      final categoryMap = await _loadCategoryMap();
      print('📋 GL Categories loaded: $categoryMap');

      // ── 3. Load existing accounts: names, orgCode, maxGlNo ────────────
      final existing     = await _loadExistingAccountsAndOrgCode();
      final existingNames = existing['names']   as Set<String>;
      final orgCode       = existing['orgCode'] as int;
      final maxGlNo       = existing['maxGlNo'] as int;
      print('📋 Existing: ${existingNames.length} accounts, orgCode=$orgCode, maxGlNo=$maxGlNo');

      // ── 4. Resolve column indices ──────────────────────────────────────
      int idx(String? col) => col != null ? headers.indexOf(col) : -1;

      final nameIdx    = idx(mappings['Account Name']);
      final codeIdx    = idx(mappings['Account Code']);
      final typeIdx    = idx(mappings['Account Type']);
      final descIdx    = idx(mappings['Description']);
      final currIdx    = idx(mappings['Currency']);
      final parentIdx  = idx(mappings['Parent Account']);
      final balanceIdx = idx(mappings['Opening Balance']);

      // ── 5. Audit fields ────────────────────────────────────────────────
      final now      = DateTime.now().toUtc();
      final nowIso   = '${now.toIso8601String().split('.').first}.000+00:00';
      final cleanUser = eUser.contains('@') ? eUser.split('@').first : eUser;

      // ── 6. Import rows ─────────────────────────────────────────────────
      int imported  = 0;
      int skipped   = 0;
      int autoGlNo  = maxGlNo; // auto-increment if glNo not in CSV
      final List<String> errors = [];
      final Set<String>  seenNames = {};

      for (int i = 0; i < dataRows.length; i++) {
        final row    = dataRows[i];
        final rowNum = i + 2;

        String cell(int colIdx) =>
            (colIdx >= 0 && colIdx < row.length) ? row[colIdx].trim() : '';

        final glName   = cell(nameIdx);
        final glNoRaw  = cell(codeIdx);
        final typeName = cell(typeIdx);
        final desc     = cell(descIdx);
        final currency = cell(currIdx);
        final parent   = cell(parentIdx);
        final balance  = cell(balanceIdx);

        // Skip empty Account Name rows
        if (glName.isEmpty) {
          skipped++;
          errors.add('Row $rowNum: Account Name is empty — skipped.');
          continue;
        }

        // Skip empty Account Type rows (if mapped)
        if (typeName.isEmpty && typeIdx != -1) {
          skipped++;
          errors.add('Row $rowNum: Account Type is empty — skipped.');
          continue;
        }

        // Duplicate handling
        final nameKey = glName.toLowerCase();
        if (duplicateHandling == 'skip') {
          if (seenNames.contains(nameKey) || existingNames.contains(nameKey)) {
            skipped++;
            errors.add('Row $rowNum: "$glName" is a duplicate — skipped.');
            continue;
          }
        }
        seenNames.add(nameKey);

        // Resolve glCatCd from category name
        final glCatCd = _resolveCategory(typeName, categoryMap);

        // glNo: use CSV value, or auto-generate
        int glNo = int.tryParse(glNoRaw.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        if (glNo == 0) {
          autoGlNo++;
          glNo = autoGlNo;
        }

        // Opening balance
        final openingBal = double.tryParse(
            balance.replaceAll(RegExp(r'[^\d.\-]'), '')) ?? 0.0;

        final payload = {
          'orgCode': orgCode,
          'glNo':    glNo,
          'glName':  glName,
          'glCatCd': glCatCd,
          'status':  1,
          if (desc.isNotEmpty)     'gldesc':         desc,
          if (currency.isNotEmpty) 'currency':       currency,
          if (parent.isNotEmpty)   'parentAccount':  parent,
          if (openingBal != 0.0)   'openingBalance': openingBal,
          // Audit fields — same as GL Master form
          'cUser': cleanUser, 'cuser': cleanUser,
          'cDate': nowIso,    'cdate': nowIso,
          'eUser': cleanUser, 'euser': cleanUser,
          'eDate': nowIso,    'edate': nowIso,
          'aUser': cleanUser, 'auser': cleanUser,
          'aDate': nowIso,    'adate': nowIso,
        };

        print('📤 Row $rowNum: glName=$glName glNo=$glNo glCatCd=$glCatCd orgCode=$orgCode');
        print('📤 Payload: ${jsonEncode(payload)}');

        try {
          final res = await http.post(
            Uri.parse('${ApiService.baseUrl}/gl-master'),
            headers: apiService.headers,
            body: jsonEncode(payload),
          );

          print('📥 Row $rowNum: ${res.statusCode} — ${res.body}');

          if (res.statusCode >= 200 && res.statusCode < 300) {
            imported++;
          } else {
            skipped++;
            final msg = _extractError(res.body, res.statusCode);
            errors.add('Row $rowNum "$glName": $msg');
            print('❌ Row $rowNum failed: $msg');
          }
        } catch (e) {
          skipped++;
          errors.add('Row $rowNum "$glName": $e');
        }
      }

      print('✅ Done: $imported imported, $skipped skipped');

      final status  = imported > 0 ? 'SUCCESS' : 'ERROR';
      final message = imported > 0
          ? 'Imported $imported record(s) successfully. $skipped skipped.'
          : 'No records imported. $skipped failed/skipped.';

      return {
        'status':   status,
        'message':  message,
        'imported': imported,
        'skipped':  skipped,
        'errors':   errors,
      };
    } catch (e) {
      print('❌ importCompanyGlData: $e');
      return {'status': 'ERROR', 'message': 'Import failed: $e'};
    }
  }

  // ── Load GL categories: name → glCatCd ───────────────────────────────────
  Future<Map<String, int>> _loadCategoryMap() async {
    final map = <String, int>{};
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/gl-category?page=0&size=1000'),
        headers: apiService.headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> items = decoded is List
            ? decoded
            : (decoded is Map ? decoded['content'] ?? [] : []);
        for (final item in items) {
          final name = (item['glCatName'] ?? item['glcatname'] ?? '').toString();
          final cd   = item['glCatCd'] ?? item['glcatcd'];
          final id   = cd is int ? cd : int.tryParse(cd.toString()) ?? 0;
          if (name.isNotEmpty && id != 0) map[name] = id;
        }
      }
    } catch (e) {
      print('⚠️ _loadCategoryMap: $e');
    }
    return map;
  }

  // ── Load existing accounts + orgCode + maxGlNo ────────────────────────────
  Future<Map<String, dynamic>> _loadExistingAccountsAndOrgCode() async {
    final names = <String>{};
    int orgCode = 50;   // app-wide default
    int maxGlNo = 1000; // safe starting point

    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/gl-master?page=0&size=5000'),
        headers: apiService.headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> items = decoded is List
            ? decoded
            : (decoded is Map ? decoded['content'] ?? [] : []);

        for (final item in items) {
          // Collect existing account names
          final name = (item['glName'] ?? item['glname'] ?? '')
              .toString().toLowerCase().trim();
          if (name.isNotEmpty) names.add(name);

          // Read orgCode from first record
          final oc = item['orgCode'] ?? item['orgcode'];
          if (oc != null) {
            orgCode = oc is int ? oc : int.tryParse(oc.toString()) ?? orgCode;
          }

          // Track max glNo for auto-increment
          final gn = item['glNo'] ?? item['glno'];
          if (gn != null) {
            final gnInt = gn is int ? gn : int.tryParse(gn.toString()) ?? 0;
            if (gnInt > maxGlNo) maxGlNo = gnInt;
          }
        }
      }
    } catch (e) {
      print('⚠️ _loadExistingAccountsAndOrgCode: $e');
    }

    return {'names': names, 'orgCode': orgCode, 'maxGlNo': maxGlNo};
  }

  // ── Resolve category name → glCatCd ──────────────────────────────────────
  int _resolveCategory(String typeName, Map<String, int> categoryMap) {
    if (typeName.isEmpty || categoryMap.isEmpty) return 0;
    final lower = typeName.toLowerCase().trim();

    // 1. Exact match
    for (final e in categoryMap.entries) {
      if (e.key.toLowerCase() == lower) { return e.value; }
    }
    // 2. Partial match
    for (final e in categoryMap.entries) {
      if (e.key.toLowerCase().contains(lower) ||
          lower.contains(e.key.toLowerCase())) { return e.value; }
    }
    // 3. Keyword fallback — return first available category
    return categoryMap.values.first;
  }

  // ── Extract error text from server response ───────────────────────────────
  String _extractError(String body, int statusCode) {
    final t = body.trim();
    if (t.isEmpty) return 'HTTP $statusCode';
    try {
      final d = jsonDecode(t);
      if (d is Map) {
        return d['message']?.toString() ??
               d['error']?.toString()   ??
               d['detail']?.toString()  ??
               t;
      }
    } catch (_) {}
    return t.length > 200 ? '${t.substring(0, 200)}...' : t;
  }

  // ── Minimal CSV parser supporting quoted fields ───────────────────────────
  List<List<String>> _parseCSV(String csv) {
    final result = <List<String>>[];
    for (final line in csv.split(RegExp(r'\r?\n'))) {
      if (line.trim().isEmpty) continue;
      final row     = <String>[];
      final field   = StringBuffer();
      bool inQuotes = false;
      for (int i = 0; i < line.length; i++) {
        final c = line[i];
        if (c == '"') {
          inQuotes = !inQuotes;
        } else if (c == ',' && !inQuotes) {
          row.add(field.toString().trim());
          field.clear();
        } else {
          field.write(c);
        }
      }
      row.add(field.toString().trim());
      result.add(row);
    }
    return result;
  }
}

final importApiService = ImportApiService();
