import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class OrganisationScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const OrganisationScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<OrganisationScreen> createState() => _OrganisationScreenState();
}

class _OrganisationScreenState extends State<OrganisationScreen> {
  // --- STATIC DATA ---
  final List<Map<String, dynamic>> _organisations = [
    {
      'orgcode': 101,
      'name': 'Bbots Solutions Pvt Ltd',
      'opendate': '01-01-2024',
      'country': 'India',
      'state': 'Tamil Nadu',
      'district': 'Chennai',
      'pincode': '600001',
      'addrline1': '123 Fintech Street',
      'addrline2': 'Guindy',
      'addrline3': 'Chennai',
      'telephone': '🇮🇳 +91 44 2233 4455',
      'email': 'admin@bbots.ai',
      'status': 1,
    },
  ];

  static const Map<String, Map<String, String>> _countryInfo = {
    'India': {'flag': '🇮🇳', 'code': '+91'},
    'USA': {'flag': '🇺🇸', 'code': '+1'},
    'UK': {'flag': '🇬🇧', 'code': '+44'},
    'Singapore': {'flag': '🇸🇬', 'code': '+65'},
    'Germany': {'flag': '🇩🇪', 'code': '+49'},
    'Japan': {'flag': '🇯🇵', 'code': '+81'},
    'Canada': {'flag': '🇨🇦', 'code': '+1'},
    'Australia': {'flag': '🇦🇺', 'code': '+61'},
  };

