import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/gl_api_service.dart';

class AllowedBranchScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final void Function(String key, dynamic val) onChanged;
  final Map<String, dynamic>? initialData;
  final bool isViewMode;

  const AllowedBranchScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    required this.onChanged,
    this.initialData,
    this.isViewMode = false,
  });

  @override
  State<AllowedBranchScreen> createState() => _AllowedBranchScreenState();
}

class _AllowedBranchScreenState extends State<AllowedBranchScreen> {
  bool showForm = false;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isViewOnly = false;
  String? selectedGL;
  String? _originalGL;
  String _searchQuery = '';
  final TextEditingController orgCodeController = TextEditingController(text: "50");
  String? _orgError;
  List<Map<String, dynamic>> savedList = [];
  /// GL Accounts
  List<String> glAccounts = [];

  /// Branch List
  List<Map<String, dynamic>> branches = [
    {"code": "HO", "name": "Head Office", "enabled": true},
    {"code": "BLR", "name": "Bangalore", "enabled": true},
    {"code": "MUM", "name": "Mumbai", "enabled": true},
    {"code": "CHN", "name": "Chennai", "enabled": false},
    {"code": "DEL", "name": "Delhi", "enabled": false},
  ];

  Future<void> loadGLAccounts() async {
    final response = await GLApiService().getGlList();

    if (response != null && response.isNotEmpty) {
      setState(() {
        glAccounts = response.map<String>((item) {
          final glNo = item['GLNO'] ?? item['glNo'] ?? item['glno'] ?? item['gl_no'] ?? item['GlNo'] ?? '';
          final glName = item['GLNAME'] ?? item['glName'] ?? item['glname'] ?? item['gl_name'] ?? item['GlName'] ?? '';
          return "GL $glNo — $glName";
        }).toSet().toList();
      });
    }
  }

  Future<void> loadSavedBranches() async {
    final response = await GLApiService().getGl104List();
    if (response != null) {
      setState(() {
        // Map backend format to local UI format
        savedList = response.map<Map<String, dynamic>>((backendItem) {
          
          final glNo = (backendItem['glNo'] ?? backendItem['GLNO'] ?? backendItem['GlNo'] ?? backendItem['glno'])?.toString();
          
          // Attempt to find the full display name from glAccounts, otherwise fallback
          String matchedGl = "GL $glNo —";
          try {
            matchedGl = glAccounts.firstWhere((element) => element.contains("GL $glNo "));
          } catch(e) {}
          
          final rawBranches = (backendItem['allowedBrn'] ?? backendItem['ALLOWEDBRN'] ?? backendItem['AllowedBrn'] ?? backendItem['allowedbrn'])?.toString() ?? "";
          final branchesList = rawBranches.split(",").where((s) => s.trim().isNotEmpty).toList();

          final orgCode = backendItem['orgCode'] ?? backendItem['ORGCODE'] ?? backendItem['OrgCode'] ?? backendItem['orgcode'];

          return {
            "orgCode": orgCode,
            "gl": matchedGl,
            "branches": branchesList
          };
        }).toList();
      });
    }
  }

  Future<void> initData() async {
    await loadGLAccounts();
    await loadSavedBranches();
  }

  @override
  void dispose() {
    orgCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initData();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          /// Header
          AmsIdentityHeader(
            icon: const Icon(
              Icons.account_tree_rounded,
              size: 28,
              color: AppColors.tBlue,
            ),
            title: 'Allowed Branches (GL104)',
            subtitle: '',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(
                label: 'Home',
                onTap: widget.onBack,
              ),
              HeaderBreadcrumb(
                label: 'GL Module',
                onTap: widget.onBackToModule,
              ),
              HeaderBreadcrumb(
                label: 'Allowed Branch',
              ),
            ],
            onBack: widget.onBackToModule,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: showForm ? _buildFormView() : _buildListView(),
            ),
          ),
        ],
      ),
    );
  }

  /// ================================
  /// LIST VIEW
  /// ================================
