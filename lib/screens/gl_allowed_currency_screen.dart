import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

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

  /// GL Accounts List
  List<String> glAccounts = [
    "GL 10020 — Bank Operating A/c",
    "GL 10021 — Cash Account",
    "GL 10022 — Salary Account",
    "GL 10023 — Vendor Account",
    "GL 10024 — Customer Account",
    "GL 10025 — Expense Account",
  ];

  final TextEditingController _currencyCtrl = TextEditingController();

  List<String> currencies = ["INR", "USD", "GBP", "EUR", "SGD"];

  final List<Color> chipColors = [
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.teal.shade100,
  ];

  void addCurrency() {
    if (_currencyCtrl.text.isNotEmpty) {
      setState(() {
        currencies.add(_currencyCtrl.text.toUpperCase());
        _currencyCtrl.clear();
      });
    }
  }

  void removeCurrency(String currency) {
    setState(() {
      currencies.remove(currency);
    });
  }

  @override
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
                    placeholder: 'Search currencies...',
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
                  variant: AmsButtonVariant.primary,
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

            showAmsToast(
             context,
             '✅',
             'Allowed currencies updated successfully.',
            );
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
                currencies.clear();
                _currencyCtrl.clear();
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
                  style: bodyStyle(weight: FontWeight.w600, color: AppColors.ink),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            child: const Icon(Icons.currency_exchange_rounded, size: 10, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(c, style: bodyStyle(weight: FontWeight.w800, color: AppColors.ink, size: 13)),
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
                  style: bodyStyle(weight: FontWeight.w600, color: AppColors.ink),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sidebar,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text("Add", style: bodyStyle(color: Colors.white, weight: FontWeight.w600)),
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
}
