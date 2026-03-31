import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class GLAttributeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const GLAttributeScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<GLAttributeScreen> createState() => _GLAttributeScreenState();
}

class _GLAttributeScreenState extends State<GLAttributeScreen> {

  bool _showForm = false;
  final _glNoController = TextEditingController();
final _attrIdController = TextEditingController();
final _attrValueController = TextEditingController();
String? _glNoError;
String? _attrIdError;
String? _attrValueError;

  final List<String> glAccounts = [
    "GL 10020 — Bank Operating A/c",
  ];

  String selectedAccount = "GL 10020 — Bank Operating A/c";

  final List<Map<String, String>> attributes = [
  {"id": "RECON_FLAG", "value": "Y", "desc": "Reconciliation required"},
  {"id": "COST_CENTER", "value": "CC-FINANCE-001", "desc": "Default cost centre"},
  {"id": "IFRS_CLASS", "value": "FVTPL", "desc": "IFRS 9 classification"},
  {"id": "REPORT_GROUP", "value": "TREASURY", "desc": "Reporting group"},
  {"id": "TAX_CODE", "value": "GST-18", "desc": "Default tax code"},
  {"id": "CTRL_ACCOUNT", "value": "Y", "desc": "Control account flag"},
];

/// ✅ ADD HERE
void _deleteAttribute(int index) {
  setState(() {
    attributes.removeAt(index);
  });
}
void _editAttribute(int index) {
  setState(() {
    _showForm = true;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [

          /// HEADER
          AmsIdentityHeader(
            icon: const Icon(Icons.category_rounded,
                size: 28, color: AppColors.tBlue),
            title: 'GL Attribute',
            subtitle: '',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'GL Attribute'),
            ],
            onBack: widget.onBackToModule,
          ),

          /// BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _showForm ? _buildAddForm() : _buildListScreen(),
            ),
          ),
        ],
      ),
    );
  }

  /// =============================
  /// LIST SCREEN
  /// =============================

  Widget _buildListScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// SELECT GL
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                '* Select GL Account',
                style: bodyStyle(
                  weight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              AmsDropdown(
                items: glAccounts,
                initialValue: selectedAccount,
                onChanged: (v) {
                  setState(() {
                    selectedAccount = v!;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              "Custom Attributes",
              style: bodyStyle(
                size: 16,
                weight: FontWeight.w700,
              ),
            ),

            AmsButton(
              label: '+ Add Attribute',
              variant: AmsButtonVariant.primary,
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
            ),

          ],
        ),

        const SizedBox(height: 10),

        /// TABLE
       Expanded(
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    child: Column(
      children: [
 
        /// TABLE HEADER
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF2F5597),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Row(
            children: const [
 
              Expanded(
                flex: 2,
                child: Text(
                  "Attribute ID",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
 
              Expanded(
                flex: 2,
                child: Text(
                  "Value",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
 
              Expanded(
                flex: 3,
                child: Text(
                  "Description",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
 
              Expanded(
                flex: 1,
                child: Text(
                  "Actions",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
 
        /// TABLE DATA
        Expanded(
          child: ListView.builder(
            itemCount: attributes.length,
            itemBuilder: (context, index) {
 
              final item = attributes[index];
 
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
 
                    /// Attribute ID
                    Expanded(
                      flex: 2,
                      child: Text(
                        item["id"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
 
                    /// Value
                    Expanded(
                      flex: 2,
                      child: Text(item["value"]!),
                    ),
 
                    /// Description
                    Expanded(
                      flex: 3,
                      child: Text(item["desc"]!),
                    ),
 
                    /// Actions
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
 
                          /// Edit
                          InkWell(
                            onTap: () {
                              _editAttribute(index);
                            },
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
 
                          const SizedBox(width: 12),
 
                          /// Delete
                          InkWell(
                            onTap: () {
                              _deleteAttribute(index);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black54,
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
)
      ],
    );
  }

  /// =============================
  /// ADD FORM
  /// =============================

  Widget _buildAddForm() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
 
        /// HEADER
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.sidebar,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
 
              Text(
                "Add GL Attribute",
                style: bodyStyle(
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
 
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showForm = false;
                  });
                },
              ),
 
            ],
          ),
        ),
 
        /// BODY
      Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
 
                  AmsFormGrid(

  children: [
 
    AmsField(

      label: "GL No",

      required: true,

      labelAbove: true,

      child: AmsTextInput(

        controller: _glNoController,

        errorText: _glNoError,

        placeholder: "10020",

      ),

    ),
 
    AmsField(

      label: "Attribute ID",

      required: true,

      labelAbove: true,

      child: AmsTextInput(

        controller: _attrIdController,

        errorText: _attrIdError,

      ),

    ),
 
    AmsField(

      label: "Attribute Value",

      required: true,

      labelAbove: true,

      child: AmsTextInput(

        controller: _attrValueController,

        errorText: _attrValueError,

      ),

    ),
 
  ],

),
 
 
                ],
              ),
            ),
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
 
      AmsButton(
        label: 'Save',
        variant: AmsButtonVariant.primary,
        backgroundColor: AppColors.sidebar,

        onPressed: () {
          _validateForm();

          // showAmsToast(

          //   context,

          //   '✅',

          //   'Attribute saved successfully.',

          // );
 
          // setState(() {

          //   _showForm = false;

          // });

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

            _showForm = false;

          });

        },

      ),
 
    ],

  );

}

void _validateForm() {
  setState(() {
    _glNoError =
        _glNoController.text.isEmpty ? "GL No is required" : null;
 
    _attrIdError =
        _attrIdController.text.isEmpty ? "Attribute ID is required" : null;
 
    _attrValueError =
        _attrValueController.text.isEmpty ? "Attribute Value is required" : null;
  });
 
  if (_glNoError == null &&
      _attrIdError == null &&
      _attrValueError == null) {
    _saveAttribute();
  }
}

void _saveAttribute() {
  setState(() {
    attributes.add({
      "id": _attrIdController.text,
      "value": _attrValueController.text,
      "desc": "",
    });
 
    _showForm = false;
  });
 
  _glNoController.clear();
  _attrIdController.clear();
  _attrValueController.clear();
}
}