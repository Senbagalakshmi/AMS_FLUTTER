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

  // ================= PICK FILE =================
  void _pickCSVFile() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      if (uploadInput.files!.isNotEmpty) {
        final file = uploadInput.files![0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _fileName = file.name;
            _fileBytes = reader.result as Uint8List;
            _importResult = null; // Clear previous result
          });
        });
      }
    });
  }

  // ================= DOWNLOAD TEMPLATE =================
  void _downloadTemplate() {
    const csvContent = 
        "OrgCode,CompanyName,BranchCode,Currency,GlCatCd,GlCatName,GlCatType,GlCatSubType,GlNo,GlName,Balance\n"
        "101,My Company,1,INR,1,Assets,Asset,Current Assets,1001,Cash on Hand,5000.00\n"
        "101,My Company,1,INR,1,Assets,Asset,Current Assets,1002,Bank Account,12000.50\n"
        "101,My Company,1,INR,2,Liabilities,Liability,Current Liabilities,2001,Accounts Payable,-3500.00\n";

    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute("download", "company_import_template.csv")
      ..click();
      
    html.Url.revokeObjectUrl(url);
  }

  // ================= UPLOAD / SUBMIT =================
  Future<void> _submitImport() async {
    if (_fileBytes == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid CSV file first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
          content: Text("Successfully imported ${result['importedRows']} GL accounts!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg = result?['message'] ?? "Import failed. Please check the file formatting.";
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Import Error"),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              errorMsg,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // HEADER BAR
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBackToModule,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Import Company GL & Balances",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Download Template CSV"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1967D2),
                      side: const BorderSide(color: Color(0xFF1967D2)),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ),

          // MAIN BODY
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert Header Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "This tool allows importing existing company structures. Uploading a CSV will create the Organisation, categories, GL accounts, and post initial balances into the ledger transaction log.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E40AF),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Drag and Drop Styled Container
                      InkWell(
                        onTap: _isUploading ? null : _pickCSVFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _fileName != null ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _fileName != null ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
                                size: 56,
                                color: _fileName != null ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _fileName ?? "Click to browse and select CSV file",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _fileName != null ? const Color(0xFF1E293B) : const Color(0xFF475569),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              if (_fileName == null)
                                const Text(
                                  "Only .csv files are supported",
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                )
                              else
                                Text(
                                  "${(_fileBytes!.length / 1024).toStringAsFixed(2)} KB",
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Template Downloader for Mobile view
                      if (isMobile) ...[
                        OutlinedButton.icon(
                          onPressed: _downloadTemplate,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text("Download Template CSV"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Upload Success Box
                      if (_importResult != null && _importResult!['status'] == 'SUCCESS') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF15803D)),
                                  SizedBox(width: 8),
                                  Text(
                                    "Import Completed Successfully!",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text("• Total rows parsed: ${_importResult!['totalRows']}"),
                              Text("• Successfully imported: ${_importResult!['importedRows']}"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Import trigger Button
                      ElevatedButton(
                        onPressed: _fileBytes == null || _isUploading ? null : _submitImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1967D2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text("Importing Data...", style: TextStyle(fontSize: 16)),
                                ],
                              )
                            : const Text("Import Company Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
