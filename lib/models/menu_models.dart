import 'dart:convert';

class ProgramMaster {
  final String pgmId;
  final String descn;
  final int module;
  final int? subModule;
  final int pgmClass;
  final int status;
  final String? remarks;

  ProgramMaster({
    required this.pgmId,
    required this.descn,
    required this.module,
    this.subModule,
    required this.pgmClass,
    required this.status,
    this.remarks,
  });

  factory ProgramMaster.fromJson(Map<String, dynamic> json) {
    return ProgramMaster(
      pgmId: json['pgmId']?.toString() ?? json['PGM_ID']?.toString() ?? '',
      descn: json['descn']?.toString() ?? json['DESCN']?.toString() ?? '',
      module: int.tryParse(json['module']?.toString() ?? json['MODULE']?.toString() ?? '0') ?? 0,
      subModule: int.tryParse(json['subModule']?.toString() ?? json['SUB_MODULE']?.toString() ?? ''),
      pgmClass: int.tryParse(json['pgmClass']?.toString() ?? json['PGM_CLASS']?.toString() ?? '1') ?? 1,
      status: int.tryParse(json['status']?.toString() ?? json['status']?.toString() ?? '1') ?? 1,
      remarks: json['remarks']?.toString() ?? json['REMARKS']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pgmId': pgmId,
    'descn': descn,
    'module': module,
    'subModule': subModule,
    'pgmClass': pgmClass,
    'status': status,
    'remarks': remarks,
  };
}

class ParentMenu {
  final int roleCd;
  final int menuCode;
  final String menuDescn;
  final int menuOrder;
  final int subMenuReq;
  final String parentMenuPgmId;
  final String programPath;
  final String menuLogo;
  final String menuLocation;
  final int menuStatus;

  ParentMenu({
    required this.roleCd,
    required this.menuCode,
    required this.menuDescn,
    required this.menuOrder,
    required this.subMenuReq,
    required this.parentMenuPgmId,
    required this.programPath,
    required this.menuLogo,
    required this.menuLocation,
    required this.menuStatus,
  });

  factory ParentMenu.fromJson(Map<String, dynamic> json) {
    return ParentMenu(
      roleCd: int.tryParse(json['roleCd']?.toString() ?? json['ROLECD']?.toString() ?? '0') ?? 0,
      menuCode: int.tryParse(json['menuCode']?.toString() ?? json['Menucode']?.toString() ?? '0') ?? 0,
      menuDescn: json['menuDescn']?.toString() ?? json['MENU_DESCN']?.toString() ?? '',
      menuOrder: int.tryParse(json['menuOrder']?.toString() ?? json['MENU_ORDER']?.toString() ?? '1') ?? 1,
      subMenuReq: int.tryParse(json['subMenuReq']?.toString() ?? json['SUBMENUREQ']?.toString() ?? '0') ?? 0,
      parentMenuPgmId: json['parentMenuPgmId']?.toString() ?? json['Parentmenu_PGMID']?.toString() ?? '',
      programPath: json['programPath']?.toString() ?? json['Program Path']?.toString() ?? '',
      menuLogo: json['menuLogo']?.toString() ?? json['MENU_LOGO']?.toString() ?? '',
      menuLocation: json['menuLocation']?.toString() ?? json['MENU_LOCATION']?.toString() ?? 'L',
      menuStatus: int.tryParse(json['menuStatus']?.toString() ?? json['MENU_STATUS']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'roleCd': roleCd,
    'menuCode': menuCode,
    'menuDescn': menuDescn,
    'menuOrder': menuOrder,
    'subMenuReq': subMenuReq,
    'parentMenuPgmId': parentMenuPgmId,
    'programPath': programPath,
    'menuLogo': menuLogo,
    'menuLocation': menuLocation,
    'menuStatus': menuStatus,
  };
}

class SubMenu {
  final int roleCd;
  final int menuCode;
  final int subMenuCode;
  final String description;
  final int menuOrder;
  final String subMenuPgmId;
  final String programPath;
  final String menuLogo;
  final int menuStatus;

  SubMenu({
    required this.roleCd,
    required this.menuCode,
    required this.subMenuCode,
    required this.description,
    required this.menuOrder,
    required this.subMenuPgmId,
    required this.programPath,
    required this.menuLogo,
    required this.menuStatus,
  });

  factory SubMenu.fromJson(Map<String, dynamic> json) {
    return SubMenu(
      roleCd: int.tryParse(json['roleCd']?.toString() ?? json['ROLECD']?.toString() ?? '0') ?? 0,
      menuCode: int.tryParse(json['menuCode']?.toString() ?? json['Menucode']?.toString() ?? '0') ?? 0,
      subMenuCode: int.tryParse(json['subMenuCode']?.toString() ?? json['submenucode']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? json['Decription']?.toString() ?? '',
      menuOrder: int.tryParse(json['menuOrder']?.toString() ?? json['MENU_ORDER']?.toString() ?? '1') ?? 1,
      subMenuPgmId: json['subMenuPgmId']?.toString() ?? json['Submenu_PGMID']?.toString() ?? '',
      programPath: json['programPath']?.toString() ?? json['Program Path']?.toString() ?? '',
      menuLogo: json['menuLogo']?.toString() ?? json['MENU_LOGO']?.toString() ?? '',
      menuStatus: int.tryParse(json['menuStatus']?.toString() ?? json['MENU_STATUS']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'roleCd': roleCd,
    'menuCode': menuCode,
    'subMenuCode': subMenuCode,
    'description': description,
    'menuOrder': menuOrder,
    'subMenuPgmId': subMenuPgmId,
    'programPath': programPath,
    'menuLogo': menuLogo,
    'menuStatus': menuStatus,
  };
}

class MenuProgram {
  final int roleCd;
  final int menuCode;
  final int subMenuCode;
  final String pgmId;
  final String description;
  final int menuOrder;
  final String programPath;
  final String menuLogo;
  final int status;

  MenuProgram({
    required this.roleCd,
    required this.menuCode,
    required this.subMenuCode,
    required this.pgmId,
    required this.description,
    required this.menuOrder,
    required this.programPath,
    required this.menuLogo,
    required this.status,
  });

  factory MenuProgram.fromJson(Map<String, dynamic> json) {
    return MenuProgram(
      roleCd: int.tryParse(json['roleCd']?.toString() ?? json['ROLECD']?.toString() ?? '0') ?? 0,
      menuCode: int.tryParse(json['menuCode']?.toString() ?? json['Menucode']?.toString() ?? '0') ?? 0,
      subMenuCode: int.tryParse(json['subMenuCode']?.toString() ?? json['submenucode']?.toString() ?? '0') ?? 0,
      pgmId: json['pgmId']?.toString() ?? json['PGM_ID']?.toString() ?? '',
      description: json['description']?.toString() ?? json['Decription']?.toString() ?? '',
      menuOrder: int.tryParse(json['menuOrder']?.toString() ?? json['MENU_ORDER']?.toString() ?? '1') ?? 1,
      programPath: json['programPath']?.toString() ?? json['Program Path']?.toString() ?? '',
      menuLogo: json['menuLogo']?.toString() ?? json['MENU_LOGO']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? json['status']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'roleCd': roleCd,
    'menuCode': menuCode,
    'subMenuCode': subMenuCode,
    'pgmId': pgmId,
    'description': description,
    'menuOrder': menuOrder,
    'programPath': programPath,
    'menuLogo': menuLogo,
    'status': status,
  };
}
