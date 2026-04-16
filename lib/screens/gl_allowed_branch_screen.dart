import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/gl_api_service.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

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
  String _searchQuery = '';
  final TextEditingController orgCodeController = TextEditingController(text: "50");
  String? _orgError;
  List<Map<String, dynamic>> savedList = [];

  /// GL Masters (same pattern as GL Segments)
  List<Map<String, dynamic>> _glMasters = [];
  bool _loadingGlMasters = false;
  Map<String, dynamic>? _selectedGlMaster;

  /// Branch List
  List<Map<String, dynamic>> branches = [
    {"code": "HO", "name": "Head Office", "enabled": true},
    {"code": "BLR", "name": "Bangalore", "enabled": true},
    {"code": "MUM", "name": "Mumbai", "enabled": true},
    {"code": "CHN", "name": "Chennai", "enabled": false},
    {"code": "DEL", "name": "Delhi", "enabled": false},
  ];

  Future<void> _loadGlMasters() async {
    setState(() => _loadingGlMasters = true);
    final data = await apiService.getAllGlMasters();
    setState(() {
      _loadingGlMasters = false;
      _glMasters = data?.items ?? [];
    });
  }

  Future<void> loadSavedBranches() async {
    final response = await GLApiService().getGl104List();
    if (response != null) {
      setState(() {
        // Map backend format to local UI format
        savedList = response.map<Map<String, dynamic>>((backendItem) {
          
          final glNo = (backendItem['glNo'] ?? backendItem['GLNO'] ?? backendItem['GlNo'] ?? backendItem['glno'])?.toString() ?? '';
          
          // Attempt to find the matching GL master
          String glDisplay = "GL $glNo";
          try {
            final matched = _glMasters.firstWhere((m) => m['glNo']?.toString() == glNo);
            final glName = matched['glName']?.toString() ?? '';
            glDisplay = "GL $glNo — $glName";
          } catch(e) {
            // keep default
          }
          
          final rawBranches = (backendItem['allowedBrn'] ?? backendItem['ALLOWEDBRN'] ?? backendItem['AllowedBrn'] ?? backendItem['allowedbrn'])?.toString() ?? "";
          final branchesList = rawBranches.split(",").where((s) => s.trim().isNotEmpty).toList();

          final orgCode = backendItem['orgCode'] ?? backendItem['ORGCODE'] ?? backendItem['OrgCode'] ?? backendItem['orgcode'];

          return {
            ...backendItem,
            "orgCode": orgCode,
            "glNo": glNo,
            "gl": "GL $glNo",
            "gl_full": glDisplay,
            "branches": branchesList
          };
        }).toList().reversed.toList();
      });
    }
  }

  Future<void> initData() async {
    await _loadGlMasters();
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
                    _selectedGlMaster = null;
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
                                (item["gl"] ?? "G")
                                    .toString()
                                    .replaceAll("GL ", "")
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
                                    // Match the GL master from the list
                                    final glNo = item["glNo"]?.toString();
                                    try {
                                      _selectedGlMaster = _glMasters.firstWhere((m) => m['glNo']?.toString() == glNo);
                                    } catch (_) {
                                      _selectedGlMaster = null;
                                    }
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
                                    // Match the GL master from the list
                                    final glNo = item["glNo"]?.toString();
                                    try {
                                      _selectedGlMaster = _glMasters.firstWhere((m) => m['glNo']?.toString() == glNo);
                                    } catch (_) {
                                      _selectedGlMaster = null;
                                    }
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
                                            
                                            // Use glNo directly
                                            final int? parsedGlNo = int.tryParse(item["glNo"]?.toString() ?? '');

                                            print("DELETE ITEM: $item");
                                            print("DELETE parsedGlNo: $parsedGlNo");

                                            if (parsedGlNo != null) {
                                              setState(() {
                                                 _isLoading = true;
                                              });
                                              final orgCode = item["orgCode"] ?? 50;
                                              print("DELETE orgCode: $orgCode (${orgCode.runtimeType})");

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
                    _orgError = "Organisation Code is required.";
                  });
                  showAmsSnack(context, "Please enter an Organisation Code.", type: 'e');
                  return;
                }

                if (_selectedGlMaster == null) {
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

                final parsedGlNo = _selectedGlMaster!['glNo'] as int?;

                final payload = {
                  "orgCode": int.tryParse(orgCodeController.text) ?? 50,
                  "glNo": parsedGlNo,
                  "allowedBrn": selectedBranches.join(",")
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
        /// Organisation Code
        AmsField(
          label: "Organisation Code",
          labelAbove: true,
          child: AmsTextInput(
            placeholder: "Enter Organisation Code",
            controller: orgCodeController,
            readOnly: _isViewOnly || _isEditMode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
       /// Select GL Account (same pattern as GL Segments)
       const Text('* Select GL Account',
           style: TextStyle(
               fontSize: 13,
               fontWeight: FontWeight.w600,
               color: Color(0xFF475569))),
       const SizedBox(height: 8),
       if (_loadingGlMasters)
         const Padding(
           padding: EdgeInsets.symmetric(vertical: 14),
           child: SizedBox(
             width: 22,
             height: 22,
             child: CircularProgressIndicator(strokeWidth: 2),
           ),
         )
       else if (_glMasters.isEmpty)
         Container(
           width: double.infinity,
           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
           decoration: BoxDecoration(
             color: const Color(0xFFF1F5FB),
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
           ),
           child: Row(children: [
             const Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
             const SizedBox(width: 8),
             const Text('No GL Accounts found.',
                 style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
             const Spacer(),
             GestureDetector(
               onTap: _loadGlMasters,
               child: const Icon(Icons.refresh, size: 16, color: AppColors.sidebar),
             ),
           ]),
         )
       else
         Container(
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
           ),
           padding: const EdgeInsets.symmetric(horizontal: 14),
           child: DropdownButtonHideUnderline(
             child: DropdownButton<Map<String, dynamic>>(
               value: _selectedGlMaster,
               isExpanded: true,
               hint: const Text(
                 'Select GL Account',
                 style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
               ),
               style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
               icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569)),
               items: [
                 const DropdownMenuItem<Map<String, dynamic>>(
                   value: null,
                   child: Text(
                     'Select GL Account',
                     style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                   ),
                 ),
                 ..._glMasters.map((gl) {
                   final glNo = gl['glNo']?.toString() ?? '';
                   final glName = gl['glName']?.toString() ?? '';
                   return DropdownMenuItem<Map<String, dynamic>>(
                     value: gl,
                     child: Text('GL $glNo — $glName'),
                   );
                 }),
               ],
               onChanged: (_isViewOnly || _isEditMode) ? null : (v) => setState(() => _selectedGlMaster = v),
             ),
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
