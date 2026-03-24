import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'theme.dart';
import 'data.dart';
import 'models/models.dart';
import 'widgets/widgets.dart';
import 'screens/login_screen.dart';
import 'screens/select_type_screen.dart';
import 'screens/tran_entry_screen.dart';
import 'screens/nontran_entry_screen.dart';
import 'screens/program_list_screen.dart';

import 'screens/nontran_auth_screen.dart';
import 'screens/auth_config_screen.dart';
import 'screens/modal_queue_direct.dart';

void main() {
  runApp(const AmsApp());
}

class AmsApp extends StatelessWidget {
  const AmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS — Authorization Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AmsRoot(),
    );
  }
}

class AmsRoot extends StatefulWidget {
  const AmsRoot({super.key});

  @override
  State<AmsRoot> createState() => _AmsRootState();
}

class _AmsRootState extends State<AmsRoot> {
  AppState _state = AppState(
    screen: 'login',
    queue: seedQueue(),
    authQueue: seedAuthQueue(),
    authConfigs: auth101,
  );

  // Pending modal data
  String? _modalProg;
  Auth101Config? _modalCfg;
  String? _modalAuthsl;
  String? _modalAmount;

  void _navigate(String screen) {
    setState(() => _state = _state.copyWith(screen: screen));
  }

  Future<void> _refreshData() async {
    final configs = await apiService.getAuthConfigs();
    final authQueue = await apiService.getAuthQueue();

    if (mounted) {
      setState(() {
        _state = _state.copyWith(
          authConfigs: configs,
          authQueue: authQueue,
        );
      });
    }
  }

  void _handleLogin(String token, String userName) {
    apiService.updateToken(token);
    setState(() => _state = _state.copyWith(
          screen: 'list',
          token: token,
          userName: userName,
        ));
    _refreshData();
    _toast('✅', 'Authentication Successful — Welcome back!');
  }

  void _handleProceed(String type) {
    if (type == 'AUTH') {
      setState(() => _state = _state.copyWith(screen: 'auth'));
      return;
    }
    if (type == 'AUTH_CONFIG') {
      setState(() => _state = _state.copyWith(screen: 'auth_config'));
      return;
    }
    setState(() => _state = _state.copyWith(
          screen: 'list',
          selectedType: type,
          clearProg: true,
        ));
  }

  void _handleSelectProg(String prog) {
    bool isTran = tranPrograms.contains(prog);
    setState(() => _state = _state.copyWith(
          screen: isTran ? 'tran' : 'nontran',
          selectedType: isTran ? 'T' : 'N',
          selectedProg: prog,
        ));
  }

  void _handleTranSubmit(
      String prog, Auth101Config cfg, String authsl, String amount) {
    setState(() {
      _modalProg = prog;
      _modalCfg = cfg;
      _modalAuthsl = authsl;
      _modalAmount = amount;
    });
  }

  void _handleNonTranSubmit(
      String prog, Auth101Config cfg, String authsl, Map<String, dynamic> data) async {
    bool success = false;
    
    // Choose API method based on program
    if (prog == 'USR-CRT') {
      success = await apiService.createUser(data);
    } else if (prog == 'ROLE-CRT') {
      success = await apiService.createRole(data);
    } else if (prog == 'MOD-CRT') {
      success = await apiService.createModule(data);
    } else if (prog == 'MENU-CRT') {
      success = await apiService.createMenu('program', data);
    } else if (prog == 'USR-ROLE') {
      success = await apiService.assignUserRole(data);
    } else if (prog == 'AUTHCTL') {
      success = await apiService.createAuthConfig(data);
    } else {
      // Mock success for other non-tran programs for now
      success = true; 
    }

    if (!mounted) return;

    if (success) {
      if (cfg.approvalReq) {
        showAmsToast(context, '🚀', 'Submitted for Authorization: $authsl',
            type: 's');
      } else {
        showAmsToast(context, '✅', 'Record saved directly: $authsl', type: 's');
      }
      _navigate('list');
      _refreshData();
    } else {
      showAmsToast(context, '❌', 'Failed to save record.', type: 'e');
    }
  }

  void _handleRouteQueue() {
    final prog = _modalProg!;
    final cfg = _modalCfg!;
    final authsl = _modalAuthsl!;
    final amount = _modalAmount;
    final type = _state.screen == 'tran' ? 'T' : 'N';

    final entry = QueueEntry(
      authsl: authsl,
      type: type,
      prog: prog,
      name: cfg.name,
      user: '${_state.userName ?? 'User'} (You)',
      date: _shortDate(),
      amount: amount != null && amount.isNotEmpty
          ? '₹${_formatIndian(amount)}'
          : '—',
      level: 'L1',
      risk: false,
      locked: false,
      isNew: true,
    );

    setState(() {
      _state = _state.copyWith(
        screen: 'queue',
        queue: [entry, ..._state.queue],
        lastSubmitted: entry,
      );
      _modalProg = null;
      _modalCfg = null;
      _modalAuthsl = null;
      _modalAmount = null;
    });
    _toast('📥', '$authsl submitted — routed to L1 authorization queue!');
  }

  Future<void> _handleAuthProcess(AuthRecord record, bool isApprove) async {
    final action = isApprove ? 'approve' : 'reject';
    
    int level = 1;
    if (record.flUser != null && record.flUser != '0' && record.flUser!.trim().isNotEmpty) level = 2;
    if (record.slUser != null && record.slUser != '0' && record.slUser!.trim().isNotEmpty) level = 3;
    final userId = _state.userName ?? 'SYSTEM';

    final success = await apiService.processAuth(record.authSl, action, level, userId);
    if (success) {
      _toast(isApprove ? '✅' : '❌',
          'Request ${record.authSl} ${isApprove ? 'authorized' : 'rejected'} successfully!');
      _refreshData();
    } else {
      _toast('⚠️', 'Failed to process authorization request.');
    }
  }

