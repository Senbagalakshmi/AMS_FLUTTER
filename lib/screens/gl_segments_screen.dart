import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/gl_api_service.dart';

// ─── Entry widget ─────────────────────────────────────────────────────────────

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
  int? glNo;
  String? glName;

  Segment({
    required this.id,
    required this.level,
    required this.segmentId,
    required this.segmentValue,
    required this.type,
    this.isActive = true,
    this.glNo,
    this.glName,
  });

  /// API response → Segment
  factory Segment.fromApi(Map<String, dynamic> map) {
    final segType = (map['segType'] as int?) ?? 1;
    return Segment(
      id: (map['glNo'] as int?) ?? 0,
      level: 'L$segType',
      segmentId: map['segId']?.toString() ?? '',
      segmentValue: map['segValue']?.toString() ?? '',
      type: 'Type $segType',
      isActive: true,
      glNo: map['glNo'] as int?,
      glName: map['glName']?.toString(),
    );
  }

  /// Segment → API request body
  Map<String, dynamic> toApiMap() => {
        'glNo': glNo,
        'segId': segmentId,
        'segValue': segmentValue,
        'segType': int.tryParse(level.replaceAll('L', '')) ?? 1,
      };
}

// ─── Constants ────────────────────────────────────────────────────────────────

const Color kNavy = Color(0xFF1E3A5F);
const Color kBlueMid = Color(0xFF3B82F6);
const Color kOrangeRed = Color(0xFFEF4444);
const Color kBg = Color(0xFFF4F6FA);
const Color kCardBorder = Color(0xFFE2E8F0);
const Color kTextDark = Color(0xFF0F172A);
const Color kTextMid = Color(0xFF475569);
const Color kTextLight = Color(0xFF94A3B8);
const Color kRedBack = Color(0xFFDC2626);
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

// ─── Screen state enum ────────────────────────────────────────────────────────

