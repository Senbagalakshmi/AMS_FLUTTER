import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

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
  State<AllowedBranchScreen> createState() =>
      _AllowedBranchScreenState();
}

class _AllowedBranchScreenState
    extends State<AllowedBranchScreen> {

  bool showForm = false;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isViewOnly = false;

  /// GL Accounts
  List<String> glAccounts = [
    "GL 10020 — Bank Operating A/c",
    "GL 10021 — Cash Account",
    "GL 10022 — Salary Account",
    "GL 10023 — Vendor Account",
    "GL 10024 — Customer Account",
    "GL 10025 — Expense Account",
  ];

  /// Branch List
  List<Map<String, dynamic>> branches = [
    {"code": "HO", "name": "Head Office", "enabled": true},
    {"code": "BLR", "name": "Bangalore", "enabled": true},
    {"code": "MUM", "name": "Mumbai", "enabled": true},
    {"code": "CHN", "name": "Chennai", "enabled": false},
    {"code": "DEL", "name": "Delhi", "enabled": false},
  ];

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
            title: 'Allowed Branch',
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
              padding: const EdgeInsets.all(20),
              child: showForm
                  ? _buildFormView()
                  : _buildListView(),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                Expanded(
                  child: AmsTextInput(
                    icon: Icons.search_rounded,
                    placeholder: 'Search branches...',
                    onChanged: (v) {},
                  ),
                ),

                const SizedBox(width: 16),

                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {},
                ),

                const SizedBox(width: 16),

                AmsButton(
                  label: '+ Add New',
                  onPressed: () {
                    setState(() {
                      showForm = true;
                    });
                  },
                ),
              ],
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
            color: Colors.orange,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "GL104 — Allowed Branches",
                  style: bodyStyle(
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      showForm = false;
                    });
                  },
                )

              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildForm(),
            ),
          ),

        ],
      ),
    );
  }

  /// ================================
  /// FORM UI
  /// ================================
  Widget _buildForm() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        /// Select GL
        AmsField(
          label: "Select GL Account",
          labelAbove: true,
          child: AmsDropdown(
            items: glAccounts,
            onChanged: (v) {},
          ),
        ),

        const SizedBox(height: 20),

        /// Branch List
        ...branches.map((branch) {

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: branch["enabled"]
                  ? Colors.green.shade50
                  : Colors.grey.shade200,
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [

                SizedBox(
                  width: 60,
                  child: Text(
                    branch["code"],
                    style: bodyStyle(
                      weight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    branch["name"],
                    style: bodyStyle(),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      branch["enabled"] =
                          !branch["enabled"];
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8),
                    color: branch["enabled"]
                        ? Colors.green
                        : Colors.grey,
                    child: Text(
                      branch["enabled"]
                          ? "ON"
                          : "OFF",
                      style: const TextStyle(
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );

        }).toList(),

        const SizedBox(height: 20),

        /// Footer
        if (!_isViewOnly)
          AmsSubmitBar(
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
                AmsButton(
                  label: _isEditMode ? 'Update' : 'Save',
                  variant: AmsButtonVariant.primary,
                  backgroundColor: AppColors.sidebar,
                  onPressed: () {
                    setState(() {
                      showForm = false;
                    });
                  },
                ),

                AmsButton(
                  label: 'Clear',
                  icon: Icons.clear_all_rounded,
                  variant: AmsButtonVariant.outline,
                  onPressed: () {},
                ),

                AmsButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  variant: AmsButtonVariant.danger,
                  onPressed: () {
                    setState(() {
                      showForm = false;
                    });
                  },
                ),
              ],
            ],
          ),

      ],
    );
  }
}