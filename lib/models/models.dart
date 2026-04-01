import 'dart:convert';

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
    List<AuthDataBlock> dataBlocksList = [];
    try {
      var dbData = json['dataBlocks'] ?? json['datablock'] ?? json['dataBlock'];
      if (dbData != null) {
        if (dbData is String && dbData.trim().isNotEmpty) {
          var parsed = jsonDecode(dbData);
          if (parsed is List) {
            for (var item in parsed) {
              if (item is Map<String, dynamic>) {
                dataBlocksList.add(AuthDataBlock.fromJson(item));
              }
            }
          } else if (parsed is Map<String, dynamic>) {
            dataBlocksList.add(AuthDataBlock.fromJson(parsed));
          }
        } else if (dbData is List) {
          for (var item in dbData) {
            if (item is Map<String, dynamic>) {
              dataBlocksList.add(AuthDataBlock.fromJson(item));
            }
          }
        } else if (dbData is Map<String, dynamic>) {
          dataBlocksList.add(AuthDataBlock.fromJson(dbData));
        }
      }
    } catch (e) {
      print('Error parsing dataBlocks for ${json['authSl']}: $e');
    }

    return AuthRecord(
      orgCode: json['orgCode']?.toString() ?? '',
      effDate: json['effDate']?.toString() ?? '',
      programId: json['programId']?.toString() ?? '',
      primaryKey: json['primaryKey']?.toString() ?? '',
      authSl: json['authSl']?.toString() ?? '',
      displayRemarks: json['displayRemarks']?.toString() ?? '',
      eUser: json['eUser']?.toString() ?? '',
      eDate: json['eDate']?.toString() ?? '',
      cUser: json['cUser']?.toString(),
      cDate: json['cDate']?.toString(),
      rUser: json['rUser']?.toString(),
      rDate: json['rDate']?.toString(),
      flUser: json['flUser']?.toString(),
      flDate: json['flDate']?.toString(),
      slUser: json['slUser']?.toString(),
      slDate: json['slDate']?.toString(),
      tlUser: json['tlUser']?.toString(),
      tlDate: json['tlDate']?.toString(),
      exceptionalRemarks: json['exceptionalRemarks']?.toString(),
      correctionReq: json['correctionReq'] == true || json['correctionReq'] == 1,
      correctionDetails: json['correctionDetails']?.toString(),
      riskPresented: json['riskPresented'] == true || json['riskPresented'] == 1,
      authLock: json['authLock'] == true || json['authLock'] == 1,
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
    Map<String, dynamic> dataMap = {};
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'];
    } else {
      var dbString = json['dataBlock'] ?? json['datablock'] ?? json['DATABLOCK'];
      if (dbString != null && dbString is String && dbString.trim().isNotEmpty) {
        try {
          dataMap = jsonDecode(dbString);
        } catch (e) {
          // Fallback to the whole map if it's not a string or decode fails
          dataMap = json;
        }
      } else {
        // Fallback: use the item itself as data if no specific datablock field
        dataMap = json;
      }
    }

    return AuthDataBlock(
      recSl: json['recSl'] ?? 0,
      tableName: json['tableName'] ?? '',
      data: dataMap,
    );
  }
}

class AppState {
  final String screen; 
  final String? selectedType; // 'T' or 'N'
  final String? selectedProg;
  final String? selectedCategory;
  final List<QueueEntry> queue;
  final List<AuthRecord> authQueue;
  final int authQueueTotal;
  final Map<String, Auth101Config> authConfigs;
  final QueueEntry? lastSubmitted;
  final String? token;
  final String? userName;
  final bool isLoadingAuth;

  const AppState({
    required this.screen,
    this.selectedType,
    this.selectedProg,
    this.selectedCategory,
    required this.queue,
    required this.authQueue,
    this.authQueueTotal = 0,
    required this.authConfigs,
    this.lastSubmitted,
    this.token,
    this.userName,
    this.isLoadingAuth = false,
  });

    AppState copyWith({
    String? screen,
    String? selectedType,
    String? selectedProg,
    String? selectedCategory,
    List<QueueEntry>? queue,
    List<AuthRecord>? authQueue,
    int? authQueueTotal,
    Map<String, Auth101Config>? authConfigs,
    QueueEntry? lastSubmitted,
    String? token,
    String? userName,
    bool? isLoadingAuth,
    bool clearProg = false,
    bool clearCategory = false,
    bool clearSubmitted = false,
  }) {
    return AppState(
      screen: screen ?? this.screen,
      selectedType: selectedType ?? this.selectedType,
      selectedProg: clearProg ? null : (selectedProg ?? this.selectedProg),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      queue: queue ?? this.queue,
      authQueue: authQueue ?? this.authQueue,
      authQueueTotal: authQueueTotal ?? this.authQueueTotal,
      authConfigs: authConfigs ?? this.authConfigs,
      lastSubmitted:
          clearSubmitted ? null : (lastSubmitted ?? this.lastSubmitted),
      token: token ?? this.token,
      userName: userName ?? this.userName,
      isLoadingAuth: isLoadingAuth ?? this.isLoadingAuth,
    );
  }
}