enum _ScreenState { list, view, edit }

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
  final GLApiService _glApi = GLApiService();

  _ScreenState _screen = _ScreenState.list;
  Segment? _activeSegment;

  // ── GL Masters from API ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _glMasters = [];
  bool _loadingGlMasters = false;
  Map<String, dynamic>? _selectedGlMaster;

  // ── GL Segments from API ──────────────────────────────────────────────────
  List<Segment> _segments = [];
  bool _loadingSegments = false;
  String? _segmentsError;

  String _searchQuery = '';

  List<Segment> get _filtered => _searchQuery.isEmpty
      ? List.from(_segments)
      : _segments
          .where((s) =>
              s.segmentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.segmentValue.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadGlMasters();
    _loadGlSegments();
  }

  Future<void> _loadGlMasters() async {
    setState(() => _loadingGlMasters = true);
    final data = await apiService.getAllGlMasters();
    setState(() {
      _loadingGlMasters = false;
      _glMasters = data?.items ?? [];
      if (_glMasters.isNotEmpty && _selectedGlMaster == null) {
        _selectedGlMaster = _glMasters.first;
      }
    });
  }

  Future<void> _loadGlSegments() async {
    setState(() {
      _loadingSegments = true;
      _segmentsError = null;
    });
    final data = await _glApi.getAllGlSegments();
    setState(() {
      _loadingSegments = false;
      if (data != null) {
        _segments = data.map((m) => Segment.fromApi(m)).toList();
      } else {
        _segmentsError = 'Failed to load segments. Tap refresh to retry.';
      }
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goList() => setState(() {
        _screen = _ScreenState.list;
        _activeSegment = null;
      });

  void _goView(Segment s) => setState(() {
        _screen = _ScreenState.view;
        _activeSegment = s;
      });

  void _goEdit(Segment? s) => setState(() {
        _screen = _ScreenState.edit;
        _activeSegment = s;
      });

  // ── Delete ────────────────────────────────────────────────────────────────

  void _deleteSegment(Segment seg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Segment',
            style: TextStyle(
                color: kTextDark, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${seg.segmentId} — ${seg.segmentValue}"?\nThis cannot be undone.',
            style: const TextStyle(color: kTextMid, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextMid, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (seg.glNo == null) return;

              final success = await _glApi.deleteGlSegment(seg.glNo!);

              if (!mounted) return;
              if (success) {
                setState(() => _segments.removeWhere((s) => s.id == seg.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Segment deleted successfully'),
                    backgroundColor: kValidGreen,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Failed to delete segment. Please try again.'),
                    backgroundColor: kInvalidRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kInvalidRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Save (Create / Update) ────────────────────────────────────────────────

  Future<void> _onSave(
    String level,
    String segId,
    String segValue,
    bool isActive,
    int glNo,
    String glName,
    int orgCode,
  ) async {
    final typeNum = level.replaceAll('L', '');
    final isEditing = _activeSegment != null;

    final payload = {
      'orgCode': orgCode,
      'glNo': glNo,
      'segId': segId,
      'segValue': segValue,
      'segType': int.tryParse(typeNum) ?? 1,
    };

    bool success;
    if (isEditing) {
      success = await _glApi.updateGlSegment(payload);
    } else {
      success = await _glApi.createGlSegment(payload);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Segment updated successfully'
              : 'Segment created successfully'),
          backgroundColor: kValidGreen,
        ),
      );
      // Refresh list from API
      await _loadGlSegments();
      setState(() {
        _screen = _ScreenState.list;
        _activeSegment = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Failed to update segment. Please try again.'
              : 'Failed to create segment. Please try again.'),
          backgroundColor: kInvalidRed,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _ScreenState.view:
        return _buildViewPage();
      case _ScreenState.edit:
        return _buildEditPage();
      case _ScreenState.list:
        return _buildListPage();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW PAGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildViewPage() {
    final seg = _activeSegment!;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        AmsIdentityHeader(
          icon: const Icon(Icons.account_tree_rounded,
              size: 28, color: AppColors.tBlue),
          title: 'GL Attribute',
          subtitle: 'Manage custom fields for GL accounts',
          badges: [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
            HeaderBreadcrumb(label: 'GL Attribute', onTap: _goList),
          ],
          onBack: _goList,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kCardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: kNavy,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Row(children: [
                    Expanded(
                      child: Text('View GL Attribute',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                    Icon(Icons.keyboard_arrow_up,
                        color: Colors.white, size: 22),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      final half = (constraints.maxWidth - 24) / 2;

                      Widget readField(String label, String value,
                          {bool required = true, String? tooltip}) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  if (required)
                                    const Text('* ',
                                        style: TextStyle(
                                            color: kOrangeRed,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                  Text(label,
                                      style: const TextStyle(
                                          color: kTextMid,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  if (tooltip != null) ...[
                                    const SizedBox(width: 5),
                                    Tooltip(
                                        message: tooltip,
                                        child: const Icon(Icons.info_outline,
                                            size: 14, color: kTextLight)),
                                  ],
                                ]),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5FB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: kCardBorder, width: 1.2),
                                  ),
                                  child: Text(value,
                                      style: const TextStyle(
                                          color: kTextMid, fontSize: 14)),
                                ),
                              ]),
                        );
                      }

                      final fields = [
                        readField('GL No.', seg.glNo?.toString() ?? '—',
                            tooltip: 'GL Account Number'),
                        readField('Segment ID', seg.segmentId,
                            tooltip: 'Unique attribute identifier'),
                        readField('Segment Value', seg.segmentValue,
                            tooltip: 'Attribute value'),
                        readField('Segment Type', seg.level,
                            tooltip: 'L1 / L2 / L3'),
                        readField('Description', seg.type,
                            required: false, tooltip: 'Optional description'),
                      ];

                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isWide)
                              Wrap(
                                  spacing: 24,
                                  runSpacing: 0,
                                  children: fields
                                      .map((f) =>
                                          SizedBox(width: half, child: f))
                                      .toList())
                            else
                              Column(children: fields),
                          ]);
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _goList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRedBack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                      ),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.arrow_back, size: 15),
                        SizedBox(width: 8),
                        Text('Back to List',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 15),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EDIT PAGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEditPage() {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        AmsIdentityHeader(
          icon: const Icon(Icons.account_tree_rounded,
              size: 28, color: AppColors.tBlue),
          title:
              _activeSegment != null ? 'Edit GL Segment' : 'Create GL Segment',
          subtitle: '',
          badges: [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
            HeaderBreadcrumb(label: 'GL Segments', onTap: _goList),
            HeaderBreadcrumb(
                label: _activeSegment != null
                    ? 'Edit GL Segment'
                    : 'Create GL Segment'),
          ],
          onBack: _goList,
        ),
        Expanded(
          child: _AddEditForm(
            key: ValueKey(_activeSegment?.id ?? 'new'),
            editingSegment: _activeSegment,
            glMasters: _glMasters,
            preselectedGlMaster:
                _activeSegment == null ? _selectedGlMaster : null,
            onSave: _onSave,
            onCancel: _goList,
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIST PAGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildListPage() {
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
          actions: [
            AmsButton(
              label: 'Add New',
              icon: Icons.add_rounded,
              small: true,
              onPressed: () => _goEdit(null),
            ),
          ],
        ),
        Expanded(child: _buildListBody()),
      ]),
    );
  }

  Widget _buildListBody() {
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
            // ── GL Account Dropdown (from API) ───────────────────────────
            const Text('* Select GL Account',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextMid)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kCardBorder, width: 1.5),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: kTextLight),
                  const SizedBox(width: 8),
                  const Text('No GL Accounts found. Please add from GL Master.',
                      style: TextStyle(color: kTextLight, fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadGlMasters,
                    child: const Icon(Icons.refresh, size: 16, color: kNavy),
                  ),
                ]),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kCardBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _selectedGlMaster,
                    isExpanded: true,
                    style: const TextStyle(color: kTextMid, fontSize: 14),
                    icon:
                        const Icon(Icons.keyboard_arrow_down, color: kTextMid),
                    items: _glMasters.map((gl) {
                      final glNo = gl['glNo']?.toString() ?? '';
                      final glName = gl['glName']?.toString() ?? '';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: gl,
                        child: Text('GL $glNo — $glName'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedGlMaster = v),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── Search + Refresh ─────────────────────────────────────────
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
              // Refresh button — reloads from API
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kCardBorder, width: 1.5),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _loadGlSegments();
                  },
                  icon: const Icon(Icons.refresh, color: kNavy, size: 20),
                ),
              ),
            ]),

            const SizedBox(height: 10),

            // ── Segment count / loading / error ──────────────────────────
            if (_loadingSegments)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_segmentsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(children: [
                    const Icon(Icons.error_outline,
                        color: kInvalidRed, size: 32),
                    const SizedBox(height: 10),
                    Text(_segmentsError!,
                        style: const TextStyle(color: kTextMid, fontSize: 13)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadGlSegments,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ]),
                ),
              )
            else ...[
              Text('Showing 1–${filtered.length} of ${_segments.length}',
                  style: const TextStyle(fontSize: 12, color: kTextLight)),
              const SizedBox(height: 14),

              // ── Segment rows ───────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kCardBorder, width: 1.4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No segments found.',
                                style:
                                    TextStyle(color: kTextLight, fontSize: 14)),
                          ),
                        )
                      : Column(
                          children: filtered
                              .asMap()
                              .entries
                              .map((entry) => _hierarchyRow(entry.value,
                                  entry.key == filtered.length - 1))
                              .toList(),
                        ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ─── Segment Row ──────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                if (seg.glNo != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('GL ${seg.glNo}',
                        style: const TextStyle(
                            color: kBlueMid,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                ],
                SizedBox(
                  width: 90,
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
                  width: 54,
                  child: Text(seg.type,
                      style: const TextStyle(fontSize: 12, color: kTextLight)),
                ),
                const SizedBox(width: 12),
                _iconBtn(
                  icon: Icons.visibility_outlined,
                  iconColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                  onTap: () => _goView(seg),
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  icon: Icons.edit_outlined,
                  iconColor: kBlueMid,
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () => _goEdit(seg),
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  icon: Icons.delete_outline,
                  iconColor: kInvalidRed,
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: () => _deleteSegment(seg),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }
}

// ─── Add / Edit Form ──────────────────────────────────────────────────────────

class _AddEditForm extends StatefulWidget {
  final Segment? editingSegment;
  final List<Map<String, dynamic>> glMasters;
  final Map<String, dynamic>? preselectedGlMaster;
  final Future<void> Function(
    String level,
    String segId,
    String segValue,
    bool isActive,
    int glNo,
    String glName,
    int orgCode,
  ) onSave;
  final VoidCallback onCancel;

  const _AddEditForm({
    super.key,
    required this.editingSegment,
    required this.glMasters,
    required this.onSave,
    required this.onCancel,
    this.preselectedGlMaster,
  });

  @override
  State<_AddEditForm> createState() => _AddEditFormState();
}

class _AddEditFormState extends State<_AddEditForm> {
  // GL Name removed from UI — read internally from selected GL master
  late TextEditingController _orgCodeCtrl;
  late TextEditingController _segIdCtrl;
  late TextEditingController _segValueCtrl;

  Map<String, dynamic>? _selectedGlMaster;
  String? _selectedLevel;
  bool? _selectedActive;

  bool? _orgCodeValid;
  bool? _glNoValid;
  bool? _segIdValid;
  bool? _segValueValid;
  bool? _levelValid;
  bool? _activeValid;
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seg = widget.editingSegment;

    if (seg != null) {
      _selectedGlMaster = widget.glMasters.firstWhere(
        (m) => m['glNo'].toString() == seg.glNo?.toString(),
        orElse: () => {},
      );
      if (_selectedGlMaster!.isEmpty) _selectedGlMaster = null;
      _orgCodeCtrl = TextEditingController();
      _segIdCtrl = TextEditingController(text: seg.segmentId);
      _segValueCtrl = TextEditingController(text: seg.segmentValue);
      _selectedLevel = seg.level;
      _selectedActive = seg.isActive;
      _orgCodeValid = _glNoValid =
          _segIdValid = _segValueValid = _levelValid = _activeValid = true;
    } else {
      _selectedGlMaster = widget.preselectedGlMaster;
      _orgCodeCtrl = TextEditingController();
      _segIdCtrl = TextEditingController();
      _segValueCtrl = TextEditingController();
      _selectedLevel = null;
      _selectedActive = null;
    }
  }

  @override
  void dispose() {
    _orgCodeCtrl.dispose();
    _segIdCtrl.dispose();
    _segValueCtrl.dispose();
    super.dispose();
  }

  void _onGlChanged(Map<String, dynamic>? gl) {
    setState(() {
      _selectedGlMaster = gl;
      _glNoValid = gl != null;
    });
  }

  void _validateOrgCode(String v) =>
      setState(() => _orgCodeValid = v.trim().isNotEmpty);
  void _validateSegId(String v) =>
      setState(() => _segIdValid = v.trim().isNotEmpty);
  void _validateSegValue(String v) =>
      setState(() => _segValueValid = v.trim().isNotEmpty);
  void _validateLevel(String? v) => setState(() {
        _selectedLevel = v;
        _levelValid = v != null;
      });
  void _validateActive(String? v) => setState(() {
        _selectedActive = v == 'Active';
        _activeValid = v != null;
      });

  bool _validateAll() {
    setState(() {
      _submitted = true;
      _orgCodeValid = _orgCodeCtrl.text.trim().isNotEmpty;
      _glNoValid = _selectedGlMaster != null;
      _segIdValid = _segIdCtrl.text.trim().isNotEmpty;
      _segValueValid = _segValueCtrl.text.trim().isNotEmpty;
      _levelValid = _selectedLevel != null;
      _activeValid = _selectedActive != null;
    });
    return _orgCodeValid! &&
        _glNoValid! &&
        _segIdValid! &&
        _segValueValid! &&
        _levelValid! &&
        _activeValid!;
  }

  void _clear() => setState(() {
        _orgCodeCtrl.clear();
        _segIdCtrl.clear();
        _segValueCtrl.clear();
        _selectedGlMaster = null;
        _selectedLevel = null;
        _selectedActive = null;
        _orgCodeValid = _glNoValid =
            _segIdValid = _segValueValid = _levelValid = _activeValid = null;
        _submitted = false;
      });

  InputBorder _borderFor(bool? valid, {bool isFocused = false}) {
    if (valid == null)
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: isFocused ? kNavy.withOpacity(0.5) : kCardBorder),
      );
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color:
            valid ? kValidGreen.withOpacity(0.5) : kInvalidRed.withOpacity(0.5),
      ),
    );
  }

  Widget _errorMsg(String msg, bool? valid) => valid == false
      ? Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(msg,
              style: const TextStyle(fontSize: 12, color: kInvalidRed)),
        )
      : const SizedBox(height: 18);

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
                final halfWidth = (constraints.maxWidth - 24) / 2;

                InputDecoration dec(String hint, bool? valid) =>
                    InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                          color: Color(0xFFCBD5E1), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: _borderFor(valid),
                      enabledBorder: _borderFor(valid),
                      focusedBorder: _borderFor(valid, isFocused: true),
                    );

                // ── GL Name field removed — 5 fields remain ──────────────
                final fields = [
                  _field(
                    'Org Code',
                    TextField(
                      controller: _orgCodeCtrl,
                      onChanged: _validateOrgCode,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: dec('e.g. 50', _orgCodeValid),
                    ),
                    info: 'Organization Code',
                    errorWidget: _errorMsg('Org Code is required',
                        _submitted ? _orgCodeValid : null),
                  ),
                  _field(
                    'GL No.',
                    widget.glMasters.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5FB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kCardBorder),
                            ),
                            child: const Text('No GL Accounts available',
                                style:
                                    TextStyle(color: kTextLight, fontSize: 14)),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedGlMaster,
                            isExpanded: true,
                            hint: const Text('Select GL Account',
                                style: TextStyle(
                                    color: Color(0xFFCBD5E1), fontSize: 14)),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              filled: true,
                              fillColor: Colors.white,
                              border:
                                  _borderFor(_submitted ? _glNoValid : null),
                              enabledBorder:
                                  _borderFor(_submitted ? _glNoValid : null),
                              focusedBorder:
                                  _borderFor(_glNoValid, isFocused: true),
                            ),
                            style:
                                const TextStyle(color: kTextDark, fontSize: 14),
                            items: widget.glMasters.map((gl) {
                              final glNo = gl['glNo']?.toString() ?? '';
                              final glName = gl['glName']?.toString() ?? '';
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: gl,
                                child: Text('$glNo — $glName',
                                    style: const TextStyle(
                                        color: kTextDark, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: _onGlChanged,
                          ),
                    info: 'Select GL Account from GL Master',
                    errorWidget: _errorMsg(
                        'GL No. is required', _submitted ? _glNoValid : null),
                  ),
                  _field(
                    'Segment Type',
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      hint: const Text('Select type',
                          style: TextStyle(
                              color: Color(0xFFCBD5E1), fontSize: 14)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
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
                      onChanged: _validateSegId,
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: dec('e.g. DEPT, COSTCTR', _segIdValid),
                    ),
                    info: 'Unique identifier for the segment',
                    errorWidget:
                        _errorMsg('Segment ID is required', _segIdValid),
                  ),
                  _field(
                    'Segment Value',
                    TextField(
                      controller: _segValueCtrl,
                      onChanged: _validateSegValue,
                      style: const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: dec('e.g. Finance, Payroll', _segValueValid),
                    ),
                    info: 'Display value or description',
                    errorWidget:
                        _errorMsg('Segment Value is required', _segValueValid),
                  ),
                  _field(
                    'Status',
                    DropdownButtonFormField<String>(
                      initialValue: _selectedActive == null
                          ? null
                          : (_selectedActive! ? 'Active' : 'Inactive'),
                      hint: const Text('Active / Inactive',
                          style: TextStyle(
                              color: Color(0xFFCBD5E1), fontSize: 14)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
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
                                .map(
                                    (f) => SizedBox(width: halfWidth, child: f))
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
                        // Save button with loading state
                        ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (_validateAll()) {
                                    setState(() => _saving = true);
                                    final glNo = _selectedGlMaster!['glNo'];
                                    final glName = _selectedGlMaster!['glName']
                                            ?.toString() ??
                                        '';
                                    final orgCode = int.tryParse(
                                            _orgCodeCtrl.text.trim()) ??
                                        50;
                                    await widget.onSave(
                                      _selectedLevel!,
                                      _segIdCtrl.text.trim(),
                                      _segValueCtrl.text.trim(),
                                      _selectedActive ?? true,
                                      glNo is int
                                          ? glNo
                                          : int.tryParse(glNo.toString()) ?? 0,
                                      glName,
                                      orgCode,
                                    );
                                    if (mounted) {
                                      setState(() => _saving = false);
                                    }
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
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
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
                          onPressed: _saving ? null : _clear,
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
                          onPressed: _saving ? null : widget.onCancel,
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
