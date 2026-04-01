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
  State<AllowedBranchScreen> createState() => _AllowedBranchScreenState();
}

class _AllowedBranchScreenState extends State<AllowedBranchScreen> {
  bool showForm = false;
  final bool _isLoading = false;
  final bool _isEditMode = false;
  final bool _isViewOnly = false;

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
          if (!_isViewOnly) _buildFixedFooter(),
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
          AmsButton(
            label: _isEditMode ? 'Update' : 'Save',
            variant: AmsButtonVariant.primary,
            backgroundColor: AppColors.sidebar,
            onPressed: () {
              showAmsSnack(context, 'Allowed branches updated successfully.',
                  icon: '✅');
              setState(() {
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
                for (var b in branches) {
                  b["enabled"] = false;
                }
              });
            },
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
    );
  }

  Widget _buildFormContentOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
