import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

// class AllowedCurrencyScreen extends StatefulWidget {
//   final void Function(String key, dynamic val) onChanged;
//   final Map<String, dynamic>? initialData;
//   final bool isViewMode;

//   const AllowedCurrencyScreen({
//     super.key,
//     required this.onChanged,
//     this.initialData,
//     this.isViewMode = false,
//   });

//   @override
//   State<AllowedCurrencyScreen> createState() =>
//       _AllowedCurrencyScreenState();
// }
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
  State<AllowedCurrencyScreen> createState() =>
      _AllowedCurrencyScreenState();
}

class _AllowedCurrencyScreenState
    extends State<AllowedCurrencyScreen> {

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

  final TextEditingController _currencyCtrl =
      TextEditingController();

  List<String> currencies = [
    "INR",
    "USD",
    "GBP",
    "EUR",
    "SGD"
  ];

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

          /// Header
 /// Header
AmsIdentityHeader(
  icon: const Icon(
    Icons.currency_exchange_rounded,
    size: 28,
    color: AppColors.tBlue,
  ),
  title: 'Allowed Currency',
  subtitle: '',
  badges: [],
  accentColor: AppColors.tBlue,
  accentLt: AppColors.tBlueLt,
  accentMd: AppColors.tBlueMd,
  breadcrumbs: [
    HeaderBreadcrumb(
      label: 'Home',
      onTap: () {},
    ),
    HeaderBreadcrumb(
      label: 'GL Module',
      onTap: () {},
    ),
    HeaderBreadcrumb(
      label: 'Allowed Currency',
    ),
  ],
  onBack: () {
    Navigator.pop(context);
  },
),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: showForm
                  ? _buildFullFormView()
                  : _buildFullListView(),
            ),
          ),

        ],
      ),
    );
  }

  /// List View
Widget _buildFullListView() {
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

              /// Search
              Expanded(
                child: AmsTextInput(
                  icon: Icons.search_rounded,
                  placeholder: 'Search branches...',
                  onChanged: (v) {},
                ),
              ),

              const SizedBox(width: 16),

              /// Refresh
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                onPressed: () {},
              ),

              const SizedBox(width: 16),

              /// Add New
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
  /// Form View
  Widget _buildFullFormView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [

          /// Form Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.purple,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "GL103 — Allowed Currencies",
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
          )

        ],
      ),
    );
  }

  /// Form UI
  Widget _buildForm() {
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
          "Allowed Currencies",
          style: bodyStyle(
            weight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        /// Chips
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              currencies.asMap().entries.map((entry) {

            int index = entry.key;
            String c = entry.value;

            return Container(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10),
              decoration: BoxDecoration(
                color: chipColors[
                    index %
                        chipColors.length],
                border: Border.all(
                  color: chipColors[
                      index %
                          chipColors.length],
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(c),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        removeCurrency(c),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        /// Add Currency
        Row(
          children: [
            Expanded(
              child: AmsTextInput(
                controller: _currencyCtrl,
                placeholder:
                    "Add currency code (e.g. JPY)",
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: addCurrency,
              child: Container(
                padding:
                    const EdgeInsets.all(12),
                color: Colors.deepPurple,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),

        const SizedBox(height: 20),

        /// Buttons
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