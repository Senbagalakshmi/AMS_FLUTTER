import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../services/import_api_service.dart';
import '../services/gl_api_service.dart';
import '../utils/responsive.dart';
import '../theme.dart';

class ImportCompanyScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const ImportCompanyScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<ImportCompanyScreen> createState() => _ImportCompanyScreenState();
}

class _ImportCompanyScreenState extends State<ImportCompanyScreen> {
  @override
  void initState() {
    super.initState();
    GLApiService.loadAccountCache();
  }

  String? _fileName;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  Map<String, dynamic>? _importResult;
  String? _validationError;
  bool _isBinaryFile = false;
  String _duplicateHandling = 'skip';

  bool _showMappingStep = false;
  int _currentStep = 1;
  bool _showReadyDetails = false;
  bool _showSkippedDetails = false;
  bool _showUnmappedDetails = false;
  bool _isFormatAtFieldLevel = false;
  String _decimalFormat = "1234567.89";
  Map<String, String?> _mappings = {};
  String? _openDropdownField;
  bool _saveSelections = false;
  String _characterEncoding = 'UTF-8 (Unicode)';

  final List<Map<String, dynamic>> _mappingFields = [
    {"name": "Account Name", "mandatory": true},
    {"name": "Account Code", "mandatory": false},
    {"name": "Description", "mandatory": false},
    {"name": "Account Type", "mandatory": true},
    {"name": "Mileage Rate", "mandatory": false},
    {"name": "Mileage Unit", "mandatory": false},
    {"name": "IsMileage", "mandatory": false},
    {"name": "Account #", "mandatory": false},
    {"name": "Currency", "mandatory": false},
    {"name": "Parent Account", "mandatory": false},
    {"name": "Opening Balance", "mandatory": false},
    {"name": "Debit or Credit", "mandatory": false},
  ];

  // Exact headers matching your PostgreSQL procedure parameter structure
  final List<String> _expectedHeaders = [
    "OrgCode",
    "CompanyName",
    "BranchCode",
    "Currency",
    "GlCatCd",
    "GlCatName",
    "GlCatType",
    "GlCatSubType",
    "GlNo",
    "GlName",
    "Balance"
  ];

