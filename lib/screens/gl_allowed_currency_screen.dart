import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/gl_api_service.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class AllowedCurrencyScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final void Function(String key, dynamic val) onChanged;
  final Map<String, dynamic>? initialData;
  final bool isViewMode;

  const AllowedCurrencyScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    required this.onChanged,
    this.initialData,
    this.isViewMode = false,
  });

  @override
  State<AllowedCurrencyScreen> createState() => _AllowedCurrencyScreenState();
}

class _AllowedCurrencyScreenState extends State<AllowedCurrencyScreen> {
  bool showForm = false;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isViewOnly = false;
  String? _orgError;
  String? _glError;
  String _searchQuery = "";
  final TextEditingController _orgCodeCtrl = TextEditingController(text: "50");
  Map<String, dynamic>? _selectedRecord;

  /// GL Masters (same pattern as GL Segments)
  List<Map<String, dynamic>> _glMasters = [];
  bool _loadingGlMasters = false;
  Map<String, dynamic>? _selectedGlMaster;

  List<Map<String, dynamic>> savedList = [];
  final TextEditingController _currencyCtrl = TextEditingController();

  List<String> currencies = ["INR", "USD", "GBP", "EUR", "SGD"];

  final List<Color> chipColors = [
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.teal.shade100,
  ];
  
  Future<void> loadSavedCurrencies() async {
    final response = await GLApiService().getGl103List();
    if (response != null && response.isNotEmpty) {
      setState(() {
        savedList = response.map((item) {
          final glNo = (item["glNo"] ?? item["GLNO"] ?? item["GlNo"] ?? item["glno"])?.toString() ?? "";
          
          String glDisplay = "GL $glNo";
          try {
            final matched = _glMasters.firstWhere((m) => m['glNo']?.toString() == glNo);
            final glName = matched['glName']?.toString() ?? '';
            glDisplay = "GL $glNo — $glName";
          } catch(e) {
            // keep default
          }
          
          final raw = item["allowedCurr"] ??
              item["ALLOWEDCURR"] ??
              item["allowedcurr"] ??
              "";
          final currencies = raw
              .toString()
              .split(",")
              .where((e) => e.trim().isNotEmpty)
              .toList();
          return {
            ...item,
            "orgCode": item["orgCode"] ?? item["ORGCODE"] ?? 50,
            "glNo": glNo,
            "gl": "GL $glNo",
            "gl_full": glDisplay,
            "currencies": currencies
          };
        }).toList().reversed.toList();
      });
    } else {
      setState(() {
        savedList = [];
      });
    }
  }
  
  void addCurrency() {
    if (_currencyCtrl.text.isNotEmpty) {
      setState(() {
        currencies.insert(0, _currencyCtrl.text.toUpperCase());
        _currencyCtrl.clear();
      });
    }
  }

  void removeCurrency(String currency) {
    setState(() {
      currencies.remove(currency);
    });
  }

  Future<void> _loadGlMasters() async {
    setState(() => _loadingGlMasters = true);
    final data = await apiService.getAllGlMasters();
    setState(() {
      _loadingGlMasters = false;
      _glMasters = data?.items ?? [];
    });
  }

  Future<void> initData() async {
    await _loadGlMasters();
    await loadSavedCurrencies();
  }
  

