import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/org_api_service.dart';
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
  static const Map<String, Map<String, String>> _countryInfo = {
    'India': {'flag': '🇮🇳', 'code': '+91', 'iso': 'IN'},
    'USA': {'flag': '🇺🇸', 'code': '+1', 'iso': 'US'},
    'UK': {'flag': '🇬🇧', 'code': '+44', 'iso': 'GB'},
    'Singapore': {'flag': '🇸🇬', 'code': '+65', 'iso': 'SG'},
    'Germany': {'flag': '🇩🇪', 'code': '+49', 'iso': 'DE'},
    'Japan': {'flag': '🇯🇵', 'code': '+81', 'iso': 'JP'},
    'Canada': {'flag': '🇨🇦', 'code': '+1', 'iso': 'CA'},
    'Australia': {'flag': '🇦🇺', 'code': '+61', 'iso': 'AU'},
  };

  static const Map<String, List<String>> _countryStates = {
    'India': ['Tamil Nadu', 'Karnataka', 'Maharashtra', 'Kerala'],
    'USA': ['New York', 'California', 'Texas'],
    'UK': ['Greater London', 'Manchester', 'West Midlands'],
    'Singapore': ['Central Region'],
    'Germany': ['Bavaria', 'Berlin'],
    'Japan': ['Tokyo', 'Osaka'],
    'Canada': ['Ontario', 'Quebec'],
    'Australia': ['New South Wales', 'Victoria'],
  };

  final Map<String, List<String>> _stateDistricts = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Trichy'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode'],
    'New York': ['Manhattan', 'Brooklyn', 'Queens'],
    'California': ['Los Angeles', 'San Francisco', 'San Diego'],
    'Greater London': ['City of London', 'Westminster', 'Camden', 'Greenwich'],
    'Manchester': ['Manchester City', 'Salford', 'Bolton'],
    'West Midlands': ['Birmingham', 'Coventry', 'Wolverhampton'],
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
  bool _pincodeLoading = false;

  final GlobalKey<OrganisationFieldsState> _fieldsKey = GlobalKey<OrganisationFieldsState>();

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
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return true;
    return RegExp(r"^[+0-9\s-]{7,15}$").hasMatch(phone.replaceAll(RegExp(r'\s+'), ''));
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
        // We'll show a snackbar or just a generic error since we don't have _phoneError state yet
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
      // Format openDate to ISO-8601 with offset
      String openDateStr = _openDateCtrl.text; // dd-MM-yyyy
      DateTime openDate = DateFormat('dd-MM-yyyy').parse(openDateStr);
      String isoOpenDate = "${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(openDate.toUtc())}+00:00";

      String countryName = _countryCtrl.text.split(' ').last;
      String countryCode = _countryInfo[countryName]?['iso'] ?? countryName;

      String nowIso = "${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(DateTime.now().toUtc())}+00:00";

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
        "logo": "/ftp/logos/org_header.png"
      };

      if (_isEditMode) {
        payload["cUser"] = widget.userName ?? "admin";
        payload["cDate"] = nowIso;
      } else {
        payload["eUser"] = widget.userName ?? "admin";
        payload["eDate"] = nowIso;
      }

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
        _showTopNotification('Failed to save organisation.',
            isError: true);
        setState(() => _isSaving = false);
      }
    } catch (e) {
      _showTopNotification('Error: $e', isError: true);
      setState(() => _isSaving = false);
    }
  }



  void _enterViewMode(Map<String, dynamic> record, {bool viewOnly = true}) {
    _orgCodeCtrl.text = (record['orgcode'] ?? record['orgCode'] ?? '').toString();
    _nameCtrl.text = record['name'] ?? '';

    // Bind and format Date: yyyy-MM-dd -> dd-MM-yyyy
    String rawDate = (record['openDate'] ?? record['opendate'] ?? '').toString();
    if (rawDate.isNotEmpty) {
      try {
        // Handle full ISO date or just yyyy-MM-dd
        DateTime dt = DateTime.parse(rawDate.split('T')[0]);
        _openDateCtrl.text = DateFormat('dd-MM-yyyy').format(dt);
      } catch (e) {
        _openDateCtrl.text = rawDate;
      }
    } else {
      _openDateCtrl.text = '';
    }

    // Resolve Country Flag from ISO Code
    String countryCode = record['country'] ?? '';
    var match = _countryInfo.entries.where((e) => e.value['iso'] == countryCode);
    if (match.isNotEmpty) {
      final info = match.first.value;
      _countryCtrl.text = "${info['flag']} ${match.first.key}";
    } else {
      _countryCtrl.text = countryCode;
    }

    // Map divisionName to State and District fields
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
        title: Text('Delete Organisation', style: bodyStyle(weight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          AmsButton(label: 'Cancel', variant: AmsButtonVariant.ghost, onPressed: () => Navigator.pop(ctx, false)),
          AmsButton(label: 'Delete', variant: AmsButtonVariant.danger, onPressed: () => Navigator.pop(ctx, true)),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
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
    
    // Clear the child fields via key
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
    if (pick != null) {
      setState(
          () => _openDateCtrl.text = DateFormat('dd-MM-yyyy').format(pick));
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
            return const Center(child: Padding(
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
                                    style: bodyStyle(weight: FontWeight.bold, size: 14)),
                                Text(
                                    '${o['district'] ?? o['divisionName'] ?? ''}, ${o['country'] ?? ''}',
                                    style: bodyStyle(color: AppColors.ink3, size: 11)),
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
                              style: bodyStyle(color: AppColors.tBlue, size: 12, weight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  onTap: () => _confirmDelete(o['orgcode'] ?? 0, o['name'] ?? 'Organisation')),
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
                          Text(o['name'] ?? 'Unknown', style: bodyStyle(weight: FontWeight.bold)),
                          Text('${o['district'] ?? o['divisionName'] ?? ''}, ${o['country'] ?? ''}',
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
                                label: o['email'] ?? '',
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
                              onTap: () => _confirmDelete(o['orgcode'] ?? 0, o['name'] ?? 'Organisation')),
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
                    initialData: _isEditMode || _isViewOnly ? _organisations.firstWhere((o) => (o['orgcode'] ?? o['orgCode'])?.toString() == _orgCodeCtrl.text, orElse: () => {}) : null,
                    onChanged: (k, v) {
                      // Sync from Fields widgets to screen controllers for save logic
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

  String? _orgCodeError;
  String? _orgNameError;
  String? _emailError;
  String? _phoneError;
  String? _openDateError;
  String? _countryError;
  String? _stateError;
  String? _districtError;
  String? _addr1Error;

  static const Map<String, Map<String, String>> _countryInfo = {
    'India': {'flag': '🇮🇳', 'code': '+91', 'iso': 'IN'},
    'USA': {'flag': '🇺🇸', 'code': '+1', 'iso': 'US'},
    'UK': {'flag': '🇬🇧', 'code': '+44', 'iso': 'GB'},
    'Singapore': {'flag': '🇸🇬', 'code': '+65', 'iso': 'SG'},
  };

  static const Map<String, List<String>> _countryStates = {
    'India': ['Tamil Nadu', 'Karnataka', 'Maharashtra', 'Kerala'],
    'USA': ['New York', 'California', 'Texas'],
  };

  final Map<String, List<String>> _stateDistricts = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Trichy'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
  };

  final Map<String, String> _pincodeMap = {
    'Chennai': '600001',
    'Bangalore': '560001',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadCountries(); // Pre-load countries on init
  }

  @override
  void didUpdateWidget(OrganisationFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    if (widget.initialData == null) return;
    final d = widget.initialData!.map((k, v) => MapEntry(k.toLowerCase(), v));
    _orgCodeCtrl.text = (d['orgcode'] ?? '').toString();
    _nameCtrl.text = (d['name'] ?? d['orgname'] ?? '').toString();
    
    String rawDate = (d['opendate'] ?? '').toString();
    if (rawDate.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(rawDate.split('T')[0]);
        _openDateCtrl.text = DateFormat('dd-MM-yyyy').format(dt);
      } catch (_) {
        _openDateCtrl.text = rawDate;
      }
    }

    String countryCode = (d['country'] ?? '').toString();
    var match = _countryInfo.entries.where((e) => e.value['iso'] == countryCode);
    if (match.isNotEmpty) {
      final info = match.first.value;
      _countryCtrl.text = "${info['flag']} ${match.first.key}";
    } else {
      _countryCtrl.text = countryCode;
    }

    String div = (d['divisionname'] ?? d['state'] ?? '').toString();
    if (div.contains(' - ')) {
      var parts = div.split(' - ');
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
  }

  // --- Smart Search (Overlays) ---
  final _countryLayerLink = LayerLink();
  final _stateLayerLink = LayerLink();
  final _districtLayerLink = LayerLink();
  
  OverlayEntry? _countryOverlay;
  OverlayEntry? _stateOverlay;
  OverlayEntry? _districtOverlay;

  final _countrySearchCtrl = TextEditingController();
  final _stateSearchCtrl = TextEditingController();
  final _districtSearchCtrl = TextEditingController();

  static List<String> _cachedCountries = [];
  static Map<String, String> _cachedIsoMap = {};
  
  List<String> _countriesList = _cachedCountries;
  final Map<String, String> _countryIsoMap = Map.from(_cachedIsoMap);
  List<String> _statesList = [];
  List<String> _districtsList = [];
  
  bool _countriesLoading = false;
  bool _statesLoading = false;
  bool _districtsLoading = false;
  bool _pincodeLoading = false;

  String? _selectedCountryIso;

  @override
  void dispose() {
    _removeAllOverlays();
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
    _countrySearchCtrl.dispose();
    _stateSearchCtrl.dispose();
    _districtSearchCtrl.dispose();
    super.dispose();
  }

  void _removeAllOverlays() {
    _countryOverlay?.remove();
    _countryOverlay = null;
    _stateOverlay?.remove();
    _stateOverlay = null;
    _districtOverlay?.remove();
    _districtOverlay = null;
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return true;
    return RegExp(r"^[+0-9\s-]{7,15}$").hasMatch(phone.replaceAll(RegExp(r'\s+'), ''));
  }

  bool validate() {
    bool hasError = false;
    setState(() {
      _orgCodeError = null;
      _orgNameError = null;
      _emailError = null;
      _phoneError = null;
      _openDateError = null;
      _countryError = null;
      _stateError = null;
      _districtError = null;
      _addr1Error = null;

      if (_orgCodeCtrl.text.isEmpty) {
        _orgCodeError = 'Organisation Code is mandatory';
        hasError = true;
      }
      if (_nameCtrl.text.isEmpty) {
        _orgNameError = 'Organisation Name is mandatory';
        hasError = true;
      }
      if (_openDateCtrl.text.isEmpty) {
        _openDateError = 'Open Date is mandatory';
        hasError = true;
      }
      if (_countryCtrl.text.isEmpty) {
        _countryError = 'Country is mandatory';
        hasError = true;
      }
      if (_stateCtrl.text.isEmpty) {
        _stateError = 'State is mandatory';
        hasError = true;
      }
      if (_districtCtrl.text.isEmpty) {
        _districtError = 'District is mandatory';
        hasError = true;
      }
      if (_emailCtrl.text.isEmpty) {
        _emailError = 'Email Address is mandatory';
        hasError = true;
      } else if (!_isValidEmail(_emailCtrl.text)) {
        _emailError = 'Invalid email format (e.g. user@example.com)';
        hasError = true;
      }
      if (_phoneCtrl.text.isEmpty) {
        _phoneError = 'Telephone is mandatory';
        hasError = true;
      } else if (!_isValidPhone(_phoneCtrl.text)) {
        _phoneError = 'Invalid phone number (min 7 digits)';
        hasError = true;
      }
      if (_addr1Ctrl.text.isEmpty) {
        _addr1Error = 'Address Line 1 is mandatory';
        hasError = true;
      }
    });
    return !hasError;
  }

  void clear() {
    setState(() {
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

      _orgCodeError = null;
      _orgNameError = null;
      _emailError = null;
      _phoneError = null;
      _openDateError = null;
      _countryError = null;
      _stateError = null;
      _districtError = null;
      _addr1Error = null;
    });
  }

  // --- External APIs for Addresses ---

  Future<void> _loadCountries() async {
    if (_countriesLoading || _countriesList.isNotEmpty) return;
    
    // Add default common countries immediately to avoid empty list
    if (_countriesList.isEmpty) {
      setState(() {
        _countriesList = ['India', 'USA', 'UK', 'Singapore', 'Canada', 'Australia', 'Germany', 'Japan'];
        _countryIsoMap.addAll({'India': 'IN', 'USA': 'US', 'UK': 'GB', 'Singapore': 'SG', 'Canada': 'CA', 'Australia': 'AU', 'Germany': 'DE', 'Japan': 'JP'});
      });
    }

    setState(() => _countriesLoading = true);
    try {
      final res = await http.get(Uri.parse('https://countriesnow.space/api/v0.1/countries')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] ?? [];
        final names = data.map<String>((e) => e['country'] as String).toList()..sort();
        final isoMap = <String, String>{};
        for (final entry in data) {
          final name = entry['country'] as String? ?? '';
          final iso = entry['iso2'] as String? ?? '';
          if (name.isNotEmpty && iso.isNotEmpty) isoMap[name] = iso.toUpperCase();
        }
        
        // Update cache
        _cachedCountries = names;
        _cachedIsoMap = isoMap;

        if (mounted) {
          setState(() {
            _countriesList = names;
            _countryIsoMap.clear();
            _countryIsoMap.addAll(isoMap);
          });
        }
      }
    } catch (e) {
      debugPrint("Country Load Error: $e");
    } finally {
      if (mounted) setState(() => _countriesLoading = false);
    }
  }

  Future<void> _loadStates(String countryName) async {
    setState(() {
      _statesLoading = true;
      _statesList = [];
      _districtsList = [];
    });
    try {
      final res = await http.post(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/states'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'country': countryName}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List stateList = decoded['data']?['states'] ?? [];
        final names = stateList.map<String>((s) => s['name'] as String).toList()..sort();
        if (mounted) setState(() => _statesList = names);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _statesLoading = false);
    }
  }

  Future<void> _loadDistricts(String countryName, String stateName) async {
    setState(() {
      _districtsLoading = true;
      _districtsList = [];
    });
    try {
      final res = await http.post(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/state/cities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'country': countryName, 'state': stateName}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List cities = decoded['data'] ?? [];
        final names = cities.cast<String>()..sort();
        if (mounted) setState(() => _districtsList = names);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _districtsLoading = false);
    }
  }

  Future<void> _loadPincode(String cityName) async {
    if (!mounted) return;
    setState(() => _pincodeLoading = true);
    try {
      final res = await http.get(Uri.parse('https://api.postalpincode.in/postoffice/${Uri.encodeComponent(cityName)}')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            final pincode = postOffices[0]['Pincode']?.toString() ?? '';
            if (pincode.isNotEmpty && mounted) {
              setState(() => _pincodeCtrl.text = pincode);
              widget.onChanged('pincode', pincode);
            }
          }
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _pincodeLoading = false);
    }
  }

  OverlayEntry _buildDropdownOverlay({
    required LayerLink link,
    required List<String> items,
    required bool isLoading,
    required TextEditingController searchCtrl,
    required Function(String) onSelect,
    required VoidCallback onClose,
  }) {
    return OverlayEntry(
      builder: (context) => GestureDetector(
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
                        padding: const EdgeInsets.all(8.0),
                        child: AmsTextInput(
                          controller: searchCtrl,
                          placeholder: 'Search...',
                          icon: Icons.search,
                          onChanged: (v) => (context as Element).markNeedsBuild(),
                        ),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Flexible(
                          child: Builder(builder: (ctx) {
                            final query = searchCtrl.text.toLowerCase();
                            final filtered = items.where((i) => i.toLowerCase().contains(query)).toList();
                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No results found'),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              itemBuilder: (ctx, idx) => ListTile(
                                title: Text(filtered[idx], style: bodyStyle(size: 13)),
                                dense: true,
                                onTap: () => onSelect(filtered[idx]),
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

  void _openCountryDropdown() {
    if (widget.isViewMode) return;
    _removeAllOverlays();
    _loadCountries();
    _countrySearchCtrl.clear();
    _countryOverlay = _buildDropdownOverlay(
      link: _countryLayerLink,
      items: _countriesList,
      isLoading: _countriesLoading,
      searchCtrl: _countrySearchCtrl,
      onSelect: (val) {
        setState(() {
          _countryCtrl.text = val;
          _selectedCountryIso = _countryIsoMap[val];
          _stateCtrl.clear();
          _districtCtrl.clear();
          _pincodeCtrl.clear();
        });
        widget.onChanged('country', val);
        _loadStates(val);
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_countryOverlay!);
  }

  void _openStateDropdown() {
    if (widget.isViewMode || _countryCtrl.text.isEmpty) return;
    _removeAllOverlays();
    _stateSearchCtrl.clear();
    _stateOverlay = _buildDropdownOverlay(
      link: _stateLayerLink,
      items: _statesList,
      isLoading: _statesLoading,
      searchCtrl: _stateSearchCtrl,
      onSelect: (val) {
        setState(() {
          _stateCtrl.text = val;
          _districtCtrl.clear();
          _pincodeCtrl.clear();
        });
        widget.onChanged('state', val);
        _loadDistricts(_countryCtrl.text, val);
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_stateOverlay!);
  }

  void _openDistrictDropdown() {
    if (widget.isViewMode || _stateCtrl.text.isEmpty) return;
    _removeAllOverlays();
    _districtSearchCtrl.clear();
    _districtOverlay = _buildDropdownOverlay(
      link: _districtLayerLink,
      items: _districtsList,
      isLoading: _districtsLoading,
      searchCtrl: _districtSearchCtrl,
      onSelect: (val) {
        setState(() {
          _districtCtrl.text = val;
          _pincodeCtrl.clear();
        });
        widget.onChanged('district', val);
        _loadPincode(val);
        _removeAllOverlays();
      },
      onClose: _removeAllOverlays,
    );
    Overlay.of(context).insert(_districtOverlay!);
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: AmsFormGrid(cols: 2, children: [
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
            Icons.calendar_today_rounded, errorText: _openDateError),
        
        CompositedTransformTarget(
          link: _countryLayerLink,
          child: _buildPickerField('Country*', _countryCtrl, _openCountryDropdown,
              Icons.public_rounded, errorText: _countryError),
        ),
        CompositedTransformTarget(
          link: _stateLayerLink,
          child: _buildPickerField('State Code*', _stateCtrl, _openStateDropdown,
              Icons.map_rounded, errorText: _stateError),
        ),
        CompositedTransformTarget(
          link: _districtLayerLink,
          child: _buildPickerField('District Code*', _districtCtrl,
              _openDistrictDropdown, Icons.location_city_rounded, errorText: _districtError),
        ),
        
        _field('Pincode*', _pincodeCtrl, enabled: false),
        _field('Email Address*', _emailCtrl,
            mandatory: true,
            errorText: _emailError,
            onChanged: (v) {
              setState(() => _emailError = _isValidEmail(v) ? null : 'Invalid email format');
              widget.onChanged('email', v);
            }),
        _field('Telephone*', _phoneCtrl, icon: Icons.phone_rounded,
            mandatory: true,
            errorText: _phoneError,
            onChanged: (v) {
              setState(() => _phoneError = _isValidPhone(v) ? null : 'Invalid phone format');
              widget.onChanged('telephone', v);
            }),
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
            readOnly: widget.isViewMode || !enabled,
            placeholder: enabled
                ? 'Enter ${label.replaceAll('*', '')}'
                : 'Auto-populated',
            borderColor: AppColors.tBlue,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : null,
            errorText: errorText,
            icon: icon,
            onChanged: onChanged));
  }

  Widget _buildPickerField(String label, TextEditingController ctrl,
      VoidCallback onTap, IconData icon, {String? errorText}) {
    return AmsField(
        label: label,
        labelAbove: true,
        required: label.contains('*'),
        child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
                child: AmsTextInput(
                    controller: ctrl,
                    readOnly: widget.isViewMode,
                    placeholder: 'Select $label',
                    borderColor: AppColors.tBlue,
                    errorText: errorText,
                    icon: icon))));
  }

  Future<void> _selectDate() async {
    if (widget.isViewMode) return;
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
    if (pick != null) {
      String fmt = DateFormat('dd-MM-yyyy').format(pick);
      setState(() => _openDateCtrl.text = fmt);
      widget.onChanged('openDate', fmt);
    }
  }
}
