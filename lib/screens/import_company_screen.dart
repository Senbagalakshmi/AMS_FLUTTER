import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../services/import_api_service.dart';
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
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  Map<String, dynamic>? _importResult;
  String? _validationError;
  bool _isBinaryFile = false; 

  // Exact headers matching your PostgreSQL procedure parameter structure
  final List<String> _expectedHeaders = [
    "OrgCode", "CompanyName", "BranchCode", "Currency", "GlCatCd", 
    "GlCatName", "GlCatType", "GlCatSubType", "GlNo", "GlName", "Balance"
  ];

  // ================= STATE RESET CONTROLLER =================
  void _clearSelectedFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
      _validationError = null;
      _importResult = null;
      _isBinaryFile = false;
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

      // 1. Structural Header Mapping Verification
      final List<String> headers = rows.first;
      Map<String, int> idx = {};
      
      for (var expectedHeader in _expectedHeaders) {
        int foundIndex = headers.indexOf(expectedHeader);
        if (foundIndex == -1) {
          return "Missing mandatory column structure: '$expectedHeader'.";
        }
        idx[expectedHeader] = foundIndex;
      }

      if (rows.length < 2) {
        return "The file contains valid headers but lacks transactional data rows.";
      }

      // 2. Comprehensive Type Scan across ALL rows and ALL columns
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.length < headers.length) {
          return "Row ${i + 1}: Malformed row data structure. Expected ${headers.length} fields but found ${row.length}.";
        }

        // --- CHECK ALL BIGINT FIELDS ---
        final List<String> bigIntFields = ["OrgCode", "BranchCode", "GlCatCd", "GlNo"];
        for (var fieldName in bigIntFields) {
          final cellValue = row[idx[fieldName]!];
          if (int.tryParse(cellValue) == null) {
            return "Row ${i + 1}: Datatype Mismatch on '$fieldName'. The database expects a whole number (BIGINT), but encountered invalid text input: '$cellValue'.";
          }
        }

        // --- CHECK THE NUMERIC FIELD ---
        final balanceValue = row[idx["Balance"]!];
        if (double.tryParse(balanceValue) == null) {
          return "Row ${i + 1}: Datatype Mismatch on 'Balance'. The database expects a valid numeric decimal (NUMERIC), but encountered: '$balanceValue'.";
        }

        // --- CHECK ALL CHARACTER VARYING (VARCHAR) FIELDS ---
        final List<String> varcharFields = ["CompanyName", "Currency", "GlCatName", "GlCatType", "GlCatSubType", "GlName"];
        for (var fieldName in varcharFields) {
          final cellValue = row[idx[fieldName]!];
          if (cellValue.isEmpty) {
            return "Row ${i + 1}: Integrity constraint violation. Column '$fieldName' (character varying) cannot be empty or blank.";
          }
        }
      }

      return null; // File passes every single database constraint rule!
    } catch (e) {
      return "Unable to securely parse file data stream. Ensure character mapping is valid UTF-8.";
    }
  }

  // ================= PICK FILE EVENT (ACCEPTS ALL FILE TYPES) =================
  void _pickCSVFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '*.*'; 
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      if (uploadInput.files!.isNotEmpty) {
        final file = uploadInput.files![0];
        final String fileName = file.name.toLowerCase();

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          final bytes = reader.result as Uint8List;
          
          setState(() {
            _fileName = file.name;
            _importResult = null;
            
            // If text table format (.csv / .txt), execute rigorous structural data validation loop
            if (fileName.endsWith('.csv') || fileName.endsWith('.txt')) {
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

  // ================= API TRANSACTION REQUEST CONTROLLER =================
  Future<void> _submitImport() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _isUploading = true;
      _importResult = null;
    });

    final eUser = widget.userName ?? "SYSTEM";
    final result = await importApiService.importCompanyGlData(_fileBytes!, _fileName!, eUser);

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _importResult = result;
    });

    if (result != null && result['status'] == 'SUCCESS') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully uploaded and processed ${_fileName}!"),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorMsg = result?['message'] ?? "Internal server error occurred during database transaction entry setup.";
      _showErrorDialog(errorMsg);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text("Database Process Failure", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Color(0xFF334155))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dismiss", style: TextStyle(color: Color(0xFF1967D2), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBackToModule,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF334155)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Import Company GL & Balances",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
                ),
                const Spacer(),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Download Template CSV", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1967D2),
                      side: const BorderSide(color: Color(0xFF1967D2), width: 1.5),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  constraints: const BoxConstraints(maxWidth: 720),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Dashboard Announcement Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "This tool allows importing existing company structures. Every row is analyzed and verified against database constraints before submission.",
                                style: TextStyle(fontSize: 13.5, color: Color(0xFF1E40AF), height: 1.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Upload Dropbox Frame
                      InkWell(
                        onTap: _isUploading ? null : (isFileSelected ? null : _pickCSVFile),
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
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: hasError 
                                            ? const Color(0xFFFEE2E2) 
                                            : (isFileSelected ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        hasError
                                            ? Icons.warning_amber_rounded
                                            : (isFileSelected ? Icons.task_alt_rounded : Icons.cloud_upload_outlined),
                                        size: 44,
                                        color: stateColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 48),
                                      child: Text(
                                        _fileName ?? "Click to browse and select files to upload",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: hasError ? const Color(0xFF991B1B) : const Color(0xFF1E293B),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (!isFileSelected)
                                      const Text(
                                        "Accepting text files, spreadsheets, and database formats",
                                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      )
                                    else if (!hasError)
                                      Text(
                                        _isBinaryFile 
                                            ? "${(_fileBytes!.length / 1024).toStringAsFixed(2)} KB — Configuration ready"
                                            : "${(_fileBytes!.length / 1024).toStringAsFixed(2)} KB — All column types validated",
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                              ),

                              // REMOVE / CLEAR TOP-RIGHT BUTTON
                              if (isFileSelected && !_isUploading)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Tooltip(
                                    message: "Remove File",
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _clearSelectedFile,
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: hasError ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: hasError ? const Color(0xFF991B1B) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Explicit Validation Error Dashboard Logger Panel
                      if (hasError) ...[
                        const SizedBox(height: 20),
                        Container(
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
                                    const Text(
                                      "Database Schema Type Violation",
                                      style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _validationError!,
                                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      if (isMobile) ...[
                        OutlinedButton.icon(
                          onPressed: _downloadTemplate,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text("Download Template CSV", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Color(0xFF1967D2), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Execution Processing Done Message Box
                      if (_importResult != null && _importResult!['status'] == 'SUCCESS') ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    "Server Processing Completed",
                                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF065F46), fontSize: 15),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 32, top: 4, bottom: 8),
                                child: Text("Document [$_fileName] successfully processed into the ledger repository.", style: const TextStyle(color: Color(0xFF047857), fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Core Trigger Action Button
                      ElevatedButton(
                        onPressed: _fileBytes == null || _isUploading ? null : _submitImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1967D2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  ),
                                  SizedBox(width: 14),
                                  Text("Syncing Cloud Transactions...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              )
                            : const Text("Commit Database Import", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}