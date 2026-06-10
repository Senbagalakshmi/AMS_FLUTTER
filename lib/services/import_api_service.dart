import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ImportApiService {
  /// Helper to escape commas, quotes, and newlines in CSV cells
  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Normalizes user-mapped CSV to the 12 columns for Chart of Accounts (COA)
  /// and performs a single-file multipart upload to /api/imports/coa.
  Future<Map<String, dynamic>> importCoaData(
    Uint8List bytes,
    String filename,
    String eUser,
    String duplicateHandling,
    Map<String, String?> mappings,
  ) async {
    try {
      final csvString = utf8.decode(bytes);
      final rows = _parseCSV(csvString);
      if (rows.length < 2) {
        return {'status': 'ERROR', 'message': 'File has no data rows to import.'};
      }

      final headers  = rows.first;
      final dataRows = rows.skip(1).toList();

      print('📤 Import COA: ${dataRows.length} data rows from "$filename"');

      final existing     = await _loadExistingAccountsAndOrgCode();
      final existingNames = existing['names'] as Set<String>;
      final orgCode       = existing['orgCode'] as int;
      final maxGlNo       = existing['maxGlNo'] as int;

      int idx(String? col) => col != null ? headers.indexOf(col) : -1;

      final nameIdx       = idx(mappings['Account Name']);
      final codeIdx       = idx(mappings['Account Code']);
      final descIdx       = idx(mappings['Description']);
      final typeIdx       = idx(mappings['Account Type']);
      final parentIdx     = idx(mappings['Parent Account']);
      final currIdx       = idx(mappings['Currency']);
      final balanceIdx    = idx(mappings['Opening Balance']);
      final dcIdx         = idx(mappings['Debit or Credit']);
      final orgIdx        = idx(mappings['Org Code']);
      final branchIdx     = idx(mappings['Branch Code']);
      final euserIdx      = idx(mappings['Created By (euser)']);
      final edateIdx      = idx(mappings['Created Date (edate)']);

      final cleanUser = eUser.contains('@') ? eUser.split('@').first : eUser;
      final now = DateTime.now().toUtc();
      final nowIso = '${now.toIso8601String().split('.').first}.000+00:00';

      int skipped   = 0;
      int autoGlNo  = maxGlNo;
      final List<String> errors = [];
      final Set<String>  seenNames = {};

      final StringBuffer normalizedCsv = StringBuffer();
      normalizedCsv.writeln("orgcode,brncd,accountname,accountcode,description,accounttype,parentaccount,basecurr,openingbalance,debit_credit,euser,edate");

      for (int i = 0; i < dataRows.length; i++) {
        final row    = dataRows[i];
        final rowNum = i + 2;

        String cell(int colIdx) =>
            (colIdx >= 0 && colIdx < row.length) ? row[colIdx].trim() : '';

        final glName   = cell(nameIdx);
        final glNoRaw  = cell(codeIdx);
        final typeName = cell(typeIdx);

        if (glName.isEmpty) {
          skipped++;
          errors.add('Row $rowNum: Account Name is empty — skipped.');
          continue;
        }

        if (typeName.isEmpty && typeIdx != -1) {
          skipped++;
          errors.add('Row $rowNum: Account Type is empty — skipped.');
          continue;
        }

        final nameKey = glName.toLowerCase();
        if (duplicateHandling == 'skip') {
          if (seenNames.contains(nameKey) || existingNames.contains(nameKey)) {
            skipped++;
            errors.add('Row $rowNum: "$glName" is a duplicate — skipped.');
            continue;
          }
        }
        seenNames.add(nameKey);

        int glNo = int.tryParse(glNoRaw.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        if (glNo == 0) {
          autoGlNo++;
          glNo = autoGlNo;
        }

        final rowOrgCode = cell(orgIdx).isNotEmpty ? cell(orgIdx) : orgCode.toString();
        final rowBranch = cell(branchIdx).isNotEmpty ? cell(branchIdx) : '1';
        final rowDesc = cell(descIdx);
        final rowParent = cell(parentIdx);
        final rowCurr = cell(currIdx).isNotEmpty ? cell(currIdx) : 'INR';
        final rowBalance = cell(balanceIdx).isNotEmpty ? cell(balanceIdx) : '0.00';
        final rowDc = cell(dcIdx).isNotEmpty ? cell(dcIdx) : 'Debit';
        final rowEuser = cell(euserIdx).isNotEmpty ? cell(euserIdx) : cleanUser;
        final rowEdate = cell(edateIdx).isNotEmpty ? cell(edateIdx) : nowIso;

        final line = [
          _escapeCsvValue(rowOrgCode),
          _escapeCsvValue(rowBranch),
          _escapeCsvValue(glName),
          _escapeCsvValue(glNo.toString()),
          _escapeCsvValue(rowDesc),
          _escapeCsvValue(typeName),
          _escapeCsvValue(rowParent),
          _escapeCsvValue(rowCurr),
          _escapeCsvValue(rowBalance),
          _escapeCsvValue(rowDc),
          _escapeCsvValue(rowEuser),
          _escapeCsvValue(rowEdate),
        ].join(',');

        normalizedCsv.writeln(line);
      }

      final int totalParsedRows = dataRows.length - skipped;
      if (totalParsedRows <= 0) {
        return {
          'status': 'ERROR',
          'message': 'No valid COA data rows left after duplicate filtering/validation.',
          'errors': errors,
        };
      }

      final uri = Uri.parse('${ApiService.baseUrl}/imports/coa').replace(
        queryParameters: {'eUser': cleanUser},
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(apiService.headers);

      final csvBytes = utf8.encode(normalizedCsv.toString());
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        csvBytes,
        filename: 'normalized_coa_import.csv',
      );
      request.files.add(multipartFile);

      print('📤 Uploading COA file to $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final int imported = decoded['importedRows'] ?? totalParsedRows;
        return {
          'status': 'SUCCESS',
          'message': decoded['message'] ?? 'COA Import successful.',
          'imported': imported,
          'skipped': skipped,
          'errors': errors,
        };
      } else {
        final errorMsg = _extractError(response.body, response.statusCode);
        return {
          'status': 'ERROR',
          'message': 'Server rejected COA import: $errorMsg',
          'skipped': skipped,
          'errors': [errorMsg, ...errors],
        };
      }
    } catch (e) {
      print('❌ importCoaData error: $e');
      return {'status': 'ERROR', 'message': 'Import failed: $e'};
    }
  }

  /// Normalizes user-mapped CSV to the 12 columns for Journal Entries
  /// and performs a single-file multipart upload to /api/imports/journal.
  Future<Map<String, dynamic>> importJournalData(
    Uint8List bytes,
    String filename,
    String eUser,
    Map<String, String?> mappings,
  ) async {
    try {
      final csvString = utf8.decode(bytes);
      final rows = _parseCSV(csvString);
      if (rows.length < 2) {
        return {'status': 'ERROR', 'message': 'File has no data rows to import.'};
      }

      final headers  = rows.first;
      final dataRows = rows.skip(1).toList();

      print('📤 Import Journal: ${dataRows.length} data rows from "$filename"');

      final existing     = await _loadExistingAccountsAndOrgCode();
      final orgCode       = existing['orgCode'] as int;

      int idx(String? col) => col != null ? headers.indexOf(col) : -1;

      final orgIdx        = idx(mappings['Org Code']);
      final branchIdx     = idx(mappings['Branch Code']);
      final dateIdx       = idx(mappings['Transaction Date']);
      final tranIdIdx     = idx(mappings['Journal No (Tran ID)']);
      final statusIdx     = idx(mappings['Transaction Status']);
      final codeIdx       = idx(mappings['Account Code']);
      final dcIdx         = idx(mappings['Debit or Credit']);
      final totCreditIdx  = idx(mappings['Total Credit']);
      final totDebitIdx   = idx(mappings['Total Debit']);
      final narrationIdx  = idx(mappings['Narration']);
      final euserIdx      = idx(mappings['Created By (euser)']);
      final edateIdx      = idx(mappings['Created Date (edate)']);

      final cleanUser = eUser.contains('@') ? eUser.split('@').first : eUser;
      final now = DateTime.now().toUtc();
      final nowIso = '${now.toIso8601String().split('.').first}.000+00:00';

      int skipped = 0;
      final List<String> errors = [];

      final StringBuffer normalizedCsv = StringBuffer();
      normalizedCsv.writeln("orgcode,brncd,trandate,tranid,transtatus,accountcode,debit_credit,totalcredit,totaldebit,narration,euser,edate");

      for (int i = 0; i < dataRows.length; i++) {
        final row    = dataRows[i];
        final rowNum = i + 2;

        String cell(int colIdx) =>
            (colIdx >= 0 && colIdx < row.length) ? row[colIdx].trim() : '';

        final accountCode = cell(codeIdx);

        if (accountCode.isEmpty) {
          skipped++;
          errors.add('Row $rowNum: Account Code is empty — skipped.');
          continue;
        }

        final rowOrgCode = cell(orgIdx).isNotEmpty ? cell(orgIdx) : orgCode.toString();
        final rowBranch = cell(branchIdx).isNotEmpty ? cell(branchIdx) : '1';
        final rowDate = cell(dateIdx);
        final rowTranId = cell(tranIdIdx).isNotEmpty ? cell(tranIdIdx) : '0';
        final rowStatus = cell(statusIdx).isNotEmpty ? cell(statusIdx) : 'P';
        final rowDc = cell(dcIdx).isNotEmpty ? cell(dcIdx) : 'Debit';
        final rowTotCredit = cell(totCreditIdx).isNotEmpty ? cell(totCreditIdx) : '0.00';
        final rowTotDebit = cell(totDebitIdx).isNotEmpty ? cell(totDebitIdx) : '0.00';
        final rowNarration = cell(narrationIdx); // taken strictly from file
        final rowEuser = cell(euserIdx).isNotEmpty ? cell(euserIdx) : cleanUser;
        final rowEdate = cell(edateIdx); // taken strictly from file (DD-MM-YYYY)

        final line = [
          _escapeCsvValue(rowOrgCode),
          _escapeCsvValue(rowBranch),
          _escapeCsvValue(rowDate),
          _escapeCsvValue(rowTranId),
          _escapeCsvValue(rowStatus),
          _escapeCsvValue(accountCode),
          _escapeCsvValue(rowDc),
          _escapeCsvValue(rowTotCredit),
          _escapeCsvValue(rowTotDebit),
          _escapeCsvValue(rowNarration),
          _escapeCsvValue(rowEuser),
          _escapeCsvValue(rowEdate),
        ].join(',');

        normalizedCsv.writeln(line);
      }

      final int totalParsedRows = dataRows.length - skipped;
      if (totalParsedRows <= 0) {
        return {
          'status': 'ERROR',
          'message': 'No valid Journal data rows left after validation.',
          'errors': errors,
        };
      }

      final uri = Uri.parse('${ApiService.baseUrl}/imports/journal').replace(
        queryParameters: {
          'eUser': cleanUser,
        },
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(apiService.headers);

      final csvBytes = utf8.encode(normalizedCsv.toString());
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        csvBytes,
        filename: 'normalized_journal_import.csv',
      );
      request.files.add(multipartFile);

      print('📤 Uploading Journal file to $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final int imported = decoded['importedRows'] ?? totalParsedRows;
        return {
          'status': 'SUCCESS',
          'message': decoded['message'] ?? 'Journal Import successful.',
          'imported': imported,
          'skipped': skipped,
          'errors': errors,
        };
      } else {
        final errorMsg = _extractError(response.body, response.statusCode);
        return {
          'status': 'ERROR',
          'message': 'Server rejected Journal import: $errorMsg',
          'skipped': skipped,
          'errors': [errorMsg, ...errors],
        };
      }
    } catch (e) {
      print('❌ importJournalData error: $e');
      return {'status': 'ERROR', 'message': 'Import failed: $e'};
    }
  }

  /// Legacy import endpoint logic (calls /api/imports/company)
  Future<Map<String, dynamic>> importCompanyGlData(
    Uint8List bytes,
    String filename,
    String eUser,
    String duplicateHandling,
    Map<String, String?> mappings, {
    String? tranDate,
    String? notes,
    String? referenceNo,
  }) async {
    try {
      final csvString = utf8.decode(bytes);
      final rows = _parseCSV(csvString);
      if (rows.length < 2) {
        return {'status': 'ERROR', 'message': 'File has no data rows to import.'};
      }

      final headers  = rows.first;
      final dataRows = rows.skip(1).toList();

      final existing     = await _loadExistingAccountsAndOrgCode();
      final existingNames = existing['names'] as Set<String>;
      final orgCode       = existing['orgCode'] as int;
      final maxGlNo       = existing['maxGlNo'] as int;

      int idx(String? col) => col != null ? headers.indexOf(col) : -1;

      final nameIdx       = idx(mappings['Account Name']);
      final codeIdx       = idx(mappings['Account Code']);
      final descIdx       = idx(mappings['Description']);
      final typeIdx       = idx(mappings['Account Type']);
      final parentIdx     = idx(mappings['Parent Account']);
      final currIdx       = idx(mappings['Currency']);
      final balanceIdx    = idx(mappings['Opening Balance']);
      final dcIdx         = idx(mappings['Debit or Credit']);
      final orgIdx        = idx(mappings['Org Code']);
      final branchIdx     = idx(mappings['Branch Code']);
      final dateIdx       = idx(mappings['Transaction Date']);
      final tranIdIdx     = idx(mappings['Journal No (Tran ID)']);
      final statusIdx     = idx(mappings['Transaction Status']);
      final totCreditIdx  = idx(mappings['Total Credit']);
      final totDebitIdx   = idx(mappings['Total Debit']);
      final narrationIdx  = idx(mappings['Narration']);
      final euserIdx      = idx(mappings['Created By (euser)']);
      final edateIdx      = idx(mappings['Created Date (edate)']);

      final defaultDate = (tranDate != null && tranDate.isNotEmpty)
          ? tranDate
          : DateTime.now().toIso8601String().split('T').first;
      final defaultNotes = (notes != null && notes.isNotEmpty) ? notes : 'Opening balances import';
      final cleanUser = eUser.contains('@') ? eUser.split('@').first : eUser;
      final now = DateTime.now().toUtc();
      final nowIso = '${now.toIso8601String().split('.').first}.000+00:00';

      int skipped   = 0;
      int autoGlNo  = maxGlNo;
      final List<String> errors = [];
      final Set<String>  seenNames = {};

      final StringBuffer normalizedCsv = StringBuffer();
      normalizedCsv.writeln("orgcode,brncd,trandate,JournalNo(tranId),Transtatus,accountname,account code,Description,account type,parent account,basecurr,openingnalance,debit or credit,Totalcredit,TotalDebit,narration,euser,edate");

      for (int i = 0; i < dataRows.length; i++) {
        final row    = dataRows[i];
        final rowNum = i + 2;

        String cell(int colIdx) =>
            (colIdx >= 0 && colIdx < row.length) ? row[colIdx].trim() : '';

        final glName   = cell(nameIdx);
        final glNoRaw  = cell(codeIdx);
        final typeName = cell(typeIdx);

        if (glName.isEmpty) {
          skipped++;
          errors.add('Row $rowNum: Account Name is empty — skipped.');
          continue;
        }

        if (typeName.isEmpty && typeIdx != -1) {
          skipped++;
          errors.add('Row $rowNum: Account Type is empty — skipped.');
          continue;
        }

        final nameKey = glName.toLowerCase();
        if (duplicateHandling == 'skip') {
          if (seenNames.contains(nameKey) || existingNames.contains(nameKey)) {
            skipped++;
            errors.add('Row $rowNum: "$glName" is a duplicate — skipped.');
            continue;
          }
        }
        seenNames.add(nameKey);

        int glNo = int.tryParse(glNoRaw.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        if (glNo == 0) {
          autoGlNo++;
          glNo = autoGlNo;
        }

        final rowOrgCode = cell(orgIdx).isNotEmpty ? cell(orgIdx) : orgCode.toString();
        final rowBranch = cell(branchIdx).isNotEmpty ? cell(branchIdx) : '1';
        final rowDate = cell(dateIdx).isNotEmpty ? cell(dateIdx) : defaultDate;
        final rowTranId = cell(tranIdIdx).isNotEmpty ? cell(tranIdIdx) : '0';
        final rowStatus = cell(statusIdx).isNotEmpty ? cell(statusIdx) : 'P';
        final rowDesc = cell(descIdx);
        final rowParent = cell(parentIdx);
        final rowCurr = cell(currIdx).isNotEmpty ? cell(currIdx) : 'INR';
        final rowBalance = cell(balanceIdx).isNotEmpty ? cell(balanceIdx) : '0.00';
        final rowDc = cell(dcIdx).isNotEmpty ? cell(dcIdx) : 'Debit';
        final rowTotCredit = cell(totCreditIdx).isNotEmpty ? cell(totCreditIdx) : '0.00';
        final rowTotDebit = cell(totDebitIdx).isNotEmpty ? cell(totDebitIdx) : '0.00';
        final rowNarration = cell(narrationIdx).isNotEmpty ? cell(narrationIdx) : defaultNotes;
        final rowEuser = cell(euserIdx).isNotEmpty ? cell(euserIdx) : cleanUser;
        final rowEdate = cell(edateIdx).isNotEmpty ? cell(edateIdx) : nowIso;

        final line = [
          _escapeCsvValue(rowOrgCode),
          _escapeCsvValue(rowBranch),
          _escapeCsvValue(rowDate),
          _escapeCsvValue(rowTranId),
          _escapeCsvValue(rowStatus),
          _escapeCsvValue(glName),
          _escapeCsvValue(glNo.toString()),
          _escapeCsvValue(rowDesc),
          _escapeCsvValue(typeName),
          _escapeCsvValue(rowParent),
          _escapeCsvValue(rowCurr),
          _escapeCsvValue(rowBalance),
          _escapeCsvValue(rowDc),
          _escapeCsvValue(rowTotCredit),
          _escapeCsvValue(rowTotDebit),
          _escapeCsvValue(rowNarration),
          _escapeCsvValue(rowEuser),
          _escapeCsvValue(rowEdate),
        ].join(',');

        normalizedCsv.writeln(line);
      }

      final int totalParsedRows = dataRows.length - skipped;
      if (totalParsedRows <= 0) {
        return {
          'status': 'ERROR',
          'message': 'No valid data rows left after duplicate filtering/validation.',
          'errors': errors,
        };
      }

      final queryParams = {
        'eUser': cleanUser,
        if (defaultDate.isNotEmpty) 'tranDate': defaultDate,
        if (defaultNotes.isNotEmpty) 'notes': defaultNotes,
        if (referenceNo != null && referenceNo.isNotEmpty) 'referenceNo': referenceNo,
      };
      
      final uri = Uri.parse('${ApiService.baseUrl}/imports/company').replace(
        queryParameters: queryParams,
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(apiService.headers);

      final csvBytes = utf8.encode(normalizedCsv.toString());
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        csvBytes,
        filename: 'normalized_company_import.csv',
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final int imported = decoded['importedRows'] ?? totalParsedRows;

        return {
          'status': 'SUCCESS',
          'message': decoded['message'] ?? 'Import successful.',
          'imported': imported,
          'skipped': skipped,
          'errors': errors,
        };
      } else {
        final errorMsg = _extractError(response.body, response.statusCode);
        return {
          'status': 'ERROR',
          'message': 'Server rejected import: $errorMsg',
          'skipped': skipped,
          'errors': [errorMsg, ...errors],
        };
      }
    } catch (e) {
      print('❌ importCompanyGlData error: $e');
      return {'status': 'ERROR', 'message': 'Import failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _loadExistingAccountsAndOrgCode() async {
    final names = <String>{};
    int orgCode = 50;
    int maxGlNo = 1000;

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
          final name = (item['glName'] ?? item['glname'] ?? '')
              .toString().toLowerCase().trim();
          if (name.isNotEmpty) names.add(name);

          final oc = item['orgCode'] ?? item['orgcode'];
          if (oc != null) {
            orgCode = oc is int ? oc : int.tryParse(oc.toString()) ?? orgCode;
          }

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
