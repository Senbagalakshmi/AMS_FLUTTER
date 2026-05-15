import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/gl_api_service.dart';
import '../services/journal_api_service.dart';

class AuthorizationScreen extends StatefulWidget {
  final List<AuthRecord> authQueue;
  final void Function(AuthRecord, bool isApprove) onProcess;
  final VoidCallback onBack;
  final String? userName;

  const AuthorizationScreen({
    super.key,
    required this.authQueue,
    required this.onProcess,
    required this.onBack,
    this.userName,
  });

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  AuthRecord? _selectedRecord;
  List<Map<String, dynamic>> _fetchedDetails = [];
  bool _isFetchingDetails = false;

  @override
  void initState() {
    super.initState();
    _primeCache();
  }

  Future<void> _primeCache() async {
    try {
      final glApi = GLApiService();
      await Future.wait([glApi.getGlList(), glApi.getGl104List()]);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _onRecordSelected(AuthRecord record) async {
    setState(() {
      _selectedRecord = record;
      _fetchedDetails = [];
      _isFetchingDetails = true;
    });

    try {
      final header = record.details ?? {};
      final orgCode = int.tryParse((header['orgcode'] ?? header['ORGCODE'] ?? '50').toString()) ?? 50;
      final dateStrRaw = (header['trandate'] ?? header['TRANDATE'] ?? '').toString();
      final dateStr = dateStrRaw.split('T').first.split(' ').first;
      final tranId = int.tryParse((header['tranid'] ?? header['TRANID'] ?? '0').toString()) ?? 0;

      if (dateStr.isNotEmpty && tranId > 0) {
        final details = await journalApiService.getJournalDetails(orgCode, dateStr, tranId);
        if (mounted) {
          setState(() {
            _fetchedDetails = details ?? [];
            _isFetchingDetails = false;
          });
        }
      } else {
        setState(() => _isFetchingDetails = false);
      }
    } catch (e) {
      print('Detail Fetch Error: $e');
      if (mounted) setState(() => _isFetchingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Panel: Queue List
                Container(
                  width: 400,
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pending Requests', style: bodyStyle(size: 18, weight: FontWeight.w800)),
                            AmsBadge(label: '${widget.authQueue.length}', color: AppColors.amber, background: AppColors.amberLt),
                          ],
                        ),
                      ),
                      Expanded(
                        child: widget.authQueue.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                itemCount: widget.authQueue.length,
                                itemBuilder: (ctx, i) {
                                  final rec = widget.authQueue[i];
                                  return _AuthQueueItem(
                                    record: rec,
                                    isSelected: _selectedRecord == rec,
                                    onTap: () => _onRecordSelected(rec),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Right Panel: Details
                Expanded(
                  child: _selectedRecord == null
                      ? _buildNoSelection()
                      : _AuthDetailView(
                          record: _selectedRecord!,
                          fetchedDetails: _fetchedDetails,
                          isLoading: _isFetchingDetails,
                          onApprove: () => widget.onProcess(_selectedRecord!, true),
                          onReject: () => widget.onProcess(_selectedRecord!, false),
                        ),
                ),
              ],
            ),
          ),
          AmsSubmitBar(
            borderColor: AppColors.tBlue,
            actions: [
              AmsButton(label: 'Close Queue', variant: AmsButtonVariant.outline, onPressed: widget.onBack),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('No pending requests'));
  Widget _buildNoSelection() => const Center(child: Text('Select a request to review'));
}

class _AuthQueueItem extends StatelessWidget {
  final AuthRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthQueueItem({required this.record, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      onTap: onTap,
      title: Text(record.title, style: bodyStyle(weight: FontWeight.bold)),
      subtitle: Text(record.subtitle, style: bodyStyle(size: 12, color: AppColors.ink3)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _AuthDetailView extends StatelessWidget {
  final AuthRecord record;
  final List<Map<String, dynamic>> fetchedDetails;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AuthDetailView({required this.record, required this.fetchedDetails, required this.isLoading, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Expanded(child: Text('Review Transaction', style: bodyStyle(size: 16, weight: FontWeight.w800))),
              Row(
                children: [
                  AmsButton(label: 'Reject', variant: AmsButtonVariant.danger, onPressed: onReject),
                  const SizedBox(width: 12),
                  AmsButton(label: 'Approve', variant: AmsButtonVariant.primary, onPressed: onApprove),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: JournalDetailsView(
                    header: record.details ?? {},
                    details: fetchedDetails,
                  ),
                ),
        ),
      ],
    );
  }
}
