import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

// ─── Entry widget (receives navigation callbacks) ─────────────────────────────

class GlSegmentsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const GlSegmentsScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return GLSegmentPage(onBack: onBack, onBackToModule: onBackToModule);
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class Segment {
  final int id;
  String level;
  String segmentId;
  String segmentValue;
  String type;
  bool isActive;

  Segment({
    required this.id,
    required this.level,
    required this.segmentId,
    required this.segmentValue,
    required this.type,
    this.isActive = true,
  });
}

// ─── Constants ────────────────────────────────────────────────────────────────

const Color kNavy = Color(0xFF1E3A5F);
const Color kBlueMid = Color(0xFF3B82F6);
const Color kPurple = Color(0xFF8B5CF6);
const Color kGreenStatus = Color(0xFF22C55E);
const Color kOrangeRed = Color(0xFFEF4444);
const Color kGreenIcon = Color(0xFF10B981);
const Color kBg = Color(0xFFF4F6FA);
const Color kCardBorder = Color(0xFFE2E8F0);
const Color kTextDark = Color(0xFF0F172A);
const Color kTextMid = Color(0xFF475569);
const Color kTextLight = Color(0xFF94A3B8);
const Color kPillBg = Color(0xFFEDF2FB);
const Color kRedBack = Color(0xFFDC2626);

// Validation colors
const Color kValidGreen = Color(0xFF22C55E);
const Color kInvalidRed = Color(0xFFEF4444);

Color _levelColor(String level) {
  switch (level) {
    case 'L1':
      return const Color(0xFF1565C0);
    case 'L2':
      return const Color(0xFF00897B);
    default:
      return const Color(0xFFF57C00);
  }
}

double _levelIndent(String level) {
  switch (level) {
    case 'L1':
      return 0;
    case 'L2':
      return 20;
    default:
      return 40;
  }
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class GLSegmentPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  const GLSegmentPage(
      {super.key, required this.onBack, required this.onBackToModule});

  @override
  State<GLSegmentPage> createState() => _GLSegmentPageState();
}

class _GLSegmentPageState extends State<GLSegmentPage> {
  final List<String> glAccounts = [
    'GL 50010 — Staff Salaries',
    'GL 50020 — Office Expenses',
    'GL 50030 — Travel & Conveyance',
    'GL 50040 — Rent & Utilities',
  ];
  String selectedGL = 'GL 50010 — Staff Salaries';

  String _searchQuery = '';
  bool showForm = false;
  Segment? editingSegment;
  int nextId = 7;

  final List<Segment> segments = [
    Segment(
        id: 1,
        level: 'L1',
        segmentId: 'DEPT',
        segmentValue: 'Finance',
        type: 'Type 1'),
    Segment(
        id: 2,
        level: 'L2',
        segmentId: 'COSTCTR',
        segmentValue: 'Payroll',
        type: 'Type 2'),
    Segment(
        id: 3,
        level: 'L3',
        segmentId: 'PROJECT',
        segmentValue: 'SAP Rollout',
        type: 'Type 3'),
    Segment(
        id: 4,
        level: 'L2',
        segmentId: 'COSTCTR',
        segmentValue: 'IT Support',
        type: 'Type 2',
        isActive: false),
    Segment(
        id: 5,
        level: 'L1',
        segmentId: 'REGION',
        segmentValue: 'South Asia',
        type: 'Type 1'),
    Segment(
        id: 6,
        level: 'L2',
        segmentId: 'BRANCH',
        segmentValue: 'Bangalore',
        type: 'Type 2'),
  ];