  void _handleConfigUpdate(String id, Auth101Config newCfg) {
    setState(() {
      final newConfigs = Map<String, Auth101Config>.from(_state.authConfigs);
      newConfigs[id] = newCfg;
      _state = _state.copyWith(authConfigs: newConfigs);
    });
    _toast('⚙️', 'Configuration for $id updated');
  }

  void _handleRouteDirect() {
    final prog = _modalProg!;
    setState(() {
      _state = _state.copyWith(
        screen: 'direct',
        selectedProg: prog,
        lastSubmitted: null,
      );
      _modalProg = null;
      _modalCfg = null;
      _modalAuthsl = null;
      _modalAmount = null;
    });
    _toast('✅', 'Saved directly — no authorization required!');
  }

  void _handleNewEntry() {
    setState(() => _state = _state.copyWith(
        screen: 'list', clearProg: true, clearSubmitted: true));
  }

  void _closeModal() {
    setState(() {
      _modalProg = null;
      _modalCfg = null;
      _modalAuthsl = null;
      _modalAmount = null;
    });
  }

  void _toast(String icon, String msg, {String type = 's'}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showAmsToast(context, icon, msg, type: type);
      }
    });
  }

  String _shortDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)}';
  }

  String _formatIndian(String val) {
    final n = double.tryParse(val);
    if (n == null) return val;
    // Simple Indian formatting
    final intPart = n.toInt().toString();
    if (intPart.length <= 3) return intPart;
    final last3 = intPart.substring(intPart.length - 3);
    final rest = intPart.substring(0, intPart.length - 3);
    final buf = StringBuffer(rest[0]);
    for (int i = 1; i < rest.length; i++) {
      if ((rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    return '${buf.toString()},$last3';
  }

  @override
  Widget build(BuildContext context) {
    final screen = _state.screen;
    final showModal = _modalProg != null;

    Widget body;
    switch (screen) {
      case 'login':
        body = LoginScreen(onLogin: _handleLogin);
      case 'select':
        body = SelectTypeScreen(
          onProceed: _handleProceed,
          userName: _state.userName,
        );
      case 'tran':
        body = TransactionEntryScreen(
          authConfigs: _state.authConfigs,
          tranPrograms: tranPrograms,
          initialProg: _state.selectedProg,
          onSubmit: _handleTranSubmit,
          onBack: () => _navigate('list'),
          userName: _state.userName,
        );
      case 'nontran':
        body = NonTranEntryScreen(
          authConfigs: _state.authConfigs,
          nonTranPrograms: nonTranPrograms,
          initialProg: _state.selectedProg,
          onSubmit: _handleNonTranSubmit,
          onBack: () => _navigate('list'),
          userName: _state.userName,
        );
      case 'list':
        body = ProgramListScreen(
          authConfigs: _state.authConfigs,
          tranPrograms: tranPrograms,
          nonTranPrograms: nonTranPrograms,
          onSelect: _handleSelectProg,
          onProceed: _handleProceed,
          onBack: () => _navigate('login'),
          userName: _state.userName,
        );
      case 'queue':
        body = QueueScreen(
          queue: _state.queue,
          lastSubmitted: _state.lastSubmitted,
          onNewEntry: _handleNewEntry,
          subType: _state.selectedType == 'T' ? 'Transaction' : 'Non-Txn',
          userName: _state.userName,
        );
      case 'direct':
        body = DirectSaveScreen(
          prog: _state.selectedProg ?? _modalProg ?? 'KYC-UPD',
          onNewEntry: _handleNewEntry,
          userName: _state.userName,
        );
      case 'nontranauth':
        body = NonTranAuthScreen(
          authQueue: _state.authQueue.where((r) {
            final cfg = _state.authConfigs[r.programId];
            return cfg != null && cfg.isTran == false;
          }).toList(),
          onProcess: _handleAuthProcess,
          onBack: () => _navigate('list'),
          userName: _state.userName,
        );
        break;

      case 'auth_config':
        body = AuthConfigScreen(
          configs: _state.authConfigs,
          onUpdate: _handleConfigUpdate,
          onBack: () => _navigate('list'),
          userName: _state.userName,
        );
      default:
        body = LoginScreen(onLogin: _handleLogin);
    }

    final isLogin = screen == 'login';

    if (isLogin) {
      return Stack(
        children: [
          LoginScreen(onLogin: _handleLogin),
          if (showModal)
            DecisionModal(
              prog: _modalProg!,
              cfg: _modalCfg!,
              authsl: _modalAuthsl!,
              onQueue: _handleRouteQueue,
              onDirect: _handleRouteDirect,
              onClose: _closeModal,
            ),
        ],
      );
    }

    return Stack(
      children: [
        AmsShell(
          currentScreen: screen,
          selectedProg: _state.selectedProg,
          userName: _state.userName,
          onNavigate: (s, p) {
            if (s == 'login') {
              _navigate('login');
              return;
            }
            setState(() {
              _state = _state.copyWith(
                screen: s,
                selectedProg: p,
                selectedType: p != null ? (tranPrograms.contains(p) ? 'T' : 'N') : _state.selectedType,
                clearProg: p == null,
              );
            });
          },
          child: body,
        ),
        if (showModal)
          DecisionModal(
            prog: _modalProg!,
            cfg: _modalCfg!,
            authsl: _modalAuthsl!,
            onQueue: _handleRouteQueue,
            onDirect: _handleRouteDirect,
            onClose: _closeModal,
          ),
      ],
    );
  }
}
