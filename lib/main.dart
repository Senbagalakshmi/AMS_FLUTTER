import 'package:ams_flutter/screens/user_access_screen.dart';
import 'package:ams_flutter/screens/gl_segments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'config/app_config.dart';
import 'screens/gl_allowed_branch_screen.dart';
import 'screens/gl_allowed_currency_screen.dart';
import 'services/api_service.dart';
import 'services/menu_api_service.dart';
import 'services/gl_api_service.dart';
import 'services/branch_api_service.dart';
import 'theme.dart';
import 'data.dart';
import 'models/models.dart';
import 'widgets/widgets.dart';
import 'screens/login_screen.dart';
import 'screens/select_type_screen.dart';
import 'screens/tran_entry_screen.dart';
import 'screens/nontran_entry_screen.dart';
import 'screens/program_list_screen.dart';
import 'screens/gl_category_screen.dart';
import 'screens/gl_master_screen.dart';
import 'screens/submenu_dashboard_screen.dart';
import 'screens/gl_attribute_screen.dart';
import 'screens/nontran_auth_screen.dart';
import 'screens/auth_config_screen.dart';
import 'screens/modal_queue_direct.dart';
import 'screens/organisation_screen.dart';
import 'screens/branch_screen.dart';
import 'screens/gl_dashboard_screen.dart';
import 'screens/program_master_screen.dart';
import 'screens/menu_master_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.getInstance();
  runApp(const AmsApp());
}