  List<Segment> get _filtered => _searchQuery.isEmpty
      ? List.from(segments)
      : segments
          .where((s) =>
              s.segmentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.segmentValue.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  void _openAddForm() => setState(() {
        editingSegment = null;
        showForm = true;
      });
  void _openEditForm(Segment s) => setState(() {
        editingSegment = s;
        showForm = true;
      });
  void _closeForm() => setState(() => showForm = false);
  void _deleteSegment(int id) =>
      setState(() => segments.removeWhere((s) => s.id == id));

  void _onSave(String level, String segId, String segValue, bool isActive) {
    setState(() {
      final typeNum = level.replaceAll('L', '');
      if (editingSegment != null) {
        editingSegment!
          ..level = level
          ..segmentId = segId
          ..segmentValue = segValue
          ..type = 'Type $typeNum'
          ..isActive = isActive;
      } else {
        segments.add(Segment(
          id: nextId++,
          level: level,
          segmentId: segId,
          segmentValue: segValue,
          type: 'Type $typeNum',
          isActive: isActive,
        ));
      }
      showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showForm) {
      return Scaffold(
        backgroundColor: kBg,
        body: Column(children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.account_tree_rounded,
                size: 28, color: AppColors.tBlue),
            title: editingSegment != null
                ? 'Edit GL Segment'
                : 'Create GL Segment',
            subtitle: '',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(
                  label: 'GL Module', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'GL Segments', onTap: _closeForm),
              HeaderBreadcrumb(
                  label: editingSegment != null
                      ? 'Edit GL Segment'
                      : 'Create GL Segment'),
            ],
            onBack: _closeForm,
          ),
          Expanded(
            child: _AddEditForm(
              key: ValueKey(editingSegment?.id ?? 'new'),
              editingSegment: editingSegment,
              glNo: selectedGL.split(' ')[1],
              onSave: _onSave,
              onCancel: _closeForm,
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        AmsIdentityHeader(
          icon: const Icon(Icons.account_tree_rounded,
              size: 28, color: AppColors.tBlue),
          title: 'GL Segment Configuration',
          subtitle: '',
          badges: [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
            HeaderBreadcrumb(label: 'GL Segments'),
          ],
          onBack: widget.onBackToModule,
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  // ─── UPDATED: Wrapped in white Container like GL Master ───────────────────

  Widget _buildBody() {
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kCardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('* Select GL Account',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextMid)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kCardBorder, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGL,
                  isExpanded: true,
                  style: const TextStyle(color: kTextMid, fontSize: 14),
                  items: glAccounts
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedGL = v!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kCardBorder, width: 1.5),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search, color: kTextLight, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontSize: 14, color: kTextMid),
                        decoration: const InputDecoration(
                          hintText: 'Search segments...',
                          hintStyle:
                              TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kCardBorder, width: 1.5),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: const Icon(Icons.refresh, color: kNavy, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _openAddForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('+ New GL',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Text('Showing 1–${filtered.length} of ${segments.length}',
                style: const TextStyle(fontSize: 12, color: kTextLight)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kCardBorder, width: 1.4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: filtered.asMap().entries.map((entry) {
                    final isLast = entry.key == filtered.length - 1;
                    return _hierarchyRow(entry.value, isLast);
                  }).toList(),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _hierarchyRow(Segment seg, bool isLast) {
    final color = _levelColor(seg.level);
    final indent = _levelIndent(seg.level);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFEEF2FA), width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (indent > 0)
            Container(width: indent, color: const Color(0xFFF8FAFF)),
          Container(width: 5, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(seg.level,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2)),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 100,
                  child: Text(seg.segmentId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: kTextDark,
                          letterSpacing: 0.1)),
                ),
                Expanded(
                  child: Text(seg.segmentValue,
                      style: const TextStyle(fontSize: 13, color: kTextMid)),
                ),
                SizedBox(
                  width: 64,
                  child: Text(seg.type,
                      style: const TextStyle(fontSize: 12, color: kTextLight)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openEditForm(seg),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child:
                        Icon(Icons.edit_outlined, size: 16, color: kTextLight),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _deleteSegment(seg.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: kTextLight),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Add / Edit Form ──────────────────────────────────────────────────────────

class _AddEditForm extends StatefulWidget {
  final Segment? editingSegment;
  final String glNo;
  final void Function(
      String level, String segId, String segValue, bool isActive) onSave;
  final VoidCallback onCancel;

  const _AddEditForm({
    super.key,
    required this.editingSegment,
    required this.glNo,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_AddEditForm> createState() => _AddEditFormState();
}

class _AddEditFormState extends State<_AddEditForm> {
  late TextEditingController _glNoCtrl;
  late TextEditingController _segIdCtrl;
  late TextEditingController _segValueCtrl;
  String? _selectedLevel;
  bool? _selectedActive;

  bool? _segIdValid;
  bool? _segValueValid;
  bool? _levelValid;
  bool? _activeValid;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final seg = widget.editingSegment;
    _glNoCtrl = TextEditingController(text: widget.glNo);
    _segIdCtrl = TextEditingController(text: seg?.segmentId ?? '');
    _segValueCtrl = TextEditingController(text: seg?.segmentValue ?? '');
    _selectedLevel = seg?.level;
    _selectedActive = seg?.isActive;

    if (seg != null) {
      _segIdValid = true;
      _segValueValid = true;
      _levelValid = true;
      _activeValid = true;
    }
  }

  @override
  void dispose() {
    _glNoCtrl.dispose();
    _segIdCtrl.dispose();
    _segValueCtrl.dispose();
    super.dispose();
  }

  void _validateSegId(String val) {
    setState(() => _segIdValid = val.trim().isNotEmpty);
  }

  void _validateSegValue(String val) {
    setState(() => _segValueValid = val.trim().isNotEmpty);
  }

  void _validateLevel(String? val) {
    setState(() {
      _selectedLevel = val;
      _levelValid = val != null && val.isNotEmpty;
    });
  }

  void _validateActive(String? val) {
    setState(() {
      _selectedActive = val == 'Active';
      _activeValid = val != null && val.isNotEmpty;
    });
  }

  bool _validateAll() {
    setState(() {
      _submitted = true;
      _segIdValid = _segIdCtrl.text.trim().isNotEmpty;
      _segValueValid = _segValueCtrl.text.trim().isNotEmpty;
      _levelValid = _selectedLevel != null && _selectedLevel!.isNotEmpty;
      _activeValid = _selectedActive != null;
    });
    return (_segIdValid == true) &&
        (_segValueValid == true) &&
        (_levelValid == true) &&
        (_activeValid == true);
  }

  void _clear() => setState(() {
        _segIdCtrl.clear();
        _segValueCtrl.clear();
        _selectedLevel = null;
        _selectedActive = null;
        _segIdValid = null;
        _segValueValid = null;
        _levelValid = null;
        _activeValid = null;
        _submitted = false;
      });

  InputBorder _borderFor(bool? valid, {bool isFocused = false}) {
    if (valid == null) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isFocused ? kNavy.withOpacity(0.5) : kCardBorder,
          width: 1.0,
        ),
      );
    }
    if (valid) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: kValidGreen.withOpacity(0.5), width: 1.0),
      );
    }
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kInvalidRed.withOpacity(0.5), width: 1.0),
    );
  }

  Color _fillFor(bool? valid) => Colors.white;

  Widget _errorMsg(String message, bool? valid) {
    if (valid == false) {
      return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(message,
            style: const TextStyle(fontSize: 12, color: kInvalidRed)),
      );
    }
    return const SizedBox(height: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kCardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
            decoration: const BoxDecoration(
              color: kNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              widget.editingSegment != null
                  ? 'Edit Segment'
                  : 'Create GL Segment',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                final fields = [
                  _field(
                    'GL No.',
                    TextField(
                      controller: _glNoCtrl,
                      readOnly: true,
                      style: const TextStyle(color: kTextLight, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Auto-filled',
                        hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: _borderFor(null),
                        enabledBorder: _borderFor(null),
                        focusedBorder: _borderFor(null, isFocused: true),
                      ),
                    ),
                    info: 'Auto-filled from selected GL account',
                    errorWidget: const SizedBox(height: 18),
                  ),
                  _field(
                    'Segment Type',
                    DropdownButtonFormField<String>(
                      value: _selectedLevel,
                      hint: const Text('Select type',
                          style: TextStyle(
                              color: Color(0xFFCBD5E1), fontSize: 14)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: _fillFor(_submitted ? _levelValid : null),
                        border: _borderFor(_submitted ? _levelValid : null),
                        enabledBorder:
                            _borderFor(_submitted ? _levelValid : null),
                        focusedBorder: _borderFor(_levelValid, isFocused: true),
                      ),
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      items: ['L1', 'L2', 'L3']
                          .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: _validateLevel,
                    ),
                    info: 'L1 = top level, L2 = sub, L3 = leaf',
                    errorWidget: _errorMsg('Segment Type is required',
                        _submitted ? _levelValid : null),
                  ),
                  _field(
                    'Segment ID',
                    TextField(
                      controller: _segIdCtrl,
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      onChanged: _validateSegId,
                      decoration: InputDecoration(
                        hintText: 'e.g. DEPT, COSTCTR',
                        hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: _borderFor(_segIdValid),
                        enabledBorder: _borderFor(_segIdValid),
                        focusedBorder: _borderFor(_segIdValid, isFocused: true),
                      ),
                    ),
                    info: 'Unique identifier for the segment',
                    errorWidget:
                        _errorMsg('Segment ID is required', _segIdValid),
                  ),
                  _field(
                    'Segment Value',
                    TextField(
                      controller: _segValueCtrl,
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      onChanged: _validateSegValue,
                      decoration: InputDecoration(
                        hintText: 'e.g. Finance, Payroll',
                        hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: _borderFor(_segValueValid),
                        enabledBorder: _borderFor(_segValueValid),
                        focusedBorder:
                            _borderFor(_segValueValid, isFocused: true),
                      ),
                    ),
                    info: 'Display value or description',
                    errorWidget:
                        _errorMsg('Segment Value is required', _segValueValid),
                  ),
                  _field(
                    'Status',
                    DropdownButtonFormField<String>(
                      value: _selectedActive == null
                          ? null
                          : (_selectedActive! ? 'Active' : 'Inactive'),
                      hint: const Text('Active / Inactive',
                          style: TextStyle(
                              color: Color(0xFFCBD5E1), fontSize: 14)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: _fillFor(_submitted ? _activeValid : null),
                        border: _borderFor(_submitted ? _activeValid : null),
                        enabledBorder:
                            _borderFor(_submitted ? _activeValid : null),
                        focusedBorder:
                            _borderFor(_activeValid, isFocused: true),
                      ),
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      items: ['Active', 'Inactive']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: _validateActive,
                    ),
                    info: 'Active or Inactive',
                    errorWidget: _errorMsg(
                        'Status is required', _submitted ? _activeValid : null),
                  ),
                ];

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        Wrap(
                            spacing: 24,
                            runSpacing: 0,
                            children: fields
                                .map((f) => SizedBox(
                                    width: (constraints.maxWidth - 24) / 2,
                                    child: f))
                                .toList())
                      else
                        Column(children: fields),
                      const Text('* Required fields',
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 32),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_validateAll()) {
                              widget.onSave(
                                _selectedLevel ?? '',
                                _segIdCtrl.text.trim(),
                                _segValueCtrl.text.trim(),
                                _selectedActive ?? true,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Save',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 16),
                              ]),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kTextMid,
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                                color: kCardBorder, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.format_align_left, size: 15),
                                SizedBox(width: 6),
                                Text('Clear',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ]),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: widget.onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRedBack,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, size: 15),
                                SizedBox(width: 6),
                                Text('Cancel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ]),
                        ),
                      ]),
                    ]);
              }),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, Widget child,
      {String? info, Widget? errorWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RichText(
              text: TextSpan(children: [
            const TextSpan(
                text: '* ',
                style: TextStyle(
                    color: kOrangeRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            TextSpan(
                text: label,
                style: const TextStyle(
                    color: kTextMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ])),
          if (info != null) ...[
            const SizedBox(width: 6),
            Tooltip(
                message: info,
                child: const Icon(Icons.info_outline,
                    size: 14, color: kTextLight)),
          ],
        ]),
        const SizedBox(height: 8),
        child,
        if (errorWidget != null) errorWidget,
      ]),
    );
  }
}
