import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/org_api_service.dart';
import '../services/location_api_service.dart'; // ← NEW
import '../utils/responsive.dart';

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
  // --- UI STATE ---
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showForm = false;
  bool _isViewOnly = false;
  bool _isEditMode = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _organisations = [];
  int _totalRecords = 0;
  int _currentPage = 1;

  // Error States
  String? _orgCodeError;
  String? _orgNameError;
  String? _emailError;

  // Controllers (kept in sync from OrganisationFields via onChanged)
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

  // IDs synced from OrganisationFields for payload building
  int _selectedCountryId = 0;
  int _selectedStateId = 0;
  int _selectedDistrictId = 0;
  String _selectedCountryIso = '';

  final GlobalKey<OrganisationFieldsState> _fieldsKey =
      GlobalKey<OrganisationFieldsState>();

  @override
  void initState() {
    super.initState();
    _fetchOrganisations(1);
  }

  Future<void> _fetchOrganisations(int page) async {
    setState(() {
      _isLoading = true;
      _currentPage = page;
    });
    final res = await orgApiService.getAllOrganisations(page: page - 1);
    if (res != null) {
      setState(() {
        _organisations = res.items;
        _totalRecords = res.totalElements;
      });
    }
    setState(() => _isLoading = false);
  }

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

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return true;
    return RegExp(r"^[+0-9\s-]{7,15}$")
        .hasMatch(phone.replaceAll(RegExp(r'\s+'), ''));
  }

  void _clearErrors() {
    setState(() {
      _orgCodeError = null;
      _orgNameError = null;
      _emailError = null;
    });
  }

  Future<void> _save() async {
    bool hasError = false;
    setState(() {
      if (_orgCodeCtrl.text.isEmpty) {
        _orgCodeError = 'Organisation Code is mandatory';
        hasError = true;
      }
      if (_nameCtrl.text.isEmpty) {
        _orgNameError = 'Organisation Name is mandatory';
        hasError = true;
      }
      if (_emailCtrl.text.isNotEmpty && !_isValidEmail(_emailCtrl.text)) {
        _emailError = 'Invalid email format';
        hasError = true;
      }
      if (_phoneCtrl.text.isNotEmpty && !_isValidPhone(_phoneCtrl.text)) {
        hasError = true;
      }
    });

    if (hasError) {
      _showTopNotification('Please correct the highlighted errors',
          isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      String openDateStr = _openDateCtrl.text;
      DateTime openDate = DateFormat('dd-MM-yyyy').parse(openDateStr);
      String isoOpenDate =
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(openDate.toUtc())}+00:00";

      // Use the ISO code synced from OrganisationFields
      String countryCode = _selectedCountryIso.isNotEmpty
          ? _selectedCountryIso
          : _countryCtrl.text;

      String nowIso =
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(DateTime.now().toUtc())}+00:00";

      String cleanUser = (widget.userName ?? "admin");
      if (cleanUser.contains('@')) cleanUser = cleanUser.split('@').first;

      Map<String, dynamic> originalRecord = {};
      if (_isEditMode) {
        try {
          originalRecord = _organisations.firstWhere(
            (o) =>
                (o['orgcode'] ?? o['orgCode'])?.toString() == _orgCodeCtrl.text,
            orElse: () => <String, dynamic>{},
          );
        } catch (_) {}
      }

      String cUserVal = _isEditMode
          ? (originalRecord['cUser'] ?? originalRecord['cuser'] ?? cleanUser)
              .toString()
          : cleanUser;
      String cDateVal = _isEditMode
          ? (originalRecord['cDate'] ?? originalRecord['cdate'] ?? nowIso)
              .toString()
          : nowIso;
      String eUserVal = cleanUser;
      String eDateVal = nowIso;
      String aUserVal = _isEditMode
          ? (originalRecord['aUser'] ?? originalRecord['auser'] ?? eUserVal)
              .toString()
          : eUserVal;
      String aDateVal = _isEditMode
          ? (originalRecord['aDate'] ?? originalRecord['adate'] ?? eDateVal)
              .toString()
          : eDateVal;

      final payload = {
        "orgcode": int.tryParse(_orgCodeCtrl.text) ?? 0,
        "name": _nameCtrl.text,
        "openDate": isoOpenDate,
        "country": countryCode,
        "divisionName": "${_stateCtrl.text} - ${_districtCtrl.text}",
        "pincode": _pincodeCtrl.text,
        "addrline1": _addr1Ctrl.text,
        "addrline2": _addr2Ctrl.text,
        "addrline3": _addr3Ctrl.text,
        "telephone": _phoneCtrl.text.trim(),
        "email": _emailCtrl.text,
        "status": 1,
        "indiv": 10,
        "logo": "/ftp/logos/org_header.png",
        "cUser": cUserVal,
        "cuser": cUserVal,
        "cDate": cDateVal,
        "cdate": cDateVal,
        "eUser": eUserVal,
        "euser": eUserVal,
        "eDate": eDateVal,
        "edate": eDateVal,
        "aUser": aUserVal,
        "auser": aUserVal,
        "aDate": aDateVal,
        "adate": aDateVal,
      };

      final success = _isEditMode
          ? await orgApiService.updateOrganisation(payload)
          : await orgApiService.createOrganisation(payload);

      if (success) {
        _showTopNotification('Organisation saved successfully');
        setState(() {
          _showForm = false;
          _isSaving = false;
        });
        _fetchOrganisations(1);
      } else {
        _showTopNotification('Failed to save organisation.', isError: true);
        setState(() => _isSaving = false);
      }
    } catch (e) {
      _showTopNotification('Error: $e', isError: true);
      setState(() => _isSaving = false);
    }
  }

  void _enterViewMode(Map<String, dynamic> record, {bool viewOnly = true}) {
    _orgCodeCtrl.text =
        (record['orgcode'] ?? record['orgCode'] ?? '').toString();
    _nameCtrl.text = record['name'] ?? '';

    String rawDate =
        (record['openDate'] ?? record['opendate'] ?? '').toString();
    if (rawDate.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(rawDate.split('T')[0]);
        _openDateCtrl.text = DateFormat('dd-MM-yyyy').format(dt);
      } catch (e) {
        _openDateCtrl.text = rawDate;
      }
    } else {
      _openDateCtrl.text = '';
    }

    _countryCtrl.text = record['country'] ?? '';

    String div = record['divisionName'] ?? record['state'] ?? '';
    if (div.contains(' - ')) {
      var parts = div.split(' - ');
      _stateCtrl.text = parts[0];
      _districtCtrl.text = parts[1];
    } else {
      _stateCtrl.text = div;
      _districtCtrl.text = record['district'] ?? '';
    }
    _pincodeCtrl.text = (record['pincode'] ?? '').toString();
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

  Future<void> _confirmDelete(int orgCode, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Organisation',
            style: bodyStyle(weight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          AmsButton(
              label: 'Cancel',
              variant: AmsButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx, false)),
          AmsButton(
              label: 'Delete',
              variant: AmsButtonVariant.danger,
              onPressed: () => Navigator.pop(ctx, true)),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      final success = await orgApiService.deleteOrganisation(orgCode);
      if (success) {
        _showTopNotification('Organisation deleted successfully');
        _fetchOrganisations(1);
      } else {
        _showTopNotification('Failed to delete organisation', isError: true);
      }
      setState(() => _isLoading = false);
    }
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
    _selectedCountryId = 0;
    _selectedStateId = 0;
    _selectedDistrictId = 0;
    _selectedCountryIso = '';
    _fieldsKey.currentState?.clear();
    _clearErrors();
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
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(builder: (context, constraints) {
              final isMobile = Responsive.isMobile(context);
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AmsTextInput(
                        icon: Icons.search_rounded,
                        placeholder: 'Search...',
                        borderColor: AppColors.tBlue,
                        onChanged: (v) => setState(() => _searchQuery = v)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: () => _fetchOrganisations(1)),
                        const Spacer(),
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
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                      child: AmsTextInput(
                          icon: Icons.search_rounded,
                          placeholder: 'Search...',
                          borderColor: AppColors.tBlue,
                          onChanged: (v) => setState(() => _searchQuery = v))),
                  IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => _fetchOrganisations(1)),
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
              );
            }),
          ),
          _isLoading
              ? const Expanded(child: AmsListSkeleton())
              : _buildListTable(),
        ],
      ),
    );
  }

  Widget _buildListTable() {
    return Expanded(
      child: AmsPaginatedView<Map<String, dynamic>>(
        items: _organisations,
        totalRecords: _totalRecords,
        currentPage: _currentPage,
        onPageChanged: (page) => _fetchOrganisations(page),
        builder: (context, items) {
          final q = _searchQuery.toLowerCase();
          final filtered = items.where((o) {
            if (q.isEmpty) return true;
            final name = (o['name'] ?? '').toString().toLowerCase();
            final code = (o['orgcode'] ?? '').toString().toLowerCase();
            return name.contains(q) || code.contains(q);
          }).toList();

          if (filtered.isEmpty && q.isNotEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No matches found for your search'),
            ));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final o = filtered[idx];
              final isMobile = Responsive.isMobile(context);

              if (isMobile) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                              backgroundColor: AppColors.tBlueLt,
                              radius: 18,
                              child: Text((o['name'] ?? 'U')[0],
                                  style: const TextStyle(
                                      color: AppColors.tBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(o['name'] ?? 'Unknown',
                                    style: bodyStyle(
                                        weight: FontWeight.bold, size: 14)),
                                Text(
                                    '${o['district'] ?? o['divisionName'] ?? ''}, ${o['country'] ?? ''}',
                                    style: bodyStyle(
                                        color: AppColors.ink3, size: 11)),
                              ])),
                          AmsBadge(label: o['orgcode']?.toString() ?? ''),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              o['email'] ?? '',
                              style: bodyStyle(
                                  color: AppColors.tBlue,
                                  size: 12,
                                  weight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _actionIcon(
                                  icon: Icons.history_rounded,
                                  color: AppColors.ink3,
                                  bg: Colors.white,
                                  onTap: () => showAuditLogPopup(context, o)),
                              const SizedBox(width: 8),
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
                                  onTap: () =>
                                      _enterViewMode(o, viewOnly: false)),
                              const SizedBox(width: 8),
                              _actionIcon(
                                  icon: Icons.delete_outline_rounded,
                                  color: AppColors.red,
                                  bg: AppColors.redLt,
                                  onTap: () => _confirmDelete(o['orgcode'] ?? 0,
                                      o['name'] ?? 'Organisation')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

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
                        child: Text((o['name'] ?? 'U')[0],
                            style: const TextStyle(
                                color: AppColors.tBlue,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(o['name'] ?? 'Unknown',
                              style: bodyStyle(weight: FontWeight.bold)),
                          Text(
                              '${o['district'] ?? o['divisionName'] ?? ''}, ${o['country'] ?? ''}',
                              style:
                                  bodyStyle(color: AppColors.ink3, size: 12)),
                        ])),
                    SizedBox(
                        width: 60,
                        child: Center(
                            child: AmsBadge(label: o['orgcode'].toString()))),
                    const SizedBox(width: 16),
                    SizedBox(
                        width: 120,
                        child: Center(
                            child: AmsPill(
                                label: o['email'] ?? '',
                                color: AppColors.tBlue,
                                background:
                                    AppColors.tBlueLt.withValues(alpha: 0.5)))),
                    const SizedBox(width: 24),
                    SizedBox(
                        width: 150,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _actionIcon(
                                  icon: Icons.history_rounded,
                                  color: AppColors.ink3,
                                  bg: Colors.white,
                                  onTap: () => showAuditLogPopup(context, o)),
                              const SizedBox(width: 8),
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
                                  onTap: () =>
                                      _enterViewMode(o, viewOnly: false)),
                              const SizedBox(width: 8),
                              _actionIcon(
                                  icon: Icons.delete_outline_rounded,
                                  color: AppColors.red,
                                  bg: AppColors.redLt,
                                  onTap: () => _confirmDelete(o['orgcode'] ?? 0,
                                      o['name'] ?? 'Organisation')),
                            ])),
                  ],
                ),
              );
            },
          );
        },
      ),
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
                  padding: const EdgeInsets.all(0),
                  child: OrganisationFields(
                    key: _fieldsKey,
                    isViewMode: _isViewOnly,
                    initialData: _isEditMode || _isViewOnly
                        ? _organisations.firstWhere(
                            (o) =>
                                (o['orgcode'] ?? o['orgCode'])?.toString() ==
                                _orgCodeCtrl.text,
                            orElse: () => {})
                        : null,
                    onChanged: (k, v) {
                      // Sync text fields
                      if (k == 'orgCode') _orgCodeCtrl.text = v.toString();
                      if (k == 'name') _nameCtrl.text = v.toString();
                      if (k == 'email') _emailCtrl.text = v.toString();
                      if (k == 'openDate') _openDateCtrl.text = v.toString();
                      if (k == 'country') _countryCtrl.text = v.toString();
                      if (k == 'state') _stateCtrl.text = v.toString();
                      if (k == 'district') _districtCtrl.text = v.toString();
                      if (k == 'pincode') _pincodeCtrl.text = v.toString();
                      if (k == 'addrline1') _addr1Ctrl.text = v.toString();
                      if (k == 'addrline2') _addr2Ctrl.text = v.toString();
                      if (k == 'addrline3') _addr3Ctrl.text = v.toString();
                      if (k == 'telephone') _phoneCtrl.text = v.toString();
                      // Sync IDs for payload building
                      if (k == 'countryId') _selectedCountryId = v as int;
                      if (k == 'stateId') _selectedStateId = v as int;
                      if (k == 'districtId') _selectedDistrictId = v as int;
                      if (k == 'countryIso') _selectedCountryIso = v.toString();
                    },
                  ))),
          _buildEntryFooter(),
        ],
      ),
    );
  }

  Widget _buildEntryFooter() {
    return AmsSubmitBar(borderColor: AppColors.border, actions: [
      if (!_isViewOnly) ...[
        AmsButton(
          label: _isEditMode ? 'Update' : 'Submit',
          variant: AmsButtonVariant.primary,
          backgroundColor: AppColors.sidebar,
          onPressed: () {
            if (_fieldsKey.currentState?.validate() == false) return;
            _save();
          },
          loading: _isSaving,
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
      ] else ...[
        AmsButton(
          label: 'Back to List',
          variant: AmsButtonVariant.outline,
          icon: Icons.arrow_back_rounded,
          onPressed: () => setState(() => _showForm = false),
        ),
      ]
    ]);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// OrganisationFields — Backend Location API integrated
// ─────────────────────────────────────────────────────────────────────────────

class OrganisationFields extends StatefulWidget {
  final bool isViewMode;
  final Map<String, dynamic>? initialData;
  final void Function(String, dynamic) onChanged;

  const OrganisationFields({
    super.key,
    required this.isViewMode,
    this.initialData,
    required this.onChanged,
  });

  @override
  State<OrganisationFields> createState() => OrganisationFieldsState();
}

class OrganisationFieldsState extends State<OrganisationFields> {
  // ── Form controllers ───────────────────────────────────────────────────────
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

  // ── Overlay search controllers ─────────────────────────────────────────────
  final _countrySearchCtrl = TextEditingController();
  final _stateSearchCtrl = TextEditingController();
  final _districtSearchCtrl = TextEditingController();
  final _pincodeSearchCtrl = TextEditingController();

  // ── LayerLinks for overlay anchoring ──────────────────────────────────────
  final _countryLayerLink = LayerLink();
  final _stateLayerLink = LayerLink();
  final _districtLayerLink = LayerLink();
  final _pincodeLayerLink = LayerLink();

  // ── Overlay entries ────────────────────────────────────────────────────────
  OverlayEntry? _countryOverlay;
  OverlayEntry? _stateOverlay;
  OverlayEntry? _districtOverlay;
  OverlayEntry? _pincodeOverlay;

  // ── Selected model objects (hold IDs for chained API calls) ───────────────
  LocationCountry? _selectedCountry;
  LocationState? _selectedState;
  LocationDistrict? _selectedDistrict;

  // ── Data lists fetched from backend ───────────────────────────────────────
  List<LocationCountry> _countries = [];
  List<LocationState> _states = [];
  List<LocationDistrict> _districts = [];
  List<LocationPincode> _pincodes = [];

  // ── Loading flags ──────────────────────────────────────────────────────────
  bool _countriesLoading = false;
  bool _statesLoading = false;
  bool _districtsLoading = false;
  bool _pincodesLoading = false;

  // ── Validation error texts ─────────────────────────────────────────────────
  String? _orgCodeError;
  String? _orgNameError;
  String? _emailError;
  String? _phoneError;
  String? _openDateError;
  String? _countryError;
  String? _stateError;
  String? _districtError;
  String? _addr1Error;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCountries(); // Pre-fetch countries on widget init
    _loadInitialData();
  }

  @override
  void didUpdateWidget(OrganisationFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _removeAllOverlays();
    for (final c in [
      _orgCodeCtrl,
      _nameCtrl,
      _openDateCtrl,
      _countryCtrl,
      _stateCtrl,
      _districtCtrl,
      _pincodeCtrl,
      _addr1Ctrl,
      _addr2Ctrl,
      _addr3Ctrl,
      _phoneCtrl,
      _emailCtrl,
      _countrySearchCtrl,
      _stateSearchCtrl,
      _districtSearchCtrl,
      _pincodeSearchCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initial data (view / edit mode)
  // ─────────────────────────────────────────────────────────────────────────

  void _loadInitialData() {
    if (widget.initialData == null) return;
    final d = widget.initialData!.map((k, v) => MapEntry(k.toLowerCase(), v));

    _orgCodeCtrl.text = (d['orgcode'] ?? '').toString();
    _nameCtrl.text = (d['name'] ?? d['orgname'] ?? '').toString();

    final rawDate = (d['opendate'] ?? '').toString();
    if (rawDate.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(rawDate.split('T')[0]);
        _openDateCtrl.text = DateFormat('dd-MM-yyyy').format(dt);
      } catch (_) {
        _openDateCtrl.text = rawDate;
      }
    }

    // Country — stored as ISO code in DB (e.g. "IN")
    // We display the countryname once the list loads; for now show the code.
    final countryCode = (d['country'] ?? '').toString();
    _countryCtrl.text = countryCode;

    // State + District from divisionName "Tamil Nadu - Chennai"
    final div = (d['divisionname'] ?? d['state'] ?? '').toString();
    if (div.contains(' - ')) {
      final parts = div.split(' - ');
      _stateCtrl.text = parts[0];
      _districtCtrl.text = parts[1];
    } else {
      _stateCtrl.text = div;
      _districtCtrl.text = (d['district'] ?? '').toString();
    }

    _pincodeCtrl.text = (d['pincode'] ?? '').toString();
    _addr1Ctrl.text = (d['addrline1'] ?? '').toString();
    _addr2Ctrl.text = (d['addrline2'] ?? '').toString();
    _addr3Ctrl.text = (d['addrline3'] ?? '').toString();
    _phoneCtrl.text = (d['telephone'] ?? '').toString();
    _emailCtrl.text = (d['email'] ?? '').toString();

    // Once countries are loaded, resolve the ISO code → full country name
    _resolveCountryFromIso(countryCode);
  }

  /// After countries list is available, find the matching entry by ISO code
  /// and update the display text + selected object.
  void _resolveCountryFromIso(String isoCode) {
    if (isoCode.isEmpty) return;
    // Try immediately if list is already loaded
    if (_countries.isNotEmpty) {
      _applyCountryFromIso(isoCode);
    }
    // Also hook into countries load completion (handled in _loadCountries)
  }

  void _applyCountryFromIso(String isoCode) {
    try {
      final match = _countries.firstWhere(
        (c) => c.countrycode.toUpperCase() == isoCode.toUpperCase(),
      );
      if (mounted) {
        setState(() {
          _selectedCountry = match;
          _countryCtrl.text = match.countryname;
        });
      }
    } catch (_) {
      // No match — keep ISO code as display text
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Backend API loaders
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadCountries() async {
    if (_countriesLoading) return;
    setState(() => _countriesLoading = true);
    try {
      final list = await locationApiService.getCountries();
      if (mounted) {
        setState(() => _countries = list);
        // If initial data set an ISO code, resolve it now
        if (_countryCtrl.text.isNotEmpty && _selectedCountry == null) {
          _applyCountryFromIso(_countryCtrl.text);
        }
      }
    } finally {
      if (mounted) setState(() => _countriesLoading = false);
    }
  }

  Future<void> _loadStates(int countryId) async {
    setState(() {
      _statesLoading = true;
      _states = [];
      _districts = [];
      _pincodes = [];
    });
    try {
      final list = await locationApiService.getStates(countryId);
      if (mounted) setState(() => _states = list);
    } finally {
      if (mounted) setState(() => _statesLoading = false);
    }
  }

  Future<void> _loadDistricts(int countryId, int stateId) async {
    setState(() {
      _districtsLoading = true;
      _districts = [];
      _pincodes = [];
    });
    try {
      final list = await locationApiService.getDistricts(countryId, stateId);
      if (mounted) setState(() => _districts = list);
    } finally {
      if (mounted) setState(() => _districtsLoading = false);
    }
  }

  Future<void> _loadPincodes(int countryId, int stateId, int cityId) async {
    setState(() {
      _pincodesLoading = true;
      _pincodes = [];
    });
    try {
      final list =
          await locationApiService.getPincodes(countryId, stateId, cityId);
      if (mounted) setState(() => _pincodes = list);
    } finally {
      if (mounted) setState(() => _pincodesLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Overlay helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _removeAllOverlays() {
    _countryOverlay?.remove();
    _countryOverlay = null;
    _stateOverlay?.remove();
    _stateOverlay = null;
    _districtOverlay?.remove();
    _districtOverlay = null;
    _pincodeOverlay?.remove();
    _pincodeOverlay = null;
  }

  OverlayEntry _buildDropdownOverlay<T>({
    required LayerLink link,
    required List<T> items,
    required bool isLoading,
    required TextEditingController searchCtrl,
    required String Function(T) labelOf,
    required void Function(T) onSelect,
    required VoidCallback onClose,
  }) {
    return OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onClose,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: AmsTextInput(
                          controller: searchCtrl,
                          placeholder: 'Search...',
                          icon: Icons.search,
                          onChanged: (_) => (ctx as Element).markNeedsBuild(),
                        ),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Flexible(
                          child: Builder(builder: (_) {
                            final q = searchCtrl.text.toLowerCase();
                            final filtered = items
                                .where(
                                    (i) => labelOf(i).toLowerCase().contains(q))
                                .toList();
                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No results found'),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => ListTile(
                                title: Text(labelOf(filtered[i]),
                                    style: bodyStyle(size: 13)),
                                dense: true,
                                onTap: () => onSelect(filtered[i]),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dropdown openers
  // ─────────────────────────────────────────────────────────────────────────

  void _openCountryDropdown() {
    if (widget.isViewMode) return;
    _removeAllOverlays();
    _countrySearchCtrl.clear();

    // Trigger load if list is empty
    if (_countries.isEmpty) _loadCountries();

    _countryOverlay = _buildDropdownOverlay<LocationCountry>(
      link: _countryLayerLink,
      items: _countries,
      isLoading: _countriesLoading,
      searchCtrl: _countrySearchCtrl,
      labelOf: (c) => c.displayName,
      onSelect: (c) {
        setState(() {
          _selectedCountry = c;
          _countryCtrl.text = c.countryname;
          // Reset dependent fields
          _selectedState = null;
          _stateCtrl.clear();
          _selectedDistrict = null;
          _districtCtrl.clear();
          _pincodeCtrl.clear();
          _states = [];
          _districts = [];
          _pincodes = [];
          _countryError = null;
        });
        widget.onChanged('country', c.countrycode); // ISO code for payload
        widget.onChanged('countryId', c.countryid);
        widget.onChanged('countryIso', c.countrycode);
        _loadStates(c.countryid);
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_countryOverlay!);
  }

  void _openStateDropdown() {
    if (widget.isViewMode || _selectedCountry == null) return;
    _removeAllOverlays();
    _stateSearchCtrl.clear();

    _stateOverlay = _buildDropdownOverlay<LocationState>(
      link: _stateLayerLink,
      items: _states,
      isLoading: _statesLoading,
      searchCtrl: _stateSearchCtrl,
      labelOf: (s) => s.displayName,
      onSelect: (s) {
        setState(() {
          _selectedState = s;
          _stateCtrl.text = s.statename;
          // Reset dependent fields
          _selectedDistrict = null;
          _districtCtrl.clear();
          _pincodeCtrl.clear();
          _districts = [];
          _pincodes = [];
          _stateError = null;
        });
        widget.onChanged('state', s.statename);
        widget.onChanged('stateId', s.stateid);
        _loadDistricts(_selectedCountry!.countryid, s.stateid);
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_stateOverlay!);
  }

  void _openDistrictDropdown() {
    if (widget.isViewMode || _selectedState == null) return;
    _removeAllOverlays();
    _districtSearchCtrl.clear();

    _districtOverlay = _buildDropdownOverlay<LocationDistrict>(
      link: _districtLayerLink,
      items: _districts,
      isLoading: _districtsLoading,
      searchCtrl: _districtSearchCtrl,
      labelOf: (d) => d.displayName,
      onSelect: (d) {
        setState(() {
          _selectedDistrict = d;
          _districtCtrl.text = d.cityname;
          _pincodeCtrl.clear();
          _pincodes = [];
          _districtError = null;
        });
        widget.onChanged('district', d.cityname);
        widget.onChanged('districtId', d.cityid);
        // Auto-load pincodes for this city
        _loadPincodes(
          _selectedCountry!.countryid,
          _selectedState!.stateid,
          d.cityid,
        );
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_districtOverlay!);
  }

  void _openPincodeDropdown() {
    if (widget.isViewMode || _selectedDistrict == null) return;
    _removeAllOverlays();
    _pincodeSearchCtrl.clear();

    _pincodeOverlay = _buildDropdownOverlay<LocationPincode>(
      link: _pincodeLayerLink,
      items: _pincodes,
      isLoading: _pincodesLoading,
      searchCtrl: _pincodeSearchCtrl,
      labelOf: (p) => p.displayName,
      onSelect: (p) {
        setState(() => _pincodeCtrl.text = p.pincode);
        widget.onChanged('pincode', p.pincode);
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_pincodeOverlay!);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────

  bool _isValidEmail(String v) =>
      v.isEmpty ||
      RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(v);

  bool _isValidPhone(String v) =>
      v.isEmpty ||
      RegExp(r"^[+0-9\s-]{7,15}$").hasMatch(v.replaceAll(RegExp(r'\s+'), ''));

  bool validate() {
    bool hasError = false;
    setState(() {
      _orgCodeError =
          _orgCodeCtrl.text.isEmpty ? 'Organisation Code is mandatory' : null;
      _orgNameError =
          _nameCtrl.text.isEmpty ? 'Organisation Name is mandatory' : null;
      _openDateError =
          _openDateCtrl.text.isEmpty ? 'Open Date is mandatory' : null;
      _countryError = _countryCtrl.text.isEmpty ? 'Country is mandatory' : null;
      _stateError = _stateCtrl.text.isEmpty ? 'State is mandatory' : null;
      _districtError =
          _districtCtrl.text.isEmpty ? 'District is mandatory' : null;
      _addr1Error =
          _addr1Ctrl.text.isEmpty ? 'Address Line 1 is mandatory' : null;
      _emailError = _emailCtrl.text.isEmpty
          ? 'Email Address is mandatory'
          : !_isValidEmail(_emailCtrl.text)
              ? 'Invalid email format (e.g. user@example.com)'
              : null;
      _phoneError = _phoneCtrl.text.isEmpty
          ? 'Telephone is mandatory'
          : !_isValidPhone(_phoneCtrl.text)
              ? 'Invalid phone number (min 7 digits)'
              : null;

      hasError = [
        _orgCodeError,
        _orgNameError,
        _openDateError,
        _countryError,
        _stateError,
        _districtError,
        _addr1Error,
        _emailError,
        _phoneError,
      ].any((e) => e != null);
    });
    return !hasError;
  }

  void clear() {
    setState(() {
      for (final c in [
        _orgCodeCtrl,
        _nameCtrl,
        _openDateCtrl,
        _countryCtrl,
        _stateCtrl,
        _districtCtrl,
        _pincodeCtrl,
        _addr1Ctrl,
        _addr2Ctrl,
        _addr3Ctrl,
        _phoneCtrl,
        _emailCtrl,
      ]) {
        c.clear();
      }
      _selectedCountry = null;
      _selectedState = null;
      _selectedDistrict = null;
      _states = [];
      _districts = [];
      _pincodes = [];
      _orgCodeError = _orgNameError = _emailError = _phoneError =
          _openDateError =
              _countryError = _stateError = _districtError = _addr1Error = null;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Date picker
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _selectDate() async {
    if (widget.isViewMode) return;
    final pick = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.tBlue)),
          child: child!),
    );
    if (pick != null) {
      final fmt = DateFormat('dd-MM-yyyy').format(pick);
      setState(() => _openDateCtrl.text = fmt);
      widget.onChanged('openDate', fmt);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: AmsFormGrid(cols: 2, children: [
        // ── Basic info ────────────────────────────────────────────────────
        _field('Organisation Code*', _orgCodeCtrl,
            isNum: true,
            mandatory: true,
            errorText: _orgCodeError,
            onChanged: (v) => widget.onChanged('orgCode', v)),
        _field('Organisation Name*', _nameCtrl,
            mandatory: true,
            errorText: _orgNameError,
            onChanged: (v) => widget.onChanged('name', v)),
        _buildPickerField('Open Date*', _openDateCtrl, _selectDate,
            Icons.calendar_today_rounded,
            errorText: _openDateError),

        // ── Country (backend dropdown) ────────────────────────────────────
        CompositedTransformTarget(
          link: _countryLayerLink,
          child: _buildPickerField(
            'Country*',
            _countryCtrl,
            _openCountryDropdown,
            Icons.public_rounded,
            errorText: _countryError,
            trailingWidget: _countriesLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
        ),

        // ── State (depends on country) ────────────────────────────────────
        CompositedTransformTarget(
          link: _stateLayerLink,
          child: _buildPickerField(
            'State*',
            _stateCtrl,
            _selectedCountry != null ? _openStateDropdown : () {},
            Icons.map_rounded,
            errorText: _stateError,
            enabled: _selectedCountry != null,
            trailingWidget: _statesLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
        ),

        // ── District / City (depends on state) ───────────────────────────
        CompositedTransformTarget(
          link: _districtLayerLink,
          child: _buildPickerField(
            'District*',
            _districtCtrl,
            _selectedState != null ? _openDistrictDropdown : () {},
            Icons.location_city_rounded,
            errorText: _districtError,
            enabled: _selectedState != null,
            trailingWidget: _districtsLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
        ),

        // ── Pincode (clickable dropdown OR auto-populated when only 1) ───
        CompositedTransformTarget(
          link: _pincodeLayerLink,
          child: _buildPickerField(
            'Pincode',
            _pincodeCtrl,
            _selectedDistrict != null ? _openPincodeDropdown : () {},
            Icons.pin_drop_rounded,
            enabled: _selectedDistrict != null,
            trailingWidget: _pincodesLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
        ),

        // ── Contact ───────────────────────────────────────────────────────
        _field('Email Address*', _emailCtrl,
            mandatory: true, errorText: _emailError, onChanged: (v) {
          setState(() =>
              _emailError = _isValidEmail(v) ? null : 'Invalid email format');
          widget.onChanged('email', v);
        }),
        _field('Telephone*', _phoneCtrl,
            icon: Icons.phone_rounded,
            mandatory: true,
            errorText: _phoneError, onChanged: (v) {
          setState(() =>
              _phoneError = _isValidPhone(v) ? null : 'Invalid phone format');
          widget.onChanged('telephone', v);
        }),

        // ── Address ───────────────────────────────────────────────────────
        _field('Address Line 1*', _addr1Ctrl,
            mandatory: true,
            errorText: _addr1Error,
            onChanged: (v) => widget.onChanged('addrline1', v)),
        _field('Address Line 2', _addr2Ctrl,
            onChanged: (v) => widget.onChanged('addrline2', v)),
        _field('Address Line 3', _addr3Ctrl,
            onChanged: (v) => widget.onChanged('addrline3', v)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Field builders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
    bool mandatory = false,
    bool enabled = true,
    String? errorText,
    IconData? icon,
    void Function(String)? onChanged,
  }) {
    return AmsField(
        label: label,
        labelAbove: true,
        required: mandatory,
        child: AmsTextInput(
            controller: ctrl,
            readOnly: widget.isViewMode || !enabled,
            placeholder: enabled
                ? 'Enter ${label.replaceAll('*', '')}'
                : 'Auto-populated',
            borderColor: AppColors.tBlue,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            inputFormatters:
                isNum ? [FilteringTextInputFormatter.digitsOnly] : null,
            errorText: errorText,
            icon: icon,
            onChanged: onChanged));
  }

  Widget _buildPickerField(
    String label,
    TextEditingController ctrl,
    VoidCallback onTap,
    IconData icon, {
    String? errorText,
    bool enabled = true,
    Widget? trailingWidget,
  }) {
    // Dim the field if it's disabled (waiting for parent selection)
    final isDisabled = widget.isViewMode || !enabled;
    return AmsField(
        label: label,
        labelAbove: true,
        required: label.contains('*'),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            GestureDetector(
                onTap: isDisabled ? null : onTap,
                child: AbsorbPointer(
                    child: AmsTextInput(
                        controller: ctrl,
                        readOnly: true,
                        placeholder: isDisabled && !widget.isViewMode
                            ? 'Select ${label.replaceAll('*', '')} first'
                            : 'Select ${label.replaceAll('*', '')}',
                        borderColor:
                            isDisabled ? AppColors.border : AppColors.tBlue,
                        errorText: errorText,
                        icon: icon))),
            if (trailingWidget != null)
              Positioned(
                right: 12,
                child: trailingWidget,
              ),
          ],
        ));
  }
}
