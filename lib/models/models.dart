class Auth101Config {
  final String id;
  final String name;
  final bool approvalReq;
  final bool preApproveProc;
  final String? preExecMethod; // '1': SQL, '2': API, '3': JAVA
  final String? preProcessName;
  final bool postApproveProc;
  final String? postExecMethod;
  final String? postProcessName;
  final bool isTran;
  final int levels;

  const Auth101Config({
    required this.id,
    required this.name,
    required this.approvalReq,
    this.preApproveProc = false,
    this.preExecMethod,
    this.preProcessName,
    this.postApproveProc = false,
    this.postExecMethod,
    this.postProcessName,
    required this.isTran,
    required this.levels,
  });
}

class Auth103Limit {
  final double from;
  final double to;
  final String role;
  final String approver;

  const Auth103Limit({
    required this.from,
    required this.to,
    required this.role,
    required this.approver,
  });
}

class QueueEntry {
  final String authsl;
  final String type; // 'T' or 'N'
  final String prog;
  final String name;
  final String user;
  final String date;
  final String amount;
  final String level;
  final bool risk;
  final bool locked;
  final bool isNew;

  QueueEntry({
    required this.authsl,
    required this.type,
    required this.prog,
    required this.name,
    required this.user,
    required this.date,
    required this.amount,
    required this.level,
    required this.risk,
    required this.locked,
    required this.isNew,
  });

  QueueEntry copyWith({bool? isNew}) => QueueEntry(
        authsl: authsl,
        type: type,
        prog: prog,
        name: name,
        user: user,
        date: date,
        amount: amount,
        level: level,
        risk: risk,
        locked: locked,
        isNew: isNew ?? this.isNew,
      );
}
class AuthRecord {
  final String orgCode;
  final String effDate;
  final String programId;
  final String primaryKey;
  final String authSl;
  final String displayRemarks;
  final String eUser;
  final String eDate;
  final String? cUser;
  final String? cDate;
  final String? rUser;
  final String? rDate;
  final String? flUser;
  final String? flDate;
  final String? slUser;
  final String? slDate;
  final String? tlUser;
  final String? tlDate;
  final String? exceptionalRemarks;
  final bool correctionReq;
  final String? correctionDetails;
  final bool riskPresented;
  final bool authLock;
  final List<AuthDataBlock> dataBlocks;

  AuthRecord({
    required this.orgCode,
    required this.effDate,
    required this.programId,
    required this.primaryKey,
    required this.authSl,
    required this.displayRemarks,
    required this.eUser,
    required this.eDate,
    this.cUser,
    this.cDate,
    this.rUser,
    this.rDate,
    this.flUser,
    this.flDate,
    this.slUser,
    this.slDate,
    this.tlUser,
    this.tlDate,
    this.exceptionalRemarks,
    this.correctionReq = false,
    this.correctionDetails,
    this.riskPresented = false,
    this.authLock = false,
    required this.dataBlocks,
  });

  factory AuthRecord.fromJson(Map<String, dynamic> json) {
    var list = json['dataBlocks'] as List? ?? [];
    List<AuthDataBlock> dataBlocksList =
        list.map((i) => AuthDataBlock.fromJson(i)).toList();

    return AuthRecord(
      orgCode: json['orgCode'] ?? '',
      effDate: json['effDate'] ?? '',
      programId: json['programId'] ?? '',
      primaryKey: json['primaryKey'] ?? '',
      authSl: json['authSl'] ?? '',
      displayRemarks: json['displayRemarks'] ?? '',
      eUser: json['eUser'] ?? '',
      eDate: json['eDate'] ?? '',
      cUser: json['cUser'],
      cDate: json['cDate'],
      rUser: json['rUser'],
      rDate: json['rDate'],
      flUser: json['flUser'],
      flDate: json['flDate'],
      slUser: json['slUser'],
      slDate: json['slDate'],
      tlUser: json['tlUser'],
      tlDate: json['tlDate'],
      exceptionalRemarks: json['exceptionalRemarks'],
      correctionReq: json['correctionReq'] ?? false,
      correctionDetails: json['correctionDetails'],
      riskPresented: json['riskPresented'] ?? false,
      authLock: json['authLock'] ?? false,
      dataBlocks: dataBlocksList,
    );
  }
}

class AuthDataBlock {
  final int recSl;
  final String tableName;
  final Map<String, dynamic> data;

  AuthDataBlock({
    required this.recSl,
    required this.tableName,
    required this.data,
  });

  factory AuthDataBlock.fromJson(Map<String, dynamic> json) {
    return AuthDataBlock(
      recSl: json['recSl'] ?? 0,
      tableName: json['tableName'] ?? '',
      data: json['data'] ?? {},
    );
  }
}

class AppState {
  final String screen; // login, select, tran, nontran, queue, direct
  final String? selectedType; // 'T' or 'N'
  final String? selectedProg;
  final List<QueueEntry> queue;
  final List<AuthRecord> authQueue;
  final Map<String, Auth101Config> authConfigs;
  final QueueEntry? lastSubmitted;
  final String? token;
  final String? userName;

  const AppState({
    required this.screen,
    this.selectedType,
    this.selectedProg,
    required this.queue,
    required this.authQueue,
    required this.authConfigs,
    this.lastSubmitted,
    this.token,
    this.userName,
  });

    AppState copyWith({
    String? screen,
    String? selectedType,
    String? selectedProg,
    List<QueueEntry>? queue,
    List<AuthRecord>? authQueue,
    Map<String, Auth101Config>? authConfigs,
    QueueEntry? lastSubmitted,
    String? token,
    String? userName,
    bool clearProg = false,
    bool clearSubmitted = false,
  }) {
    return AppState(
      screen: screen ?? this.screen,
      selectedType: selectedType ?? this.selectedType,
      selectedProg: clearProg ? null : (selectedProg ?? this.selectedProg),
      queue: queue ?? this.queue,
      authQueue: authQueue ?? this.authQueue,
      authConfigs: authConfigs ?? this.authConfigs,
      lastSubmitted:
          clearSubmitted ? null : (lastSubmitted ?? this.lastSubmitted),
      token: token ?? this.token,
      userName: userName ?? this.userName,
    );
  }
}