class AmsApp extends StatelessWidget {
  const AmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMS - Finance Management System',
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
    // Start on splash – it resolves to 'list' (SSO) or 'login' (manual)
    screen: 'splash',
    queue: seedQueue(),
    authQueue: const [],
    authConfigs: auth101,
  );

  // Pending modal data
  String? _modalProg;
  Auth101Config? _modalCfg;
  String? _modalAuthsl;
  String? _modalAmount;

  void _navigate(String screen) {
    setState(() {
      _state = _state.copyWith(
        screen: screen,
        clearProg: screen == 'list' || screen == 'login',
        clearCategory: screen == 'list' || screen == 'login',
      );
    });
    // Keep browser URL in sync: /finance for app, / for login
    if (kIsWeb) {
      if (screen == 'login') {
        html.window.history.pushState(null, '', '/');
      } else if (screen == 'list') {
        html.window.history.pushState(null, '', '/finance');
      }
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _state = _state.copyWith(isLoadingAuth: true);
      });
    }

    try {
      final configs = await apiService.getAuthConfigs();
      // Reduced size from 2000 to 100 for faster initial load
      final result = await apiService.getAuthQueue(size: 100);

      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            authConfigs: configs,
            authQueue: result?.items ?? [],
            authQueueTotal: result?.totalElements ?? 0,
            isLoadingAuth: false,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(isLoadingAuth: false);
        });
      }
    }
  }

  Future<void> _fetchModuleCounts() async {
    final glApi = GLApiService();
    try {
      final results = await Future.wait([
        apiService.getAllGlCategories(),
        apiService.getAllGlMasters(),
        glApi.getGl103List(),
        glApi.getGl104List(),
        glApi.getAllGlSegments(),
        GLApiService.getAllGlAttributes(),
      ]);

      final catsRes = results[0] as PaginatedResult<Map<String, dynamic>>?;
      final mastsRes = results[1] as PaginatedResult<Map<String, dynamic>>?;
      final curs = results[2] as List<dynamic>?;
      final brns = results[3] as List<dynamic>?;
      final segs = results[4] as List<dynamic>?;
      final atts = results[5] as List<dynamic>?;

      final newCounts = {
        'GL-CAT': catsRes?.totalElements ?? 0,
        'GL-MST': mastsRes?.totalElements ?? 0,
        'GL-CUR': curs?.length ?? 0,
        'GL-BRN': brns?.length ?? 0,
        'GL-SEG': segs?.length ?? 0,
        'GL-ATT': atts?.length ?? 0,
      };

      if (mounted) {
        setState(() {
          _state = _state.copyWith(counts: newCounts);
        });
      }
    } catch (e) {
      print('Error fetching counts: $e');
    }
  }

  void _handleLogin(String token, String userName) {
    apiService.updateToken(token);
    menuApiService.updateToken(token);
    setState(() => _state = _state.copyWith(
          screen: 'list',
          token: token,
          userName: userName,
        ));
    // Push /finance to browser URL so dashboard has its own address
    if (kIsWeb) {
      html.window.history.pushState(null, '', '/finance');
    }
    _refreshData();
    _fetchModuleCounts();
    _toast('Ã¢Å“â€¦', 'Authentication Successful  Welcome back!');
  }

  void _handleProceed(String type) {
    if (['MASTERS', 'GL', 'CONFIG', 'AUTH'].contains(type)) {
      setState(() {
        _state = _state.copyWith(
          screen: 'submenu_dashboard',
          selectedCategory: type,
          selectedProg: type,
        );
      });
      _fetchModuleCounts(); // Fetch latest counts when entering dashboard
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

  void _handleNonTranSubmit(String prog, Auth101Config cfg, String authsl,
      Map<String, dynamic> data) async {
    bool success = false;

    // Choose API method based on program
    if (prog == 'USR-CRT') {
      success = await apiService.createUser(data);
    } else if (prog == 'ROLE-CRT') {
      success = await apiService.createRole(data);
    } else if (prog == 'MOD-CRT') {
      success = await apiService.createModule(data);
    } else if (prog == 'MENU-CRT' || prog == 'MENU-MST') {
      success = await menuApiService.createMenu('program', data);
    } else if (prog == 'USR-ACCESS') {
      success = await apiService.assignUserRole(data);
    } else if (prog == 'USR-ROLE') {
      success = await apiService.assignUserRole(data);
    } else if (prog == 'BRN-CRT') {
      success = await branchApiService.createBranch(data);
    } else if (prog == 'AUTHCTL') {
      success = await apiService.createAuthConfig(data);
    } else {
      // Mock success for other non-tran programs for now
      success = true;
    }

    if (!mounted) return;

    if (success) {
      if (cfg.approvalReq) {
        showAmsSnack(context, 'Submitted for Authorization: $authsl',
            type: 's');
      } else {
        showAmsSnack(context, 'Record saved directly: $authsl', type: 's');
      }
      _refreshData();
    } else {
      showAmsSnack(context, 'Failed to save record.', type: 'e');
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
          ? 'Ã¢â€šÂ¹${_formatIndian(amount)}'
          : '',
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
    _toast('Ã°Å¸â€œÂ¥', '$authsl submitted routed to L1 authorization queue!');
  }

  Future<void> _handleAuthProcess(AuthRecord record, bool isApprove) async {
    final action = isApprove ? 'approve' : 'reject';

    int level = 1;
    if (record.flUser != null &&
        record.flUser != '0' &&
        record.flUser!.trim().isNotEmpty) {
      level = 2;
    }
    if (record.slUser != null &&
        record.slUser != '0' &&
        record.slUser!.trim().isNotEmpty) {
      level = 3;
    }
    final userId = _state.userName ?? 'SYSTEM';

    final success =
        await apiService.processAuth(record.authSl, action, level, userId);

    if (success) {
      _toast(isApprove ? 'Ã¢Å“â€¦' : 'Ã¢ÂÅ’',
          'Request ${record.authSl} ${isApprove ? 'authorized' : 'rejected'} successfully!');
      _refreshData();
    } else {
      _toast('Ã¢Å¡Â Ã¯Â¸Â', 'Failed to process authorization request.');
    }
  }

  Future<void> _handleAuthCorrection(AuthRecord record, String remarks) async {
    final level = (record.flUser == null || record.flUser == '0')
        ? 1
        : (record.slUser == null || record.slUser == '0')
            ? 2
            : 3;

    final success = await apiService.requestCorrection(
        record.authSl, level, _state.userName ?? 'SYSTEM', remarks);

    if (success) {
      _toast('Ã°Å¸â€â€ž', 'Record sent for correction');
      _refreshData();
    } else {
      _toast('Ã¢Å¡Â Ã¯Â¸Â', 'Failed to send for correction');
    }
  }

  Future<void> _handleAuthLock(AuthRecord record) async {
    final userId = _state.userName ?? 'SYSTEM';
    final status = await apiService.updateAuthLock(record.authSl, userId);

    if (status == 409) {
      _toast('Ã°Å¸â€â€™', 'Record is already locked by another user.',
          type: 'w');
    } else if (status != 200) {
      _toast('Ã¢Å¡Â Ã¯Â¸Â', 'Failed to acquire review lock (Status: $status)',
          type: 'e');
    }
  }

  void _handleConfigUpdate(String id, Auth101Config newCfg) {
    setState(() {
      final newConfigs = Map<String, Auth101Config>.from(_state.authConfigs);
      newConfigs[id] = newCfg;
      _state = _state.copyWith(authConfigs: newConfigs);
    });
    _toast('Ã¢Å¡â„¢Ã¯Â¸Â', 'Configuration for $id updated');
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
    _toast('Ã¢Å“â€¦', 'Saved directly  no authorization required!');
  }

  void _handleNewEntry() {
    setState(() => _state =
        _state.copyWith(screen: 'list', clearProg: true, clearSubmitted: true));
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
        showAmsSnack(context, msg, type: type);
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
      // ── Splash / SSO entry point ─────────────────────────────────────────
      case 'splash':
        body = SplashScreen(
          onLoginSuccess: (token, userName) {
            // Exchange succeeded – treat exactly like a successful manual login
            _handleLogin(token, userName);
          },
          onGoToLogin: () {
            setState(() => _state = _state.copyWith(screen: 'login'));
          },
        );

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
        if (_state.selectedProg == 'GL-CAT') {
          body = GLCategoryScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('GL'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'GL-MST') {
          body = GLMasterScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('GL'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'GL-ATT') {
          body = GLAttributeScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('GL'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'GL-CUR') {
          body = AllowedCurrencyScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('GL'),
            onChanged: (k, v) {},
          );
        } else if (_state.selectedProg == 'GL-BRN') {
          body = AllowedBranchScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('GL'),
            onChanged: (k, v) {},
          );
        } else if (_state.selectedProg == 'GL-SEG') {
          body = GlSegmentsScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('GL'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'ORG-CRT') {
          body = OrganisationScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('MASTERS'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'BRN-CRT') {
          body = BranchScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('MASTERS'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'USR-ACCESS') {
          body = UserAccessScreen(
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('MASTERS'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'PROG-CRT') {
          body = ProgramMasterScreen(
            authConfigs: _state.authConfigs,
            initialProg: _state.selectedProg,
            onSubmit: _handleNonTranSubmit,
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('MASTERS'),
            userName: _state.userName,
          );
        } else if (_state.selectedProg == 'MENU-MST') {
          body = MenuMasterScreen(
            authConfigs: _state.authConfigs,
            onBack: () => _navigate('list'),
            onBackToModule: () => _handleProceed('MASTERS'),
            userName: _state.userName,
          );
        } else {
          body = NonTranEntryScreen(
            authConfigs: _state.authConfigs,
            nonTranPrograms: nonTranPrograms,
            initialProg: _state.selectedProg,
            onSubmit: _handleNonTranSubmit,
            onBack: () => _navigate('list'),
            userName: _state.userName,
          );
        }
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
          authQueue: _state.authQueue,
          totalRecords: _state.authQueueTotal,
          isLoading: _state.isLoadingAuth,
          onRefresh: _refreshData,
          onProcess: _handleAuthProcess,
          onCorrection: _handleAuthCorrection,
          onLock: _handleAuthLock,
          onBack: () => _navigate('list'),
          userName: _state.userName,
          authConfigs: _state.authConfigs,
        );
        break;

      case 'auth_config':
        body = AuthConfigScreen(
          configs: _state.authConfigs,
          onUpdate: _handleConfigUpdate,
          onBack: () => _navigate('list'),
          userName: _state.userName,
        );
      case 'submenu_dashboard':
        final cat = _state.selectedCategory;
        String title = 'Dashboard';
        List<SubmenuItem> items = [];

        if (cat == 'MASTERS') {
          title = 'Masters';
          items = mastersSubmenus;
        } else if (cat == 'GL') {
          title = 'GL Module';
          items = glSubmenus.map((item) {
            final count = _state.counts[item.programId] ?? 0;
            String metric = item.metric ?? '';

            if (item.programId == 'GL-CAT')
              metric = '$count Cat';
            else if (item.programId == 'GL-MST')
              metric = '$count Mast';
            else if (item.programId == 'GL-SUB')
              metric = '4 Modules';
            
            return item.copyWith(metric: metric);
          }).toList();
        } else if (cat == 'GL-SUB') {
          title = 'Sub Category';
          items = glSubCategorySubmenus.map((item) {
            final count = _state.counts[item.programId] ?? 0;
            String metric = item.metric ?? '';

            if (item.programId == 'GL-CUR')
              metric = '$count Cur';
            else if (item.programId == 'GL-BRN')
              metric = '$count Br';
            else if (item.programId == 'GL-SEG')
              metric = '$count Seg';
            else if (item.programId == 'GL-ATT') metric = '$count Attr';

            return item.copyWith(metric: metric);
          }).toList();
        } else if (cat == 'CONFIG') {
          title = 'Configuration';
          items = configSubmenus;
        } else if (cat == 'AUTH') {
          title = 'Authorization';
          items = authSubmenus.map((item) {
            if (item.programId == 'nontranauth') {
              return item.copyWith(metric: '${_state.authQueue.length} Pend');
            }
            return item;
          }).toList();
        }

        if (cat == 'GL') {
          body = GlDashboardScreen(
            items: glSubmenus.map((item) {
              final count = _state.counts[item.programId] ?? 0;
              String metric = item.metric ?? '';

              if (item.programId == 'GL-CAT')
                metric = '$count Cat';
              else if (item.programId == 'GL-MST')
                metric = '$count Mast';
              else if (item.programId == 'GL-SUB')
                metric = '4 Modules';

              return item.copyWith(metric: metric);
            }).toList(),
            userName: _state.userName,
            onBack: () => _navigate('list'),
            onNavigate: (s, p) {
              setState(() {
                _state = _state.copyWith(
                  screen: s,
                  selectedProg: p,
                  selectedType: p != null
                      ? (tranPrograms.contains(p) ? 'T' : 'N')
                      : _state.selectedType,
                  clearCategory: true,
                );
              });
            },
          );
        } else {
          body = SubmenuDashboardScreen(
            title: title,
            items: items,
            onBack: () => _navigate('list'),
            onNavigate: (s, p) {
              setState(() {
                _state = _state.copyWith(
                  screen: s,
                  selectedProg: p,
                  selectedType: p != null
                      ? (tranPrograms.contains(p) ? 'T' : 'N')
                      : _state.selectedType,
                  clearCategory: true,
                );
              });
            },
          );
        }
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

            // Handle category navigation
            String? cat;
            if (s == 'submenu_dashboard') {
              cat = p; // Category name (e.g. 'GL')
              // Keep p as category ID for sidebar selection logic
            }

            setState(() {
              _state = _state.copyWith(
                screen: s,
                selectedProg: p,
                selectedCategory: cat,
                clearCategory: cat == null,
                selectedType: p != null
                    ? (tranPrograms.contains(p) ? 'T' : 'N')
                    : _state.selectedType,
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
