import 'models/models.dart';
import 'package:flutter/material.dart';
import 'screens/submenu_dashboard_screen.dart';

final Map<String, Auth101Config> auth101 = {
  'LOAN-DIS': const Auth101Config(
      id: 'LOAN-DIS',
      name: 'Loan Disbursement',
      approvalReq: true,
      isTran: true,
      levels: 3),
  'NEFT-TXN': const Auth101Config(
      id: 'NEFT-TXN',
      name: 'NEFT / Fund Transfer',
      approvalReq: true,
      isTran: true,
      levels: 2),
  'FD-OPEN': const Auth101Config(
      id: 'FD-OPEN',
      name: 'Fixed Deposit Opening',
      approvalReq: true,
      isTran: true,
      levels: 2),
  'RD-OPEN': const Auth101Config(
      id: 'RD-OPEN',
      name: 'Recurring Deposit',
      approvalReq: true,
      isTran: true,
      levels: 1),
  'USR-CRT': const Auth101Config(
      id: 'USR-CRT', name: 'User', approvalReq: true, isTran: false, levels: 1),
  'ROLE-CRT': const Auth101Config(
      id: 'ROLE-CRT',
      name: 'Role Creation',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'USR-ROLE': const Auth101Config(
      id: 'USR-ROLE',
      name: 'Role Assign',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'MOD-CRT': const Auth101Config(
      id: 'MOD-CRT',
      name: 'Module',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'MENU-CRT': const Auth101Config(
      id: 'MENU-CRT',
      name: 'Menu',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'ORG-CRT': const Auth101Config(
      id: 'ORG-CRT',
      name: 'Organisation',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'AUTHCTL': const Auth101Config(
      id: 'AUTHCTL',
      name: 'Auth Controller',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'nontranauth': const Auth101Config(
      id: 'nontranauth',
      name: 'Authorization',
      approvalReq: false,
      isTran: false,
      levels: 0),
  'GL-CAT': const Auth101Config(
      id: 'GL-CAT',
      name: 'GL Category',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-MST': const Auth101Config(
      id: 'GL-MST',
      name: 'GL Master',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-MAT': const Auth101Config(
      id: 'GL-MAT',
      name: 'GL Master',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-CUR': const Auth101Config(
      id: 'GL-CUR',
      name: 'Allowed Currency',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-BRN': const Auth101Config(
      id: 'GL-BRN',
      name: 'Allowed Branch',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-SEG': const Auth101Config(
      id: 'GL-SEG',
      name: 'GL Segments',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-ATT': const Auth101Config(
      id: 'GL-ATT',
      name: 'GL Attributes',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'GL-JRN': const Auth101Config(
      id: 'GL-JRN',
      name: 'Journals',
      approvalReq: true,
      isTran: true,
      levels: 2),
  'PROG-CRT': const Auth101Config(
      id: 'PROG-CRT',
      name: 'Program',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'MENU-MST': const Auth101Config(
      id: 'MENU-MST',
      name: 'Menu Master',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'BRN-CRT': const Auth101Config(
      id: 'BRN-CRT',
      name: 'Branch Master',
      approvalReq: true,
      isTran: false,
      levels: 1),
  'RPT-PL': const Auth101Config(
      id: 'RPT-PL',
      name: 'Profit and Loss',
      approvalReq: false,
      isTran: false,
      levels: 0),
  'RPT-TB': const Auth101Config(
      id: 'RPT-TB',
      name: 'Trial Balance',
      approvalReq: false,
      isTran: false,
      levels: 0),
  'RPT-BS': const Auth101Config(
      id: 'RPT-BS',
      name: 'Balance Sheet',
      approvalReq: false,
      isTran: false,
      levels: 0),
  'RPT-COA': const Auth101Config(
      id: 'RPT-COA',
      name: 'Chart of Accounts',
      approvalReq: false,
      isTran: false,
      levels: 0),
};

final Map<String, List<Auth103Limit>> auth103 = {
  'LOAN-DIS': [
    const Auth103Limit(
        from: 0, to: 100000, role: 'CLERK', approver: 'Clerk Level'),
    const Auth103Limit(
        from: 100001,
        to: 1000000,
        role: 'BRANCH_MGR',
        approver: 'Branch Manager'),
    const Auth103Limit(
        from: 1000001,
        to: 50000000,
        role: 'REGIONAL_MGR',
        approver: 'Regional Manager'),
  ],
  'NEFT-TXN': [
    const Auth103Limit(
        from: 0, to: 200000, role: 'CLERK', approver: 'Clerk Level'),
    const Auth103Limit(
        from: 200001,
        to: 2000000,
        role: 'BRANCH_MGR',
        approver: 'Branch Manager'),
  ],
  'FD-OPEN': [
    const Auth103Limit(
        from: 5000,
        to: 1000000,
        role: 'BRANCH_MGR',
        approver: 'Branch Manager'),
  ],
  'RD-OPEN': [
    const Auth103Limit(
        from: 1000, to: 100000, role: 'CLERK', approver: 'Clerk Level'),
  ],
};

const List<String> tranPrograms = [];
const List<String> nonTranPrograms = [];

final Map<String, String> tranProgPkPrefix = {
  'LOAN-DIS': 'LN',
  'NEFT-TXN': 'NT',
  'FD-OPEN': 'FD',
  'RD-OPEN': 'RD',
};

final Map<String, String> nonTranProgPkPrefix = {
  'USR-CRT': 'USR',
  'ROLE-CRT': 'ROL',
  'USR-ROLE': 'URA',
  'MOD-CRT': 'MOD',
  'MENU-CRT': 'MNU',
  'ORG-CRT': 'ORG',
  'AUTHCTL': 'ACTL',
  'nontranauth': 'NTA',
  'GL-CAT': 'GLC',
  'GL-MST': 'GLM',
  'GL-MAT': 'GLM',
  'GL-CUR': 'GLCU',
  'GL-BRN': 'GLB',
  'GL-SEG': 'GLS',
  'GL-ATT': 'GLA',
  'GL-JRN': 'JRN',
  'PROG-CRT': 'PRG',
  'MENU-MST': 'MNU',
  'BRN-CRT': 'BRN',
  'RPT-PL': 'RPL',
  'RPT-TB': 'RTB',
  'RPT-BS': 'RBS',
  'RPT-COA': 'RCA',
};

List<QueueEntry> seedQueue() => [
      QueueEntry(
          authsl: '2026-0041',
          type: 'T',
          prog: 'LOAN-DIS',
          name: 'Loan Disbursement',
          user: 'Priya R.',
          date: '10/03/26',
          amount: '₹4,50,000',
          level: 'L1',
          risk: false,
          locked: false,
          isNew: false),
      QueueEntry(
          authsl: '2026-0040',
          type: 'T',
          prog: 'FD-OPEN',
          name: 'Fixed Deposit',
          user: 'Ravi K.',
          date: '10/03/26',
          amount: '₹2,00,000',
          level: 'L1',
          risk: true,
          locked: false,
          isNew: false),
      QueueEntry(
          authsl: '2026-0039',
          type: 'T',
          prog: 'NEFT-TXN',
          name: 'NEFT Transfer',
          user: 'Sunita M.',
          date: '09/03/26',
          amount: '₹1,20,000',
          level: 'L2',
          risk: false,
          locked: false,
          isNew: false),
      QueueEntry(
          authsl: '2026-0038',
          type: 'N',
          prog: 'CASA-OPN',
          name: 'CASA Opening',
          user: 'Amit B.',
          date: '09/03/26',
          amount: '—',
          level: 'L1',
          risk: false,
          locked: true,
          isNew: false),
      QueueEntry(
          authsl: '2026-0037',
          type: 'N',
          prog: 'ADDR-UPD',
          name: 'Address Update',
          user: 'Neha P.',
          date: '08/03/26',
          amount: '—',
          level: 'L1',
          risk: false,
          locked: false,
          isNew: false),
      QueueEntry(
          authsl: '2026-0036',
          type: 'T',
          prog: 'NEFT-TXN',
          name: 'NEFT Transfer',
          user: 'Karan T.',
          date: '08/03/26',
          amount: '₹35,000',
          level: 'L1',
          risk: false,
          locked: false,
          isNew: false),
      QueueEntry(
          authsl: '2026-0035',
          type: 'N',
          prog: 'NOM-UPD',
          name: 'Nominee Update',
          user: 'Maya S.',
          date: '07/03/26',
          amount: '—',
          level: 'L2',
          risk: false,
          locked: false,
          isNew: false),
    ];
List<AuthRecord> seedAuthQueue() => [
      AuthRecord(
        orgCode: 'AMS001',
        effDate: '2026-03-11',
        programId: 'USR-CRT',
        primaryKey: 'USR_ARJUN_M',
        authSl: '2026-0001',
        displayRemarks: 'Creation of new clerk user Arjun Mehta',
        eUser: 'SYSTEM_ADMIN',
        eDate: '2026-03-11 10:30:00',
        flUser: '0',
        slUser: '0',
        tlUser: '0',
        dataBlocks: [
          AuthDataBlock(
            recSl: 1,
            tableName: 'USERS',
            data: {
              'ORGCODE': '50',
              'USERSCD': 'arjun_m',
              'MENUTYPE': '1 - Rolewise',
              'GENDER': 'Male',
              'TITLE': 'Mr.',
              'FNAME': 'Arjun',
              'MNAME': '',
              'LNAME': 'Mehta',
              'EMAIL': 'arjun.m@example.com',
              'MOBILE': '9876543210',
              'COUNTRY': 'IN',
            },
          ),
        ],
      ),
      AuthRecord(
        orgCode: 'AMS001',
        effDate: '2026-03-11',
        programId: 'ROLE-CRT',
        primaryKey: 'ASGN_ARJUN_10',
        authSl: '2026-0002',
        displayRemarks: 'Assigning Role 10 to user Arjun Mehta',
        eUser: 'HR_MNGR',
        eDate: '2026-03-11 11:15:00',
        flUser: '0',
        slUser: '0',
        tlUser: '0',
        dataBlocks: [
          AuthDataBlock(
            recSl: 1,
            tableName: 'USERS002',
            data: {
              'ORGCODE': '50',
              'USERSCD': 'arjun_m',
              'ROLECD': '10',
            },
          ),
        ],
      ),
      AuthRecord(
        orgCode: 'AMS001',
        effDate: '2026-03-11',
        programId: 'USR-ROLE',
        primaryKey: 'ROL_SR_AUDIT',
        authSl: '2026-0003',
        displayRemarks: 'New Senior Auditor role with restricted view access',
        eUser: 'SYSTEM_ADMIN',
        eDate: '2026-03-11 14:40:00',
        flUser: '0',
        slUser: '0',
        tlUser: '0',
        dataBlocks: [
          AuthDataBlock(
            recSl: 1,
            tableName: 'ROLE001',
            data: {
              'ORGCODE': '50',
              'ROLECD': '101',
              'ROLENAME': 'Senior Auditor',
              'ROLETYPE': 'M',
              'ROLESUBTYPE': 'AUDIT',
              'VIEWACCESS': '1 - Enable',
              'AUTHACCESS': '0 - Disable',
              'MAKERACCESS': '1 - Enable',
              'ADMINACCESS': '0 - Disable',
              'SYSADMINACCESS': '0 - Disable',
            },
          ),
        ],
      ),
    ];

final List<SubmenuItem> mastersSubmenus = [
  SubmenuItem(
    label: 'Organisation',
    icon: Icons.business_rounded,
    programId: 'ORG-CRT',
    subtitle: 'Manage organizational structure and entities.',
    metric: '3 Units',
    trend: 'Global',
  ),
  SubmenuItem(
    label: 'Branch Master',
    icon: Icons.store_rounded,
    programId: 'BRN-CRT',
    subtitle: 'Manage organizational units and branch data.',
    metric: '12 Br',
    trend: 'Global',
  ),
  SubmenuItem(
    label: 'User Management',
    icon: Icons.person_add_alt_1_rounded,
    programId: 'USR-CRT',
    subtitle: 'Manage administrative access and user credentials.',
    metric: '128 Active',
    trend: '+4 this week',
  ),
  SubmenuItem(
    label: 'Role Assignment',
    icon: Icons.assignment_ind_rounded,
    programId: 'ROLE-CRT',
    subtitle: 'Assign RBAC profiles to system operators.',
    metric: '15 Roles',
    trend: 'Stable',
  ),
  SubmenuItem(
    label: 'Role Master',
    icon: Icons.admin_panel_settings_rounded,
    programId: 'USR-ROLE',
    subtitle: 'Define global permission and access profiles.',
    metric: '24 Defined',
    trend: 'Secure',
  ),
  SubmenuItem(
    label: 'Module Config',
    icon: Icons.view_module_rounded,
    programId: 'MOD-CRT',
    subtitle: 'Configure core system architectural modules.',
    metric: '8 Core',
    trend: '99.9% Up',
  ),
  SubmenuItem(
    label: 'Program Master',
    icon: Icons.app_settings_alt_rounded,
    programId: 'PROG-CRT',
    subtitle: 'Define and manage system programs and screens.',
    metric: '64 Progs',
    trend: 'Standard',
  ),
  SubmenuItem(
    label: 'Menu Master',
    icon: Icons.menu_open_rounded,
    programId: 'MENU-MST',
    subtitle: 'Manage multilevel navigation and system menus.',
    metric: '3 Levels',
    trend: 'Dynamic',
  ),
];

final List<SubmenuItem> glSubmenus = [
  SubmenuItem(
    label: 'GL Category',
    icon: Icons.category_rounded,
    programId: 'GL-CAT',
    subtitle: 'Define financial ledger classification groups.',
    metric: '12 Cat',
    trend: 'Balanced',
  ),
  SubmenuItem(
    label: 'GL Master',
    icon: Icons.account_balance_wallet_rounded,
    programId: 'GL-MST',
    subtitle: 'Configure core account and ledger frameworks.',
    metric: '85 Mast',
    trend: 'Audited',
  ),
  SubmenuItem(
    label: 'Sub Category',
    icon: Icons.folder_open_rounded,
    programId: 'GL-SUB',
    screen: 'submenu_dashboard',
    subtitle: 'Open the GL control sub modules in one place.',
    metric: '4 Modules',
    trend: 'Grouped',
  ),
];

final List<SubmenuItem> transactionSubmenus = [
  SubmenuItem(
    label: 'Journals',
    icon: Icons.description_rounded,
    programId: 'GL-JRN',
    subtitle: 'Create and manage ledger journal entries.',
    metric: 'New',
    trend: 'Daily',
  ),
  SubmenuItem(
    label: 'Chart of Accounts',
    icon: Icons.list_alt_rounded,
    programId: 'RPT-COA',
    subtitle: 'View and manage organization accounts structure.',
    metric: 'Active',
    trend: 'Standard',
  ),
];

final List<SubmenuItem> glSubCategorySubmenus = [
  SubmenuItem(
    label: 'Allowed Currency',
    icon: Icons.currency_exchange_rounded,
    programId: 'GL-CUR',
    subtitle: 'Manage multi-currency exchange parameters.',
    metric: '150+ Cur',
    trend: 'Live FX',
  ),
  SubmenuItem(
    label: 'Allowed Branch',
    icon: Icons.location_city_rounded,
    programId: 'GL-BRN',
    subtitle: 'Set organizational unit and branch access.',
    metric: '12 Br',
    trend: 'Global',
  ),
  SubmenuItem(
    label: 'GL Segments',
    icon: Icons.segment_rounded,
    programId: 'GL-SEG',
    subtitle: 'Manage data dimensionality and segmentation.',
    metric: '5 Seg',
    trend: 'Syncing',
  ),
  SubmenuItem(
    label: 'GL Attributes',
    icon: Icons.settings_input_component_rounded,
    programId: 'GL-ATT',
    subtitle: 'Customize metadata fields and ledger attrs.',
    metric: '32 Attr',
    trend: 'Healthy',
  ),
];

final List<SubmenuItem> configSubmenus = [
  SubmenuItem(
    label: 'Auth Controller',
    icon: Icons.admin_panel_settings_rounded,
    programId: 'AUTHCTL',
    subtitle: 'Centralized authorization logic gatekeeper.',
    metric: 'v2.4.0',
    trend: 'Healthy',
  ),
];

final List<SubmenuItem> authSubmenus = [
  SubmenuItem(
    label: 'Authorization Queue',
    icon: Icons.fact_check_rounded,
    programId: 'nontranauth',
    screen: 'nontranauth',
    subtitle: 'Monitor and approve pending security requests.',
    metric: '—',
    trend: 'Priority',
  ),
];

final List<SubmenuItem> reportSubmenus = [
  SubmenuItem(
    label: 'Profit and Loss',
    icon: Icons.trending_up_rounded,
    programId: 'RPT-PL',
    subtitle: 'View operational profit and loss statements.',
    metric: 'Monthly',
    trend: 'View',
  ),
  SubmenuItem(
    label: 'Trial Balance',
    icon: Icons.balance_rounded,
    programId: 'RPT-TB',
    subtitle: 'Generate and review the trial balance.',
    metric: 'Summary',
    trend: 'View',
  ),
  SubmenuItem(
    label: 'Balance Sheet',
    icon: Icons.account_balance_wallet_rounded,
    programId: 'RPT-BS',
    subtitle: 'View overall organizational balance sheet.',
    metric: 'Annual',
    trend: 'View',
  ),
];