  @override
  void initState() {
    super.initState();
    initData();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(
              Icons.currency_exchange_rounded,
              size: 28,
              color: AppColors.tBlue,
            ),
            title: 'Allowed Currencies',
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
                label: 'Allowed Currency',
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

  Widget _buildListView() {
    final filteredList = savedList.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final gl = (item["gl"] ?? "").toString().toLowerCase();
      final currText =
          ((item["currencies"] as List?) ?? []).join(", ").toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      return gl.contains(q) || currText.contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          /// Search + Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AmsTextInput(
                    icon: Icons.search_rounded,
                    placeholder: 'Search currencies...',
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v?.toString() ?? "";
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    loadSavedCurrencies();
                  },
                ),
                const SizedBox(width: 16),
                AmsButton(
                  label: '+ Add New',
                  variant: AmsButtonVariant.primary,
                  onPressed: () {
                    setState(() {
                      _isEditMode = false;
                      _isViewOnly = false;
                      _selectedRecord = null;
                      _orgError = null;
                      _glError = null;
                      _orgCodeCtrl.text = "50";
                      _selectedGlMaster = null;
                      currencies = ["INR", "USD", "GBP", "EUR", "SGD"];
                      _currencyCtrl.clear();
                      showForm = true;
                    });
                  },
                ),
              ],
            ),
          ),

          /// List View
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text("No records found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final currText =
                          ((item["currencies"] ?? []) as List).join(", ");

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
                              decoration: const BoxDecoration(
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

                          /// Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  "Currencies: $currText",
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
                              /// View
                              _actionIcon(
                                icon: Icons.visibility_rounded,
                                color: Colors.green,
                                bg: Colors.green.withOpacity(0.1),
                                onTap: () {
                                  setState(() {
                                    _isEditMode = false;
                                    _isViewOnly = true;
                                    _selectedRecord = item;
                                    _orgCodeCtrl.text =
                                        item["orgCode"].toString();
                                    final glNo = item["glNo"]?.toString();
                                    try {
                                      _selectedGlMaster = _glMasters.firstWhere((m) => m['glNo']?.toString() == glNo);
                                    } catch (_) {
                                      _selectedGlMaster = null;
                                    }
                                    currencies = List<String>.from(
                                        item["currencies"]);
                                    showForm = true;
                                  });
                                },
                              ),

                              const SizedBox(width: 8),

                              /// Edit
                              _actionIcon(
                                icon: Icons.edit_rounded,
                                color: Colors.blue,
                                bg: Colors.blue.withOpacity(0.1),
                                onTap: () {
                                  setState(() {
                                    _isEditMode = true;
                                    _isViewOnly = false;
                                    _selectedRecord = item;
                                    _orgCodeCtrl.text =
                                        item["orgCode"].toString();

                                    final glNo = item["glNo"]?.toString();
                                    try {
                                      _selectedGlMaster = _glMasters.firstWhere((m) => m['glNo']?.toString() == glNo);
                                    } catch (_) {
                                      _selectedGlMaster = null;
                                    }

                                    currencies = List<String>.from(
                                        item["currencies"]);

                                    showForm = true;
                                  });
                                },
                              ),

                              const SizedBox(width: 8),

                              /// Delete
                              _actionIcon(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red,
                                bg: Colors.red.withOpacity(0.1),
                                onTap: () async {
                                  final confirm =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (context) =>
                                        AlertDialog(
                                      title:
                                          const Text("Confirm Delete"),
                                      content: const Text(
                                          "Are you sure you want to delete this currency setting?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, false),
                                          child:
                                              const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                                color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final success =
                                        await GLApiService()
                                            .deleteAllowedCurrency(
                                      item["orgCode"],
                                      item["glNo"],
                                    );

                                    if (success) {
                                      showAmsSnack(
                                        context,
                                        "Deleted successfully",
                                        icon: "🗑️",
                                      );

                                      loadSavedCurrencies();
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
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
                  "Create Allowed Currencies",
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
              icon: _isEditMode ? Icons.edit_note_rounded : Icons.save_rounded,
              variant: AmsButtonVariant.primary,
              backgroundColor: AppColors.sidebar,
              onPressed: () async {
                if (_orgCodeCtrl.text.trim().isEmpty) {
                  setState(() {
                    _orgError = "Organization Code is required.";
                  });
                  return;
                }

                if (_selectedGlMaster == null) {
                  setState(() {
                    _glError = "Please select GL Account";
                  });
                  showAmsSnack(context, "Please select a GL Account.", type: 'e');
                  return;
                }

                final parsedGlNo = _selectedGlMaster!['glNo'] as int? ?? 0;

                final payload = {
                  "orgCode": int.parse(_orgCodeCtrl.text),
                  "glNo": parsedGlNo,
                  "allowedCurr": currencies.join(","),
                  "eUser": "SYSTEM"
                };

                setState(() {
                  _isLoading = true;
                });

                final success = _isEditMode
                    ? await GLApiService()
                        .updateAllowedCurrency({..._selectedRecord!, ...payload})
                    : await GLApiService().saveAllowedCurrency(payload);

                setState(() {
                  _isLoading = false;
                  if (success) {
                    showAmsSnack(
                      context,
                      _isEditMode ? "Updated successfully" : "Saved successfully",
                      icon: "✅",
                    );
                    showForm = false;
                    loadSavedCurrencies();
                    setState(() {});
                  } else {
                    showAmsSnack(context, "Save failed", icon: "⚠️");
                  }
                });
              },
            ),
            AmsButton(
              label: 'Clear',
              icon: Icons.clear_all_rounded,
              variant: AmsButtonVariant.outline,
              onPressed: () {
                setState(() {
                  currencies.clear();
                  _currencyCtrl.clear();
                  _orgError = null;
                  _glError = null;
                  _selectedGlMaster = null;
                });
              },
            ),
          ],
          AmsButton(
            label: _isViewOnly ? 'Back' : 'Cancel',
            icon: _isViewOnly ? Icons.arrow_back_rounded : Icons.close_rounded,
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
            controller: _orgCodeCtrl,
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
        const SizedBox(height: 16),

        /// Select GL
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
             border: Border.all(
                 color: _glError != null ? Colors.red : const Color(0xFFE2E8F0),
                 width: 1.5),
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
               onChanged: (_isViewOnly || _isEditMode) ? null : (v) {
                 setState(() {
                   _selectedGlMaster = v;
                   if (v != null) _glError = null;
                 });
               },
             ),
           ),
         ),
         if (_glError != null)
           Padding(
             padding: const EdgeInsets.only(top: 8),
             child: Text(
               _glError!,
               style: const TextStyle(color: Colors.red, fontSize: 12),
             ),
           ),
        const SizedBox(height: 20),
        Text(
          "Manage Currencies",
          style: bodyStyle(
            weight: FontWeight.w700,
            size: 14,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Allowed Currencies",
                  style:
                      bodyStyle(weight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: currencies.asMap().entries.map((entry) {
                    int index = entry.key;
                    String c = entry.value;
                    final baseColor = chipColors[index % chipColors.length];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [baseColor.withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: baseColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: baseColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.currency_exchange_rounded,
                                size: 10, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(c,
                              style: bodyStyle(
                                  weight: FontWeight.w800,
                                  color: AppColors.ink,
                                  size: 13)),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => removeCurrency(c),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.ink.withOpacity(0.4),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  "Add New Currency",
                  style:
                      bodyStyle(weight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AmsTextInput(
                        controller: _currencyCtrl,
                        placeholder: "e.g. JPY, CAD, AUD",
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: addCurrency,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sidebar,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text("Add",
                                style: bodyStyle(
                                    color: Colors.white,
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required Color bg,
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
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