  // ================= STATE RESET CONTROLLER =================
  void _clearSelectedFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
      _validationError = null;
      _importResult = null;
      _isBinaryFile = false;
      _showMappingStep = false;
      _currentStep = 1;
      _showReadyDetails = false;
      _showSkippedDetails = false;
      _showUnmappedDetails = false;
      _isFormatAtFieldLevel = false;
      _decimalFormat = "1234567.89";
      _mappings.clear();
      _openDropdownField = null;
      _saveSelections = false;
      _characterEncoding = 'UTF-8 (Unicode)';
    });
  }

  List<String> _getFileHeaders() {
    if (_fileBytes == null) {
      return _expectedHeaders;
    }
    try {
      final csvString = utf8.decode(_fileBytes!);
      final List<List<String>> rows = _parseCSVManual(csvString);
      if (rows.isNotEmpty) {
        return rows.first.where((h) => h.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return _expectedHeaders;
  }

  void _initializeMappings() {
    final headers = _getFileHeaders();
    setState(() {
      _mappings = {};
      for (var field in _mappingFields) {
        String fieldName = field["name"];
        String matchedHeader = "";

        if (fieldName == "Account Name") {
          matchedHeader = headers.firstWhere(
              (h) =>
                  h.toLowerCase().contains("glname") ||
                  h.toLowerCase() == "name",
              orElse: () => headers.firstWhere(
                  (h) => h.toLowerCase().contains("companyname"),
                  orElse: () => ""));
        } else if (fieldName == "Account Code") {
          matchedHeader = headers.firstWhere(
              (h) => h.toLowerCase() == "glno" || h.toLowerCase() == "code",
              orElse: () => "");
        } else if (fieldName == "Description") {
          matchedHeader = headers.firstWhere(
              (h) =>
                  h.toLowerCase().contains("description") ||
                  h.toLowerCase().contains("desc"),
              orElse: () => "");
        } else if (fieldName == "Account Type") {
          matchedHeader = headers.firstWhere(
              (h) =>
                  h.toLowerCase().contains("glcattype") ||
                  h.toLowerCase().contains("type"),
              orElse: () => "");
        } else if (fieldName == "Account #") {
          matchedHeader = headers.firstWhere(
              (h) =>
                  h.toLowerCase() == "glno" ||
                  h.toLowerCase().contains("number"),
              orElse: () => "");
        } else if (fieldName == "Currency") {
          matchedHeader = headers.firstWhere(
              (h) => h.toLowerCase() == "currency",
              orElse: () => "");
        } else if (fieldName == "Parent Account") {
          matchedHeader = headers.firstWhere(
              (h) =>
                  h.toLowerCase().contains("parent") ||
                  h.toLowerCase().contains("subtype"),
              orElse: () => "");
        } else if (fieldName == "Opening Balance") {
          matchedHeader = headers.firstWhere(
              (h) =>
                  h.toLowerCase().contains("balance") ||
                  h.toLowerCase().contains("bal"),
              orElse: () => "");
        }

        _mappings[fieldName] = matchedHeader.isNotEmpty ? matchedHeader : null;
      }
    });
  }

  // ================= CUSTOM CSV/TXT STRUCTURAL PARSER =================
  List<List<String>> _parseCSVManual(String csvString) {
    List<List<String>> result = [];
    List<String> lines = csvString.split(RegExp(r'\r?\n'));

    for (String line in lines) {
      if (line.trim().isEmpty) continue;

      List<String> row = [];
      bool inQuotes = false;
      StringBuffer currentField = StringBuffer();

      for (int i = 0; i < line.length; i++) {
        String char = line[i];

        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          row.add(currentField.toString().trim());
          currentField.clear();
        } else {
          currentField.write(char);
        }
      }
      row.add(currentField.toString().trim());
      result.add(row);
    }
    return result;
  }

  // ================= EXHAUSTIVE PL/PGSQL PARAMETER VALIDATION ENGINE =================
  String? _validateCSVData(Uint8List bytes) {
    try {
      final csvString = utf8.decode(bytes);
      final List<List<String>> rows = _parseCSVManual(csvString);

      if (rows.isEmpty) {
        return "The uploaded file contains no data rows.";
      }

      final List<String> headers = rows.first;
      if (headers.isEmpty) {
        return "The uploaded file contains no header row.";
      }

      if (rows.length < 2) {
        return "The file contains valid headers but lacks transactional data rows.";
      }

      if (rows.length - 1 > 50000) {
        return "The uploaded file exceeds the maximum allowed limit of 50,000 rows.";
      }

      return null; // Passes base structure, completely dynamic!
    } catch (e) {
      return "Unable to securely parse file data stream. Ensure character mapping is valid UTF-8.";
    }
  }

  // ================= DYNAMIC ERROR UTILITIES =================
  String _getErrorHeader(String error) {
    final lower = error.toLowerCase();
    if (lower.contains("limit of 50,000 rows") ||
        lower.contains("50 thousand rows")) {
      return "Row Limit Exceeded";
    } else if (lower.contains("size") || lower.contains("mb")) {
      return "File Size Exceeded";
    } else if (lower.contains("format") || lower.contains("extension")) {
      return "Invalid File Format";
    } else if (lower.contains("no data rows") ||
        lower.contains("no header row") ||
        lower.contains("lacks transactional data")) {
      return "CSV Structural Error";
    } else if (lower.contains("utf-8") || lower.contains("character mapping")) {
      return "File Decoding Error";
    } else if (lower.contains("mandatory fields") ||
        lower.contains("missing") ||
        lower.contains("column")) {
      return "Mapping Validation Error";
    } else if (lower.contains("duplicate")) {
      return "Duplicate Record Error";
    } else if (lower.contains("failed") || lower.contains("error")) {
      return "Import Submission Failed";
    } else {
      return "Validation Error";
    }
  }

  Widget _buildErrorBanner(String error) {
    final header = _getErrorHeader(error);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= PICK FILE EVENT =================
  void _pickCSVFile() {
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.csv,.tsv,.xls';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      if (uploadInput.files!.isNotEmpty) {
        final file = uploadInput.files![0];
        final String fileName = file.name.toLowerCase();

        if (file.size > 25 * 1024 * 1024) {
          setState(() {
            _fileName = file.name;
            _validationError = "File exceeds maximum size of 25 MB.";
            _fileBytes = null;
            _isBinaryFile = false;
          });
          return;
        }

        if (!fileName.endsWith('.csv') &&
            !fileName.endsWith('.tsv') &&
            !fileName.endsWith('.xls')) {
          setState(() {
            _fileName = file.name;
            _validationError =
                "Invalid file format. Please upload a CSV, TSV, or XLS file.";
            _fileBytes = null;
            _isBinaryFile = false;
          });
          return;
        }

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          final bytes = reader.result as Uint8List;

          setState(() {
            _fileName = file.name;
            _importResult = null;

            // If text table format (.csv / .tsv), execute rigorous structural data validation loop
            if (fileName.endsWith('.csv') || fileName.endsWith('.tsv')) {
              _isBinaryFile = false;
              final errorResult = _validateCSVData(bytes);
              _validationError = errorResult;

              if (errorResult == null) {
                _fileBytes = bytes;
              } else {
                _fileBytes = null; // Locks down the import button
              }
            } else {
              // Binary files bypass local schema verification loops
              _isBinaryFile = true;
              _validationError = null;
              _fileBytes = bytes;
            }
          });
        });
      }
    });
  }

  // ================= DYNAMIC SKIPPED ROWS CALCULATOR =================
  List<SkippedRowInfo> _calculateSkippedRows() {
    List<SkippedRowInfo> skipped = [];
    if (_fileBytes == null) return skipped;

    try {
      final csvString = utf8.decode(_fileBytes!);
      final List<List<String>> rows = _parseCSVManual(csvString);
      if (rows.length < 2) return skipped;

      final headers = rows.first;

      // Get indices for mandatory and duplicate-check columns
      String? accountCodeHeader = _mappings["Account Code"];
      String? accountNameHeader = _mappings["Account Name"];
      String? accountTypeHeader = _mappings["Account Type"];
      int accountCodeIdx =
          accountCodeHeader != null ? headers.indexOf(accountCodeHeader) : -1;
      int accountNameIdx =
          accountNameHeader != null ? headers.indexOf(accountNameHeader) : -1;
      int accountTypeIdx =
          accountTypeHeader != null ? headers.indexOf(accountTypeHeader) : -1;

      // Only validate the "Opening Balance" column as numeric, if it is explicitly mapped
      String? balanceHeader = _mappings["Opening Balance"];
      int balanceIdx =
          balanceHeader != null ? headers.indexOf(balanceHeader) : -1;

      Set<String> seenAccountCodes = {};
      Set<String> seenAccountNames = {};

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        bool rowSkipped = false;

        // 1. Mandatory fields validation — Account Name and Account Type cannot be empty
        if (accountNameIdx != -1 && accountNameIdx < row.length) {
          if (row[accountNameIdx].trim().isEmpty) {
            skipped.add(SkippedRowInfo(
              rowNo: i + 1,
              columnName: accountNameHeader ?? "Account Name",
              errorMessage: "Mandatory field 'Account Name' cannot be empty.",
            ));
            rowSkipped = true;
          }
        }

        if (!rowSkipped &&
            accountTypeIdx != -1 &&
            accountTypeIdx < row.length) {
          if (row[accountTypeIdx].trim().isEmpty) {
            skipped.add(SkippedRowInfo(
              rowNo: i + 1,
              columnName: accountTypeHeader ?? "Account Type",
              errorMessage: "Mandatory field 'Account Type' cannot be empty.",
            ));
            rowSkipped = true;
          }
        }

        if (rowSkipped) continue;

        // 2. Validate Opening Balance as numeric only (not all unmapped columns)
        if (balanceIdx != -1 && balanceIdx < row.length) {
          final val = row[balanceIdx].trim();
          if (val.isNotEmpty) {
            // Strip currency symbols and commas to be lenient
            final cleanVal = val.replaceAll(RegExp(r'[^\d\.\-]'), '');
            final parsed = double.tryParse(cleanVal);
            if (parsed == null) {
              skipped.add(SkippedRowInfo(
                rowNo: i + 1,
                columnName: balanceHeader ?? "Opening Balance",
                errorMessage:
                    "Opening Balance value '$val' is not a valid number.",
              ));
              rowSkipped = true;
            }
          }
        }

        if (rowSkipped) continue;

        // 3. Duplicate validation — checks in-file duplicates and existing system records
        if (_duplicateHandling == 'skip') {
          bool isDuplicate = false;
          String duplicateDetails = "";

          if (accountCodeIdx != -1 && accountCodeIdx < row.length) {
            final code = row[accountCodeIdx].trim();
            if (code.isNotEmpty) {
              if (seenAccountCodes.contains(code)) {
                isDuplicate = true;
                duplicateDetails = "Duplicate Account Code '$code' in file";
              } else if (GLApiService.accountCache.containsKey(code)) {
                isDuplicate = true;
                duplicateDetails =
                    "Account Code '$code' already exists in system";
              } else {
                seenAccountCodes.add(code);
              }
            }
          }

          if (!isDuplicate &&
              accountNameIdx != -1 &&
              accountNameIdx < row.length) {
            final name = row[accountNameIdx].trim();
            if (name.isNotEmpty) {
              if (seenAccountNames.contains(name)) {
                isDuplicate = true;
                duplicateDetails = "Duplicate Account Name '$name' in file";
              } else if (GLApiService.accountCache.containsValue(name)) {
                isDuplicate = true;
                duplicateDetails =
                    "Account Name '$name' already exists in system";
              } else {
                seenAccountNames.add(name);
              }
            }
          }

          if (isDuplicate) {
            skipped.add(SkippedRowInfo(
              rowNo: i + 1,
              columnName: accountCodeHeader ?? accountNameHeader ?? "Duplicate",
              errorMessage: "Duplicate validation: $duplicateDetails",
            ));
            continue;
          }
        }
      }
    } catch (_) {}

    return skipped;
  }

  // ================= TEMPLATE GENERATOR =================
  void _downloadTemplate() {
    final csvContent = "${_expectedHeaders.join(',')}\n"
        "101,BBOTS Financials,1,INR,1,Assets,Asset,Current Assets,1001,Cash on Hand,50000.00\n"
        "101,BBOTS Financials,1,INR,1,Assets,Asset,Current Assets,1002,HDFC Bank Current A/C,250000.00\n"
        "101,BBOTS Financials,1,INR,2,Liabilities,Liability,Current Liabilities,2001,Accounts Payable,-45000.00\n";

    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "finance_import_template.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void _downloadSkippedRows() {
    final skippedRows = _calculateSkippedRows();
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln("Row No,Column,Error Message");
    for (var row in skippedRows) {
      csvBuffer.writeln(
          "${row.rowNo},${row.columnName},\"${row.errorMessage.replaceAll('"', '""')}\"");
    }

    final bytes = utf8.encode(csvBuffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "skipped_rows_${_fileName ?? 'records'}.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void _showSuccessDialog({int imported = 0, int skipped = 0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 85, left: 16, right: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20.0,
                  offset: const Offset(0.0, 8.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Import Successful",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  imported > 0
                      ? "$imported record(s) imported successfully from $_fileName."
                      : "File processed: $_fileName",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (skipped > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "$skipped record(s) were skipped (duplicates or validation errors).",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFF59E0B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onBack();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= API TRANSACTION REQUEST CONTROLLER =================
  Future<void> _submitImport() async {
    if (_fileBytes == null || _fileName == null) return;

    // Validate mandatory mapping fields before submitting
    if (_mappings["Account Name"] == null ||
        _mappings["Account Type"] == null) {
      setState(() {
        _validationError =
            "Please map the mandatory fields 'Account Name' and 'Account Type' before importing.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _importResult = null;
      _validationError = null;
    });

    final eUser = widget.userName ?? "SYSTEM";
    final result = await importApiService.importCompanyGlData(
        _fileBytes!, _fileName!, eUser, _duplicateHandling, _mappings);

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _importResult = result;
    });

    if (result['status'] == 'SUCCESS') {
      setState(() => _validationError = null);
      final imported = result['imported'] ?? 0;
      final skipped = result['skipped'] ?? 0;
      _showSuccessDialog(imported: imported, skipped: skipped);
    } else {
      String errorMsg = result['message']?.toString() ?? '';
      if (errorMsg.trim().isEmpty) {
        errorMsg = "Import failed. No records were imported.";
      }
      // Append first few row errors if available
      final rowErrors = result['errors'] as List?;
      if (rowErrors != null && rowErrors.isNotEmpty) {
        final preview = rowErrors.take(3).join('\n');
        errorMsg += '\n\nDetails:\n$preview';
        if (rowErrors.length > 3) {
          errorMsg += '\n...and ${rowErrors.length - 3} more.';
        }
      }
      setState(() {
        _validationError = errorMsg;
      });
    }
  }

  /*
  void _showEditFormatDialog() {
    bool localIsFormatAtFieldLevel = _isFormatAtFieldLevel;
    String? localSelectedFormat = _isFormatAtFieldLevel ? null : _decimalFormat;
    final GlobalKey dropdownKey = GlobalKey();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Default Data Formats", style: TextStyle(fontSize: 18, color: Color(0xFF334155))),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Table(
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: Color(0xFFF1F5F9)),
                        verticalInside: BorderSide(color: Color(0xFFF1F5F9)),
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1.5),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            const Padding(padding: EdgeInsets.only(bottom: 12), child: Text("DATA TYPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            const Padding(padding: EdgeInsets.only(bottom: 12), child: Center(child: Text("SELECT FORMAT AT FIELD LEVEL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                            const Padding(padding: EdgeInsets.only(bottom: 12, left: 16), child: Text("DEFAULT FORMAT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          ]
                        ),
                        TableRow(
                          children: [
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text("Decimal Format", style: TextStyle(color: Color(0xFF334155), fontSize: 14))),
                            Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(
                              child: SizedBox(
                                height: 20, width: 20,
                                child: Checkbox(
                                  value: localIsFormatAtFieldLevel, 
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      localIsFormatAtFieldLevel = val ?? false;
                                      if (localIsFormatAtFieldLevel) {
                                        localSelectedFormat = null;
                                      } else {
                                        localSelectedFormat = _decimalFormat;
                                      }
                                    });
                                  }, 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
                                  side: const BorderSide(color: Color(0xFFCBD5E1))
                                )
                              ),
                            )),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: InkWell(
                              key: dropdownKey,
                              onTap: localIsFormatAtFieldLevel ? null : () {
                                final RenderBox renderBox = dropdownKey.currentContext!.findRenderObject() as RenderBox;
                                final offset = renderBox.localToGlobal(Offset.zero);
                                _showFormatDropdown(context, offset, renderBox.size, localSelectedFormat ?? "", (newFormat) {
                                  setStateDialog(() {
                                    localSelectedFormat = newFormat;
                                  });
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: localIsFormatAtFieldLevel ? const Color(0xFFF8FAFC) : Colors.white,
                                  border: Border.all(color: const Color(0xFFE2E8F0)), 
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                  children: [
                                    Text(localSelectedFormat ?? "Select Format", style: TextStyle(fontSize: 14, color: localIsFormatAtFieldLevel ? const Color(0xFF94A3B8) : const Color(0xFF334155))), 
                                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: localIsFormatAtFieldLevel ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))
                                  ]
                                ),
                              ),
                            )),
                          ]
                        )
                      ]
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFormatAtFieldLevel = localIsFormatAtFieldLevel;
                              if (!_isFormatAtFieldLevel && localSelectedFormat != null) {
                                _decimalFormat = localSelectedFormat!;
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            backgroundColor: const Color(0xFFF8FAFC),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showFormatDropdown(BuildContext ctx, Offset offset, Size size, String currentFormat, Function(String) onSelected) {
    showGeneralDialog(
      context: ctx,
      barrierColor: Colors.transparent, // Transparent so it looks like an overlay menu
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: offset.dx,
              top: offset.dy + size.height + 4, // Slightly below the input field
              width: size.width < 250 ? 250 : size.width, // Match width but enforce minimum
              child: Material(
                elevation: 8,
                shadowColor: Colors.black26,
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search",
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                          ),
                        ),
                      ),
                      _buildDropdownItem(context, "1234567.89", currentFormat, onSelected, false),
                      _buildDropdownItem(context, "1,234,567.89", currentFormat, onSelected, false),
                      _buildDropdownItem(context, "1 234 567.89", currentFormat, onSelected, false),
                      _buildDropdownItem(context, "1234567,89", currentFormat, onSelected, true),
                      _buildDropdownItem(context, "1.234.567,89", currentFormat, onSelected, true),
                      _buildDropdownItem(context, "1 234 567,89", currentFormat, onSelected, true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    );
  }

  Widget _buildDropdownItem(BuildContext context, String text, String currentFormat, Function(String) onSelected, bool showCheck) {
    bool isSelected = text == currentFormat;
    return InkWell(
      onTap: () {
        onSelected(text);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(fontSize: 15, color: isSelected ? Colors.white : const Color(0xFF334155))),
            if (showCheck) Icon(Icons.check, size: 18, color: isSelected ? Colors.white : const Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }
  */

  Widget _buildTipItem(String text, {String? linkText}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, right: 12, left: 4),
          child: CircleAvatar(radius: 2.5, backgroundColor: Color(0xFF475569)),
        ),
        Expanded(
          child: linkText != null
              ? Text.rich(
                  TextSpan(
                    text: text,
                    children: [
                      TextSpan(
                        text: linkText,
                        style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF334155), height: 1.5),
                )
              : Text(
                  text,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF334155), height: 1.5),
                ),
        ),
      ],
    );
  }

  Widget _buildMappingRow(String zohoField, bool isMandatory, bool isLast) {
    String? selectedHeader = _mappings[zohoField];
    bool isDropdownOpen = _openDropdownField == zohoField;
    bool isWarning = isMandatory && selectedHeader == null;

    Color borderColor = isDropdownOpen
        ? const Color(0xFF3B82F6)
        : (isWarning ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0));
    Color dropdownBgColor = isWarning ? const Color(0xFFFFFBEB) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFFDF5) : Colors.white,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
              ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.storage_rounded,
                  size: 16,
                  color: isWarning
                      ? const Color(0xFFD97706)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: zohoField,
                      children: [
                        if (isMandatory)
                          const TextSpan(
                            text: " *",
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isWarning
                          ? const Color(0xFFB45309)
                          : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Builder(
              builder: (rowContext) {
                return InkWell(
                  onTap: () {
                    final RenderBox renderBox =
                        rowContext.findRenderObject() as RenderBox;
                    final offset = renderBox.localToGlobal(Offset.zero);
                    _showMappingDropdown(context, offset, renderBox.size,
                        zohoField, selectedHeader);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isWarning
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: borderColor,
                        width: isDropdownOpen ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: selectedHeader != null
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.table_chart_outlined,
                                      size: 15,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        selectedHeader,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      isWarning
                                          ? Icons.warning_amber_rounded
                                          : Icons.grid_on_outlined,
                                      size: 15,
                                      color: isWarning
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isWarning
                                            ? "Choose mapped field (Required)"
                                            : "Please select",
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: isWarning
                                              ? const Color(0xFFB45309)
                                              : const Color(0xFF94A3B8),
                                          fontWeight: isWarning
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (selectedHeader != null) ...[
                          InkWell(
                            onTap: () {
                              setState(() {
                                _mappings[zohoField] = null;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: const Color(0xFFE2E8F0),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          ),
                        ],
                        Icon(
                          isDropdownOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDropdownOpen
                              ? const Color(0xFF3B82F6)
                              : (isWarning
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMappingDropdown(BuildContext ctx, Offset offset, Size size,
      String zohoField, String? currentSelection) {
    setState(() {
      _openDropdownField = zohoField;
    });

    final headers = _getFileHeaders();
    String searchQuery = "";

    showGeneralDialog(
      context: ctx,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: "DismissMappingDropdown",
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredHeaders = headers
                .where(
                    (h) => h.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    left: offset.dx,
                    top: offset.dy + size.height + 4,
                    width: size.width,
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 350),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFCBD5E1)),
                                ),
                                child: TextField(
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: "Search",
                                    hintStyle: TextStyle(
                                        color: Color(0xFF94A3B8), fontSize: 14),
                                    prefixIcon: Icon(Icons.search_rounded,
                                        color: Color(0xFF64748B), size: 18),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      searchQuery = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            Flexible(
                              child: filteredHeaders.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        "No headers found",
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      itemCount: filteredHeaders.length,
                                      itemBuilder: (context, index) {
                                        final header = filteredHeaders[index];
                                        final isSelected =
                                            header == currentSelection;
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _mappings[zohoField] = header;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            color: isSelected
                                                ? const Color(0xFF3B82F6)
                                                : Colors.transparent,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  header,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF334155),
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check_rounded,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _openDropdownField = null;
      });
    });
  }

  Widget _buildStepper() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: _buildStepSegment(1, "Configure", Icons.tune_rounded)),
              Container(width: 1, color: const Color(0xFFE2E8F0)),
              Expanded(
                  child: _buildStepSegment(
                      2, "Map Fields", Icons.alt_route_rounded)),
              Container(width: 1, color: const Color(0xFFE2E8F0)),
              Expanded(
                  child:
                      _buildStepSegment(3, "Preview", Icons.analytics_rounded)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSegment(int stepNum, String title, IconData icon) {
    bool isCompleted = _currentStep > stepNum;
    bool isActive = _currentStep == stepNum;

    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF94A3B8);
    Color iconColor = const Color(0xFFCBD5E1);

    if (isActive) {
      bgColor = const Color(0xFFF8FAFC);
      textColor = const Color(0xFF0F172A);
      iconColor = const Color(0xFF2563EB);
    } else if (isCompleted) {
      bgColor = Colors.white;
      textColor = const Color(0xFF334155);
      iconColor = const Color(0xFF10B981);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: isActive
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFF2563EB),
                  width: 3.5,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: isActive
                  ? FontWeight.w800
                  : (isCompleted ? FontWeight.bold : FontWeight.w600),
              fontSize: 14.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUnmappedMandatoryFields() {
    List<String> unmapped = [];
    for (var field in _mappingFields) {
      if (field["mandatory"] == true) {
        String fieldName = field["name"];
        if (_mappings[fieldName] == null ||
            _mappings[fieldName]!.trim().isEmpty) {
          unmapped.add(fieldName);
        }
      }
    }
    return unmapped;
  }

  void _showMandatoryValidationDialog(List<String> missingFields) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Required Mapping Missing",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Before you can proceed to the preview and complete the import, you must map the following mandatory database fields to their corresponding columns in your spreadsheet:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),

                // Missing fields card deck
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFFEF3C7), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: missingFields
                        .map((f) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle,
                                      size: 6, color: Color(0xFFD97706)),
                                  const SizedBox(width: 10),
                                  Text(
                                    f,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text("Go Back & Map",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewStep() {
    final isMobile = Responsive.isMobile(context);
    final fileHeaders = _getFileHeaders();
    final mappedHeaders = _mappings.values.where((v) => v != null).toSet();
    final dynamicUnmapped =
        fileHeaders.where((h) => !mappedHeaders.contains(h)).toList();

    // Fallback to mockup list if dynamic calculation yields nothing or is initial
    final List<String> unmappedList = dynamicUnmapped.isNotEmpty
        ? dynamicUnmapped
        : [
            "Balance",
            "BranchCode",
            "GlCatName",
            "GlCatSubType",
            "GlCatType",
            "GlName",
            "GlNo",
            "OrgCode"
          ];

    int unmappedCount = unmappedList.length;

    int totalFileRows = 0;
    if (_fileBytes != null) {
      try {
        final csvString = utf8.decode(_fileBytes!);
        final List<List<String>> rows = _parseCSVManual(csvString);
        if (rows.length > 1) {
          totalFileRows = rows.length - 1;
        }
      } catch (_) {}
    }

    final skippedRowsList = _calculateSkippedRows();
    int skippedCount = skippedRowsList.length;

    int readyCount = totalFileRows - skippedCount;
    if (readyCount < 0) readyCount = 0;

    final mandatoryMissing =
        _mappings["Account Name"] == null || _mappings["Account Type"] == null;
    final noneCanBeImported = readyCount == 0 || mandatoryMissing;
    final String? previewError =
        mandatoryMissing ? "mandatory fields is missing" : _validationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepper(),

        // 1. Heading "Import Preview" with File Chip
        Row(
          children: [
            const Text(
              "Import Preview",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    _fileName ?? "",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (previewError != null && previewError.isNotEmpty) ...[
          _buildErrorBanner(previewError),
          const SizedBox(height: 16),
        ],

        // 2. Alert Box (Status Summary Banner)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: noneCanBeImported
                  ? [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)]
                  : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: noneCanBeImported
                  ? const Color(0xFFFECDD3)
                  : const Color(0xFFBBF7D0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (noneCanBeImported ? Colors.red : Colors.green)
                    .withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Highlight left bar
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: noneCanBeImported
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF10B981),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            noneCanBeImported
                                ? Icons.gpp_bad_rounded
                                : Icons.check_circle_rounded,
                            color: noneCanBeImported
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF059669),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                noneCanBeImported
                                    ? "Validation Check Failed"
                                    : "Data Validation Complete",
                                style: TextStyle(
                                  color: noneCanBeImported
                                      ? const Color(0xFF9F1239)
                                      : const Color(0xFF065F46),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                noneCanBeImported
                                    ? "None of the records can be imported due to configuration or mandatory field mapping errors."
                                    : "Your spreadsheet file is ready! $readyCount clean record(s) will be imported into the system.",
                                style: TextStyle(
                                  color: noneCanBeImported
                                      ? const Color(0xFFBE123C)
                                      : const Color(0xFF047857),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right side circular visual metric progress bar (e.g. 100% clean)
                        if (!noneCanBeImported && totalFileRows > 0) ...[
                          const SizedBox(width: 16),
                          _buildMiniCircularProgress(readyCount, totalFileRows),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // 3. Analytics Metrics Grid
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card 1: Ready
              _buildMetricCard(
                title: "Ready to Import",
                value: "$readyCount",
                description:
                    "Records validated and mapped successfully, clean for database entry.",
                icon: Icons.task_alt_rounded,
                activeColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                isSelected: _showReadyDetails,
                onTap: () {
                  setState(() {
                    _showReadyDetails = !_showReadyDetails;
                    _showSkippedDetails = false;
                    _showUnmappedDetails = false;
                  });
                },
              ),
              const SizedBox(width: 16),
              // Card 2: Skipped
              _buildMetricCard(
                title: "Skipped / Warnings",
                value: "$skippedCount",
                description:
                    "Records with validation or duplicate issues that will be ignored.",
                icon: Icons.warning_amber_rounded,
                activeColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
                isSelected: _showSkippedDetails,
                onTap: () {
                  setState(() {
                    _showSkippedDetails = !_showSkippedDetails;
                    _showReadyDetails = false;
                    _showUnmappedDetails = false;
                  });
                },
                actionButton: skippedCount == 0
                    ? null
                    : TextButton.icon(
                        onPressed: _downloadSkippedRows,
                        icon: const Icon(Icons.download_rounded, size: 13),
                        label: const Text("Export Log",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Card 3: Unmapped
              _buildMetricCard(
                title: "Unmapped Columns",
                value: "$unmappedCount",
                description:
                    "Spreadsheet columns that are not linked. Data will be bypassed.",
                icon: Icons.rule_folder_rounded,
                activeColor: const Color(0xFF64748B),
                bgColor: const Color(0xFFF1F5F9),
                isSelected: _showUnmappedDetails,
                onTap: () {
                  setState(() {
                    _showUnmappedDetails = !_showUnmappedDetails;
                    _showReadyDetails = false;
                    _showSkippedDetails = false;
                  });
                },
              ),
            ],
          )
        else
          // Stacking vertically for Mobile
          Column(
            children: [
              _buildMetricCard(
                title: "Ready to Import",
                value: "$readyCount",
                description: "Records mapped and ready for import.",
                icon: Icons.task_alt_rounded,
                activeColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                isSelected: _showReadyDetails,
                onTap: () {
                  setState(() {
                    _showReadyDetails = !_showReadyDetails;
                    _showSkippedDetails = false;
                    _showUnmappedDetails = false;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: "Skipped / Warnings",
                value: "$skippedCount",
                description: "Records containing validation errors.",
                icon: Icons.warning_amber_rounded,
                activeColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
                isSelected: _showSkippedDetails,
                onTap: () {
                  setState(() {
                    _showSkippedDetails = !_showSkippedDetails;
                    _showReadyDetails = false;
                    _showUnmappedDetails = false;
                  });
                },
                actionButton: skippedCount == 0
                    ? null
                    : TextButton.icon(
                        onPressed: _downloadSkippedRows,
                        icon: const Icon(Icons.download_rounded, size: 13),
                        label: const Text("Export Log",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: "Unmapped Columns",
                value: "$unmappedCount",
                description: "Spreadsheet columns bypassed.",
                icon: Icons.rule_folder_rounded,
                activeColor: const Color(0xFF64748B),
                bgColor: const Color(0xFFF1F5F9),
                isSelected: _showUnmappedDetails,
                onTap: () {
                  setState(() {
                    _showUnmappedDetails = !_showUnmappedDetails;
                    _showReadyDetails = false;
                    _showSkippedDetails = false;
                  });
                },
              ),
            ],
          ),

        // 4. Dynamic Details Accordion Panel
        if (_showReadyDetails) ...[
          const SizedBox(height: 24),
          _buildDetailContainer(
            title: "Ready to Import Accounts Details",
            accentColor: const Color(0xFF10B981),
            child: readyCount == 0
                ? const Text("No records are ready to import.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Estimated $readyCount transaction master accounts parsed from filename '$_fileName' will be imported.",
                          style: const TextStyle(
                              color: Color(0xFF334155), fontSize: 13.5)),
                      const SizedBox(height: 20),
                      const Text("Fields successfully mapped:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontSize: 14)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 68,
                        ),
                        itemCount: _mappings.entries
                            .where((e) => e.value != null)
                            .length,
                        itemBuilder: (context, index) {
                          final mapping = _mappings.entries
                              .where((e) => e.value != null)
                              .toList()[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                // System Target (Left side)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "SYSTEM FIELD",
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF94A3B8),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        mapping.key,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Connected Flow Arrow
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD1FAE5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Spreadsheet source (Right side)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "SPREADSHEET HEADER",
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF94A3B8),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        mapping.value!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],

        if (_showSkippedDetails) ...[
          const SizedBox(height: 24),
          _buildDetailContainer(
            title: "Skipped / Warning Records Detail Log",
            accentColor: const Color(0xFFF59E0B),
            child: skippedCount == 0
                ? const Text("No records are set to be skipped.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _duplicateHandling == 'skip'
                            ? "Based on your configuration 'Skip Duplicates':"
                            : "Based on your configuration 'Overwrite Duplicates':",
                        style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          "• $skippedCount record(s) with formatting issues or duplication will be ignored during database submission.",
                          style: const TextStyle(
                              color: Color(0xFFB45309), fontSize: 13.5)),
                      const SizedBox(height: 16),

                      // Visual Error List Cards Deck
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: skippedRowsList.length,
                          separatorBuilder: (context, index) => const Divider(
                              height: 1, color: Color(0xFFFEF3C7)),
                          itemBuilder: (context, index) {
                            final info = skippedRowsList[index];
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row badge circle
                                  Container(
                                    height: 28,
                                    width: 28,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${info.rowNo}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "Row No. ",
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                            Text(
                                              "${info.rowNo}",
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: const Color(
                                                        0xFFF59E0B)),
                                              ),
                                              child: Text(
                                                info.columnName,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          info.errorMessage,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: Color(0xFF92400E),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],

        if (_showUnmappedDetails) ...[
          const SizedBox(height: 24),
          _buildDetailContainer(
            title: "Unmapped Spreadsheet Columns Detail",
            accentColor: const Color(0xFF64748B),
            child: unmappedCount == 0
                ? const Text("All standard fields mapped successfully!",
                    style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "The following fields in your spreadsheet are not mapped to any system field. Their data will be silently ignored.",
                        style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13.5,
                            height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: unmappedList
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          size: 13,
                                          color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        f,
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
          ),
        ],

        const SizedBox(height: 40),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),

        // Action Buttons Footer Row persistent at the bottom
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Previous and Import
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _currentStep = 2;
                    _validationError = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  child: const Text("< Previous",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_isUploading ||
                          _mappings["Account Name"] == null ||
                          _mappings["Account Type"] == null)
                      ? null
                      : _submitImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Import",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // Right: Cancel
            OutlinedButton(
              onPressed: () {
                _clearSelectedFile();
                widget.onBack();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text("Cancel",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCircularProgress(int cleanCount, int totalCount) {
    double ratio = totalCount > 0 ? (cleanCount / totalCount) : 0.0;
    int percentage = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF10B981),
                  strokeWidth: 3.5,
                ),
                Center(
                  child: Text(
                    "$percentage%",
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Clean Data",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
              Text(
                "Ready to go",
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color activeColor,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? actionButton,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: activeColor.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : bgColor,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: activeColor.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: activeColor,
                          size: 22,
                        ),
                      ),
                      if (actionButton != null) actionButton,
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? activeColor : const Color(0xFF0F172A),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "ACTIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContainer({
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDuplicateHandlingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Duplicate Records Handling",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose how the system should handle records that already exist in the database.",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        // Option 1: Skip
        InkWell(
          onTap: () {
            setState(() {
              _duplicateHandling = 'skip';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _duplicateHandling == 'skip'
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
              border: Border.all(
                color: _duplicateHandling == 'skip'
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: _duplicateHandling == 'skip' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.block_flipped,
                      color: _duplicateHandling == 'skip'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Skip Duplicates",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _duplicateHandling == 'skip'
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF334155),
                      ),
                    ),
                    const Spacer(),
                    if (_duplicateHandling == 'skip')
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Do not import duplicate rows that already exist in your system (Recommended).",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Option 2: Overwrite
        InkWell(
          onTap: () {
            setState(() {
              _duplicateHandling = 'overwrite';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _duplicateHandling == 'overwrite'
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
              border: Border.all(
                color: _duplicateHandling == 'overwrite'
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: _duplicateHandling == 'overwrite' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.published_with_changes_rounded,
                      color: _duplicateHandling == 'overwrite'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Overwrite Duplicates",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _duplicateHandling == 'overwrite'
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF334155),
                      ),
                    ),
                    const Spacer(),
                    if (_duplicateHandling == 'overwrite')
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Update the existing records in the database with values from the imported spreadsheet.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFileCard(bool hasError) {
    return Container(
      key: const ValueKey('file_selected_card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_rounded,
            color: Color(0xFF3B82F6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _fileName!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isUploading ? null : _clearSelectedFile,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Remove",
                    style: TextStyle(
                      color: _isUploading
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            height: 32,
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _isUploading ? null : _pickCSVFile,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text(
                          "Replace File",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    InkWell(
                      onTap: _isUploading ? null : _pickCSVFile,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        child: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(Color stateBgColor, Color stateColor, bool hasError) {
    return InkWell(
      key: const ValueKey('upload_dropbox_frame'),
      onTap: _isUploading ? null : _pickCSVFile,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: stateBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stateColor, width: 2.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasError
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasError
                      ? Icons.warning_amber_rounded
                      : Icons.cloud_upload_outlined,
                  size: 44,
                  color: stateColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  "Click to browse and select files to upload",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasError
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Accepting text files, spreadsheets, and database formats",
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Widget _buildDecimalFormatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.numbers_rounded, color: Color(0xFF3B82F6), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "Decimal Format",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Configure decimal settings for number formatting during values parsing.",
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isFormatAtFieldLevel ? "Field Level" : _decimalFormat,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEditFormatDialog,
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text("Edit Format", style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildChartOfAccountsDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Chart of Account Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Container
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: const Text(
                        "SYSTEM FIELD",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(
                        width: 24), // Align with column spacing in rows
                    Expanded(
                      flex: 3,
                      child: const Text(
                        "SPREADSHEET HEADER",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Mapping Form Fields dynamically built as visual table row widgets
              ..._mappingFields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                final isLast = index == _mappingFields.length - 1;
                return _buildMappingRow(
                    field["name"], field["mandatory"], isLast);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMappingStep() {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepper(),

        // 1. Heading "Map Fields" with file chip tag
        Row(
          children: [
            const Text(
              "Map Fields",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    _fileName ?? "",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Beautiful Info Alert Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_rounded,
                  color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "We have auto-mapped fields matching standard system names. Please map any remaining columns.",
                  style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 3. Two-Column Split Layout
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Decimal Format Card (Narrower width, flex: 2) - COMMENTED OUT
              /*
              Expanded(
                flex: 2,
                child: _buildDecimalFormatCard(),
              ),
              const SizedBox(width: 40),
              */
              // Right Column: Chart of Accounts Mappings list (flex: 3)
              Expanded(
                flex: 3,
                child: _buildChartOfAccountsDetailsSection(),
              ),
            ],
          )
        else
          // Stacked vertically on Mobile
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildDecimalFormatCard(),
              // const SizedBox(height: 32),
              _buildChartOfAccountsDetailsSection(),
            ],
          ),

        const SizedBox(height: 32),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 20),

        // Save Selections Checkbox
        Row(
          children: [
            Checkbox(
              value: _saveSelections,
              onChanged: (val) {
                setState(() {
                  _saveSelections = val ?? false;
                });
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              activeColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 8),
            const Text(
              "Save these selections for use during future imports.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),

        if (_validationError != null && _validationError!.isNotEmpty) ...[
          _buildErrorBanner(_validationError!),
          const SizedBox(height: 16),
        ],

        // 5. Action Buttons Footer persistent at the bottom
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Group: Previous and Next
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _showMappingStep = false;
                    _currentStep = 1;
                    _validationError = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  child: const Text("< Previous",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final missing = _getUnmappedMandatoryFields();
                    if (missing.isNotEmpty) {
                      setState(() {
                        _validationError =
                            "Please map all mandatory database fields: ${missing.join(', ')} before proceeding to the preview.";
                      });
                    } else {
                      setState(() {
                        _validationError = null;
                        _currentStep = 3;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Next",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                ),
              ],
            ),

            // Right Group: Cancel
            OutlinedButton(
              onPressed: () {
                _clearSelectedFile();
                widget.onBack();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text("Cancel",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    );
  }

  // ================= INTERFACE GRAPHICS BUILD LAYER =================
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hasError = _validationError != null;
    final isFileSelected = _fileName != null;

    final Color stateColor = hasError
        ? const Color(0xFFEF4444)
        : (isFileSelected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1));

    final Color stateBgColor = hasError
        ? const Color(0xFFFEF2F2)
        : (isFileSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // HEADER DESIGN CONTROLLER
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Color(0xFF334155)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Import Company GL & Balances",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5),
                ),
                const Spacer(),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Download Template CSV",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1967D2),
                      side: const BorderSide(
                          color: Color(0xFF1967D2), width: 1.5),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          // SCROLL CONTENT COMPONENT BOX
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  padding: EdgeInsets.all(isMobile ? 20 : 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _currentStep == 1
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Stepper indicator at the top
                            _buildStepper(),
                            const SizedBox(height: 16),

                            // 2. Heading "Configure"
                            const Text(
                              "Configure",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 3. Two-Column Split Layout or vertical stacking
                            if (!isMobile)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column: Document Upload Zone
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: isFileSelected
                                              ? _buildSelectedFileCard(hasError)
                                              : _buildUploadCard(stateBgColor,
                                                  stateColor, hasError),
                                        ),
                                        if (!isFileSelected) ...[
                                          const SizedBox(height: 12),
                                          Center(
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: [
                                                const Icon(
                                                    Icons.info_outline_rounded,
                                                    size: 14,
                                                    color: Color(0xFF64748B)),
                                                const Text(
                                                  "Allowed formats: ",
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF475569),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: const Text("CSV",
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF0F172A),
                                                          fontFamily:
                                                              'monospace')),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: const Text("TSV",
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF0F172A),
                                                          fontFamily:
                                                              'monospace')),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: const Text("XLS",
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF0F172A),
                                                          fontFamily:
                                                              'monospace')),
                                                ),
                                                const Text("•",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFFCBD5E1))),
                                                const Text(
                                                  "Max Size: ",
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF475569),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const Text(
                                                  "25 MB",
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF0F172A),
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (hasError) ...[
                                          const SizedBox(height: 20),
                                          _buildErrorBanner(_validationError!),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                      width:
                                          48), // Spacious gap between columns

                                  // Right Column: Duplicate Error Handling
                                  Expanded(
                                    flex: 1,
                                    child: _buildDuplicateHandlingSelector(),
                                  ),
                                ],
                              )
                            else
                              // Stacking vertically on Mobile
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: isFileSelected
                                        ? _buildSelectedFileCard(hasError)
                                        : _buildUploadCard(
                                            stateBgColor, stateColor, hasError),
                                  ),
                                  if (!isFileSelected) ...[
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          const Icon(Icons.info_outline_rounded,
                                              size: 14,
                                              color: Color(0xFF64748B)),
                                          const Text(
                                            "Allowed formats: ",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF475569),
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: const Text("CSV",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                    fontFamily: 'monospace')),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: const Text("TSV",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                    fontFamily: 'monospace')),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: const Text("XLS",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                    fontFamily: 'monospace')),
                                          ),
                                          const Text("•",
                                              style: TextStyle(
                                                  color: Color(0xFFCBD5E1))),
                                          const Text(
                                            "Max Size: ",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF475569),
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const Text(
                                            "25 MB",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 28),
                                  _buildDuplicateHandlingSelector(),
                                  if (hasError) ...[
                                    const SizedBox(height: 20),
                                    _buildErrorBanner(_validationError!),
                                  ],
                                ],
                              ),

                            const SizedBox(height: 40),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 24),

                            // 4. Action Buttons Footer persistent at the bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: _fileBytes == null ||
                                          _isUploading ||
                                          _validationError != null
                                      ? null
                                      : () {
                                          _initializeMappings();
                                          setState(() {
                                            _showMappingStep = true;
                                            _currentStep = 2;
                                            _validationError = null;
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFFE2E8F0),
                                    disabledForegroundColor:
                                        const Color(0xFF94A3B8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 14),
                                    elevation: 0,
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : const Text("Next >",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold)),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    _clearSelectedFile();
                                    widget.onBack();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF334155),
                                    side: const BorderSide(
                                        color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                  ),
                                  child: const Text("Cancel",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ],
                        )
                      : (_currentStep == 2
                          ? _buildMappingStep()
                          : _buildPreviewStep()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkippedRowInfo {
  final int rowNo;
  final String columnName;
  final String errorMessage;

  SkippedRowInfo({
    required this.rowNo,
    required this.columnName,
    required this.errorMessage,
  });
}