  final Map<String, List<String>> _stateDistricts = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Trichy'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode'],
    'New York': ['Manhattan', 'Brooklyn', 'Queens'],
  };

  final Map<String, String> _pincodeMap = {
    'Chennai': '600001',
    'Coimbatore': '641001',
    'Madurai': '625001',
    'Salem': '636001',
    'Trichy': '620001',
    'Bangalore': '560001',
    'Mysore': '570001',
    'Hubli': '580001',
    'Mangalore': '575001',
    'Mumbai': '400001',
    'Pune': '411001',
    'Nagpur': '440001',
    'Nashik': '422001',
    'Kochi': '682001',
    'Thiruvananthapuram': '695001',
    'Kozhikode': '673001',
    'Manhattan': '10001',
    'Brooklyn': '11201',
    'Queens': '11101',
  };

  // --- UI STATE ---
  bool _showForm = false;
  bool _isViewOnly = false;
  bool _isEditMode = false;
  String _searchQuery = '';

  // Error States
  String? _orgCodeError;
  String? _orgNameError;
  String? _emailError;

  // Controllers
  final _orgCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _openDateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _addr3Ctrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _orgCodeCtrl.dispose();
    _nameCtrl.dispose();
    _openDateCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _addr3Ctrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _enterViewMode(Map<String, dynamic> record, {bool viewOnly = true}) {
    _orgCodeCtrl.text = record['orgcode'].toString();
    _nameCtrl.text = record['name'];
    _openDateCtrl.text = record['opendate'] ?? '';
    _countryCtrl.text = record['country'] ?? '';
    _stateCtrl.text = record['state'] ?? '';
    _districtCtrl.text = record['district'] ?? '';
    _pincodeCtrl.text = record['pincode'] ?? '';
    _addr1Ctrl.text = record['addrline1'] ?? '';
    _addr2Ctrl.text = record['addrline2'] ?? '';
    _addr3Ctrl.text = record['addrline3'] ?? '';
    _phoneCtrl.text = record['telephone'] ?? '';
    _emailCtrl.text = record['email'] ?? '';
    setState(() {
      _showForm = true;
      _isViewOnly = viewOnly;
      _isEditMode = !viewOnly;
      _clearErrors();
    });
  }

  void _clearFields() {
    _orgCodeCtrl.clear();
    _nameCtrl.clear();
    _openDateCtrl.clear();
    _countryCtrl.clear();
    _stateCtrl.clear();
    _districtCtrl.clear();
    _pincodeCtrl.clear();
    _addr1Ctrl.clear();
    _addr2Ctrl.clear();
    _addr3Ctrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    _clearErrors();
  }

  void _clearErrors() {
    setState(() {
      _orgCodeError = null;
      _orgNameError = null;
      _emailError = null;
    });
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showTopNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isError
                      ? AppColors.red.withValues(alpha: 0.2)
                      : AppColors.green.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isError ? AppColors.red : AppColors.green,
                    size: 20),
                const SizedBox(width: 12),
                Text(message,
                    style: bodyStyle(
                        size: 14,
                        color: isError ? AppColors.red : AppColors.green,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  Future<void> _selectDate() async {
    if (_isViewOnly) return;
    DateTime? pick = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.tBlue)),
          child: child!),
    );
    if (pick != null)
      setState(
          () => _openDateCtrl.text = DateFormat('dd-MM-yyyy').format(pick));
  }

  Future<void> _selectCountry() async {
    if (_isViewOnly) return;
    final countries = _countryInfo.keys.toList();
    final s = await showDialog<String>(
        context: context,
        builder: (ctx) =>
            _SearchPicker(title: 'Select Country', items: countries));
    if (s != null) {
      setState(() {
        final info = _countryInfo[s]!;
        _countryCtrl.text = "${info['flag']} $s";
        _phoneCtrl.text = "${info['flag']} ${info['code']} ";
        _stateCtrl.clear();
        _districtCtrl.clear();
        _pincodeCtrl.clear();
      });
    }
  }

  Future<void> _selectState() async {
    if (_isViewOnly) return;
    final s = await showDialog<String>(
        context: context,
        builder: (ctx) => _SearchPicker(
            title: 'Select State', items: _stateDistricts.keys.toList()));
    if (s != null) {
      setState(() {
        _stateCtrl.text = s;
        _districtCtrl.clear();
        _pincodeCtrl.clear();
      });
    }
  }

  Future<void> _selectDistrict() async {
    if (_isViewOnly) return;
    if (_stateCtrl.text.isEmpty) {
      _showTopNotification('Please select a State first', isError: true);
      return;
    }
    final s = await showDialog<String>(
        context: context,
        builder: (ctx) => _SearchPicker(
            title: 'Select District',
            items: _stateDistricts[_stateCtrl.text] ?? []));
    if (s != null) {
      setState(() {
        _districtCtrl.text = s;
        _pincodeCtrl.text = _pincodeMap[s] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildIdentityHeader(),
          Expanded(
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _showForm ? _buildEntryView() : _buildFullListView())),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader() {
    return AmsIdentityHeader(
      icon:
          const Icon(Icons.business_rounded, size: 28, color: AppColors.tBlue),
      title: 'Organisation',
      subtitle: '',
      badges: [],
      accentColor: AppColors.tBlue,
      accentLt: AppColors.tBlueLt,
      accentMd: AppColors.tBlueMd,
      breadcrumbs: [
        HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
        HeaderBreadcrumb(label: 'Masters', onTap: widget.onBackToModule),
        HeaderBreadcrumb(label: 'Organisation'),
      ],
      onBack: widget.onBackToModule,
    );
  }

  Widget _buildFullListView() {
    final filtered = _organisations.where((o) {
      final q = _searchQuery.toLowerCase();
      return o['name'].toString().toLowerCase().contains(q) ||
          o['orgcode'].toString().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                    child: AmsTextInput(
                        icon: Icons.search_rounded,
                        placeholder: 'Search...',
                        borderColor: AppColors.tBlue,
                        onChanged: (v) => setState(() => _searchQuery = v))),
                const SizedBox(width: 16),
                IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => setState(() {})),
                const SizedBox(width: 16),
                AmsButton(
                    label: '+ Add New',
                    variant: AmsButtonVariant.primary,
                    onPressed: () {
                      _clearFields();
                      setState(() {
                        _showForm = true;
                        _isViewOnly = false;
                      });
                    }),
              ],
            ),
          ),
          Expanded(child: _buildListTable(filtered)),
          _buildPaginationFooter(filtered.length),
        ],
      ),
    );
  }

  Widget _buildListTable(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final o = items[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: AppColors.tBlueLt,
                  child: Text(o['name'][0],
                      style: const TextStyle(
                          color: AppColors.tBlue,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(o['name'], style: bodyStyle(weight: FontWeight.bold)),
                    Text('${o['district']}, ${o['state']}, ${o['country']}',
                        style: bodyStyle(color: AppColors.ink3, size: 12)),
                  ])),
              SizedBox(
                  width: 60,
                  child:
                      Center(child: AmsBadge(label: o['orgcode'].toString()))),
              const SizedBox(width: 16),
              SizedBox(
                  width: 120,
                  child: Center(
                      child: AmsPill(
                          label: o['district'] ?? '',
                          color: AppColors.tBlue,
                          background:
                              AppColors.tBlueLt.withValues(alpha: 0.5)))),
              const SizedBox(width: 24),
              SizedBox(
                  width: 110,
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    _actionIcon(
                        icon: Icons.visibility_outlined,
                        color: AppColors.green,
                        bg: Colors.white,
                        onTap: () => _enterViewMode(o)),
                    const SizedBox(width: 8),
                    _actionIcon(
                        icon: Icons.edit_outlined,
                        color: AppColors.tBlue,
                        bg: Colors.white,
                        onTap: () => _enterViewMode(o, viewOnly: false)),
                    const SizedBox(width: 8),
                    _actionIcon(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.red,
                        bg: AppColors.redLt,
                        onTap: () {}),
                  ])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryView() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
                color: AppColors.sidebar,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
            child: Row(children: [
              Icon(_isViewOnly ? Icons.visibility : Icons.add_circle,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                  _isViewOnly
                      ? 'Organisation Details'
                      : (_isEditMode
                          ? 'Edit Organisation'
                          : 'Create Organisation'),
                  style:
                      bodyStyle(color: Colors.white, weight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white),
                  onPressed: () => setState(() => _showForm = false)),
            ]),
          ),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: AmsFormGrid(cols: 2, children: [
                    _field('Org Code*', _orgCodeCtrl,
                        isNum: true,
                        mandatory: true,
                        errorText: _orgCodeError,
                        onChanged: (v) => setState(() => _orgCodeError = null)),
                    _field('Organisation Name*', _nameCtrl,
                        mandatory: true,
                        errorText: _orgNameError,
                        onChanged: (v) => setState(() => _orgNameError = null)),
                    _buildPickerField('Open Date', _openDateCtrl, _selectDate,
                        Icons.calendar_today_rounded),
                    _buildPickerField('Country', _countryCtrl, _selectCountry,
                        Icons.public_rounded),
                    _buildPickerField('State Code', _stateCtrl, _selectState,
                        Icons.map_rounded),
                    _buildPickerField('District Code', _districtCtrl,
                        _selectDistrict, Icons.location_city_rounded),
                    _field('Pincode', _pincodeCtrl, enabled: false),
                    _field('Email Address', _emailCtrl,
                        errorText: _emailError,
                        onChanged: (v) => setState(() => _emailError = null)),
                    _field('Telephone', _phoneCtrl, icon: Icons.phone_rounded),
                    _field('Address Line 1', _addr1Ctrl),
                    _field('Address Line 2', _addr2Ctrl),
                    _field('Address Line 3', _addr3Ctrl),
                  ]))),
          _buildEntryFooter(),
        ],
      ),
    );
  }

  Widget _buildPickerField(String label, TextEditingController ctrl,
      VoidCallback onTap, IconData icon) {
    return AmsField(
        label: label,
        labelAbove: true,
        child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
                child: AmsTextInput(
                    controller: ctrl,
                    readOnly: _isViewOnly,
                    placeholder: 'Select $label',
                    borderColor: AppColors.tBlue,
                    icon: icon))));
  }

  Widget _buildEntryFooter() {
    return AmsSubmitBar(borderColor: AppColors.border, actions: [
      if (!_isViewOnly) ...[
        AmsButton(
          label: _isEditMode ? 'Update' : 'Submit',
          variant: AmsButtonVariant.primary,
          backgroundColor: AppColors.sidebar,
          onPressed: () {
            bool hasError = false;
            setState(() {
              if (_orgCodeCtrl.text.isEmpty) {
                _orgCodeError = 'Org Code is mandatory';
                hasError = true;
              }
              if (_nameCtrl.text.isEmpty) {
                _orgNameError = 'Organisation Name is mandatory';
                hasError = true;
              }
              if (!_isValidEmail(_emailCtrl.text)) {
                _emailError = 'Invalid email format';
                hasError = true;
              }
            });
            if (hasError) {
              _showTopNotification('Please correct the highlighted errors',
                  isError: true);
              return;
            }
            _showTopNotification('Organisation saved successfully');
            setState(() => _showForm = false);
          },
        ),
        const SizedBox(width: 12),
        AmsButton(
          label: 'Clear',
          variant: AmsButtonVariant.outline,
          icon: Icons.clear_all_rounded,
          onPressed: _clearFields,
        ),
        const SizedBox(width: 12),
        AmsButton(
          label: 'Cancel',
          variant: AmsButtonVariant.danger,
          icon: Icons.close_rounded,
          onPressed: () => setState(() => _showForm = false),
        ),
      ],
    ]);
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool isNum = false,
      bool mandatory = false,
      bool enabled = true,
      String? errorText,
      IconData? icon,
      void Function(String)? onChanged}) {
    return AmsField(
        label: label,
        labelAbove: true,
        required: mandatory,
        child: AmsTextInput(
            controller: ctrl,
            readOnly: _isViewOnly || !enabled,
            placeholder: enabled
                ? 'Enter ${label.replaceAll('*', '')}'
                : 'Auto-populated',
            borderColor: AppColors.tBlue,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            errorText: errorText,
            icon: icon,
            onChanged: onChanged));
  }

  Widget _actionIcon(
      {required IconData icon,
      required Color color,
      required Color bg,
      VoidCallback? onTap}) {
    return InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border)),
            child: Icon(icon, size: 16, color: color)));
  }

  Widget _buildPaginationFooter(int total) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Showing 1–$total of $total',
              style: bodyStyle(size: 13, color: AppColors.ink3)),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.chevron_left_rounded), onPressed: null),
            IconButton(
                icon: const Icon(Icons.chevron_right_rounded), onPressed: null)
          ]),
        ]));
  }
}

class _SearchPicker extends StatefulWidget {
  final String title;
  final List<String> items;
  const _SearchPicker({required this.title, required this.items});
  @override
  State<_SearchPicker> createState() => _SearchPickerState();
}

class _SearchPickerState extends State<_SearchPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(widget.title, style: bodyStyle(weight: FontWeight.bold)),
      content: SizedBox(
          width: 400,
          height: 500,
          child: Column(children: [
            AmsTextInput(
                placeholder: 'Search...',
                icon: Icons.search,
                borderColor: AppColors.tBlue,
                onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 16),
            Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No results',
                            style: bodyStyle(color: AppColors.ink4)))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) => ListTile(
                            title: Text(filtered[idx], style: bodyStyle()),
                            onTap: () =>
                                Navigator.pop(context, filtered[idx])))),
          ])),
      actions: [
        AmsButton(
            label: 'Close',
            variant: AmsButtonVariant.ghost,
            onPressed: () => Navigator.pop(context))
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class AmsPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const AmsPill(
      {super.key,
      required this.label,
      required this.color,
      required this.background});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: bodyStyle(size: 11, color: color, weight: FontWeight.w600)));
  }
}