Widget _buildListView() {
  final filteredList = savedList.where((item) {
    if (_searchQuery.trim().isEmpty) return true;
    final gl = (item["gl"] ?? "").toString().toLowerCase();
    final branchesText = ((item["branches"] as List?) ?? []).join(", ").toLowerCase();
    final q = _searchQuery.toLowerCase().trim();
    return gl.contains(q) || branchesText.contains(q);
  }).toList();

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [

        /// Top Search Row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AmsTextInput(
                  icon: Icons.search_rounded,
                  placeholder: 'Search branches...',
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v?.toString() ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  loadSavedBranches();
                },
              ),
              const SizedBox(width: 16),
              AmsButton(
                label: '+ Add New',
                onPressed: () {
                  setState(() {
                    showForm = true;
                    _isEditMode = false;
                    _isViewOnly = false;
                    selectedGL = null;
                    _originalGL = null;
                    orgCodeController.text = "50";
                    _orgError = null;
                    for (var b in branches) {
                      b["enabled"] = false;
                    }
                  });
                },
              ),
            ],
          ),
        ),

        /// List Cards
        Expanded(
          child: filteredList.isEmpty
              ? const Center(child: Text("No Records Found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {

                    final item = filteredList[index];
                    final branchesText =
                        (item["branches"] as List).join(", ");

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [

                          /// Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                item["gl"]
                                    .toString()
                                    .substring(0, 1),
                                style: bodyStyle(
                                  weight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          /// Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  item["gl"] ?? "",
                                  style: bodyStyle(
                                    weight: FontWeight.w600,
                                    size: 15,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  "Branches: $branchesText",
                                  style: bodyStyle(
                                    color: AppColors.ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _actionIcon(
                                icon: Icons.visibility_outlined,
                                color: AppColors.green,
                                bg: Colors.white,
                                onTap: () {
                                  setState(() {
                                    showForm = true;
                                    _isViewOnly = true;
                                    _isEditMode = false;
                                    selectedGL = item["gl"];
                                    _originalGL = item["gl"];
                                    orgCodeController.text = item["orgCode"]?.toString() ?? "50";
                                    final savedBranches = item["branches"] as List;
                                    for (var b in branches) {
                                      b["enabled"] = savedBranches.contains(b["name"]);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _actionIcon(
                                icon: Icons.edit_outlined,
                                color: AppColors.tBlue,
                                bg: Colors.white,
                                onTap: () {
                                  setState(() {
                                    showForm = true;
                                    _isEditMode = true;
                                    _isViewOnly = false;
                                    selectedGL = item["gl"];
                                    _originalGL = item["gl"];
                                    orgCodeController.text = item["orgCode"]?.toString() ?? "50";
                                    final savedBranches = item["branches"] as List;
                                    for (var b in branches) {
                                      b["enabled"] = savedBranches.contains(b["name"]);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _actionIcon(
                                icon: Icons.delete_outline_rounded,
                                color: AppColors.red,
                                bg: AppColors.redLt,
                                borderColor: AppColors.red.withOpacity(0.2),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text('Are you sure you want to delete?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context); // Close the dialog
                                            
                                            // Extract GL No to delete from backend
                                            final match = RegExp(r'GL (\d+) ').firstMatch(item["gl"] ?? '');
                                            final int? parsedGlNo = match != null ? int.tryParse(match.group(1) ?? '') : null;

                                            if (parsedGlNo != null) {
                                              setState(() {
                                                 _isLoading = true;
                                              });
                                              final orgCode = item["orgCode"] ?? 50;

                                              final success = await GLApiService()
                                              .deleteAllowedBranch(orgCode, parsedGlNo);

                                              if (success) {
                                                showAmsSnack(context, 'Deleted successfully.', type: 's');
                                                await loadSavedBranches(); // refresh from db
                                              } else {
                                                showAmsSnack(context, 'Deletion failed.', type: 'e');
                                              }
                                              
                                              setState(() {
                                                 _isLoading = false;
                                              });
                                            } else {
                                              // Fallback if formatting failed, just remove locally
                                              setState(() {
                                                savedList.remove(item);
                                              });
                                            }
                                          },
                                          child: const Text(
                                            'Yes',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          )

                        ],
                      ),
                    );
                  },
                ),
        ),

      ],
    ),
  );
}

  /// ================================
  /// FORM VIEW
  /// ================================
  Widget _buildFormView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.sidebar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Create Allowed Branches",
                  style: bodyStyle(
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildFormContentOnly(),
            ),
          ),
          _buildFixedFooter(),
        ],
      ),
    );
  }

  Widget _buildFixedFooter() {
    return AmsSubmitBar(
      borderColor: AppColors.border,
      actions: [
        if (_isLoading)
          const SizedBox(
            width: 80,
            height: 36,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.tBlue,
                ),
              ),
            ),
          )
        else ...[
          if (!_isViewOnly) ...[
            AmsButton(
              label: _isEditMode ? 'Update' : 'Save',
              variant: AmsButtonVariant.primary,
              backgroundColor: AppColors.sidebar,
              onPressed: () async {

                final selectedBranches = branches
                .where((b) => b["enabled"] == true)
                .map((b) => b["name"])
                .toList();

                if (orgCodeController.text.trim().isEmpty) {
                  setState(() {
                    _orgError = "Organization Code is required.";
                  });
                  showAmsSnack(context, "Please enter an Organization Code.", type: 'e');
                  return;
                }

                if (selectedGL == null) {
                  showAmsSnack(context, "Please select a GL Account.", type: 'e');
                  return;
                }

                if (selectedBranches.isEmpty) {
                  showAmsSnack(context, "Please select at least one branch.", type: 'e');
                  return;
                }

                setState(() {
                  _isLoading = true;
                });

                // Extract the integer 101 from "GL 101 — Cash"
                int? parsedGlNo;
                if (selectedGL != null) {
                   final match = RegExp(r'GL (\d+) ').firstMatch(selectedGL!);
                   if (match != null) {
                      parsedGlNo = int.tryParse(match.group(1) ?? '');
                   }
                }

                final payload = {
                  "orgCode": int.tryParse(orgCodeController.text) ?? 50,
                  "glNo": parsedGlNo,
                  "allowedBrn": selectedBranches.join(",")
                };

                // Local UI payload for snappy UI response
                final localPayload = {
                   "gl": selectedGL,
                   "branches": selectedBranches
                };

                final bool success;
                if (_isEditMode) {
                  success = await GLApiService().updateAllowedBranch(payload);
                } else {
                  success = await GLApiService().saveAllowedBranch(payload);
                }

                if (success) {
                   // Pull fresh data directly from Backend DB
                   await loadSavedBranches();
                }

                setState(() {
                  _isLoading = false;

                  if (success) {
                     showAmsSnack(context, _isEditMode ? 'Allowed branches updated successfully.' : 'Allowed branches saved.', icon: '✅');
                  } else {
                     showAmsSnack(context, 'Save failed.', icon: '⚠️');
                  }
                  
                  showForm = false;
                });
              },
            ),
            AmsButton(
              label: 'Clear',
              icon: Icons.clear_all_rounded,
              variant: AmsButtonVariant.outline,
              onPressed: () {
                setState(() {
                  _orgError = null;
                  for (var b in branches) {
                    b["enabled"] = false;
                  }
                });
              },
            ),
          ],
          AmsButton(
            label: _isViewOnly ? 'Back' : 'Cancel',
            icon: _isViewOnly ? Icons.arrow_back : Icons.close_rounded,
            variant: _isViewOnly ? AmsButtonVariant.outline : AmsButtonVariant.danger,
            onPressed: () {
              setState(() {
                showForm = false;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFormContentOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Org Code
        AmsField(
          label: "Org Code",
          labelAbove: true,
          child: AmsTextInput(
            placeholder: "Enter Org Code",
            controller: orgCodeController,
            readOnly: _isViewOnly,
            keyboardType: TextInputType.number,
            errorText: _orgError,
            onChanged: (v) {
              if (v.trim().isNotEmpty && _orgError != null) {
                setState(() {
                  _orgError = null;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 20),

        /// Select GL
       AmsField(
         label: "Select GL Account",
         labelAbove: true,
         child: glAccounts.isEmpty
         ? const SizedBox(
          height: 40,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        )
      : AmsDropdown(
          items: glAccounts,
          initialValue: selectedGL,
          placeholder: 'Please Select',
          onChanged: (v) {
            setState(() {
              selectedGL = v;
            });
          },
        ),
     ),
        const SizedBox(height: 20),

        /// Branch List
        ...branches.map((branch) {
          final isEnabled = branch["enabled"] == true;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isEnabled ? AppColors.tBlue.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? AppColors.tBlue.withOpacity(0.3)
                    : AppColors.border,
                width: 1,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.tBlue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Unique Left Accent Bar
                if (isEnabled)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: AppColors.tBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(left: isEnabled ? 12 : 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isEnabled ? AppColors.tBlueLt : AppColors.bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isEnabled
                                ? AppColors.tBlue.withOpacity(0.2)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          branch["code"],
                          style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w800,
                            color: isEnabled ? AppColors.tBlue : AppColors.ink2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          branch["name"],
                          style: bodyStyle(
                            color: isEnabled ? AppColors.ink : AppColors.ink3,
                            weight:
                                isEnabled ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      _PremiumToggle(
                        value: branch["enabled"],
                        onChanged: (v) {
                          setState(() {
                            branch["enabled"] = v;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required Color bg,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor ?? AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PremiumToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value
              ? AppColors.tBlue.withOpacity(0.8)
              : Colors.grey.withOpacity(0.3),
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
