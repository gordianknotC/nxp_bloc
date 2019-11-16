// public [a-zA-Z]+ ([a-zA-Z_0-9]+);
// ignore: non_constant_identifier_names
import 'dart:typed_data';

import 'package:PatrolParser/PatrolParser.dart';
import 'package:common/common.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';

//final D = Injector.getInjector().get<TLogWriter>();

enum ENdefRecords{
  EmptyRecord,
  TextRecord,
  SmartPosterRecord,
  AndroidApplicationRecord,
  UriRecord,
  MimeRecord
}
enum ENdefResponses {
  ndefReadSuccess,
  ndefWriteSuccess,
  ndefDetected,
  ndefWriteIncorrectContent,
  ndefReadLost,
  ndefReadError,
  ndefReadResponse,
  ndefReadProtected,
  ndefWriteLost,
  ndefWriteError,
  ndefWriteResponse,
  ndefWriteProtected,
  ndefTapRead,
  ndefTapWrite,
  toastMessage
}
enum EAuthStatus {
  Disabled,
  Unprotected,
  Authenticated,
  Protected_W,
  Protected_RW,
  Protected_W_SRAM,
  Protected_RW_SRAM,
}
enum EPseudoMainActivityMethods {
  showSettingNoNfcAlert,
  closeAppNoNfcAlert,
  nfcAvailable,
  HAS_NFC_FUNCTIONALITY,
  HAS_NONFC_FUNCTIONALITY
  
}
enum ERegisterSessionMethods {
  onSetAnswer , onTagLost, onTransceiveFailed

}
enum ENtagDemoMethods {
  resetRegister,
  resetRegisterCustomBytes,
  flutterReady,
  readEEPROMCustomBytes,
  writeEEPROMCustomBytes,
  doProcessOnExistingTagWithoutAuthCheck,
  setFactoryPassword,
  setPassword,
  obtainAuthStatus,
  getLog,
  checkNFC,
  checkNFC2,
  checkNFC3,
  checkNFC4,
  isReady,
  isConnected,
  isTagPresent,
  finishAllTasks,
  vibrate,
  scanFile,
  getProduct,
  setBoardVersion,
  resetTagMemory,
  readSessionRegisters,
  readSessionRegistersCustom,
  readWriteConfigRegister,
  readTagContent,
  resetTagContent,
  LED,
  LEDFinish,
  NDEFReadFinish,
  NDEF,
  readNDEF,
  writeNDEF,
  Flash,
  Auth,
  clearAuth,
  SRAMSpeedtest,
  SRAMSpeedFinish,
  EEPROMSpeedtest,
  EEPROMSpeedFinish,
  WriteEmptyNdefFinish,
  WriteDefaultNdefFinish,
  ObtainAuthStatus,
  // call from platfrom to dart
  onSetBoardVersion,
  onShowAlert,
  onShowOkDialogue,
  onShowOkDialogueForAction,
  onToastMakeText,
  onNDEFWrite,
  onNDEFRead,
  onWriteSRAM,
  onWriteEEPROM,
}
enum ECommonUI_Methods {
  onReading,
  onToastMakeText,
  onShowOkDialogue,
  onShowOkDialogueForAction,
  onShowYNDialogueForAction,
  closeYNDialogue,
  onShowAlert,
  onSetBoardVersion,
  onLogToDart,
  onSetDataRate,
  onShowProgressDialogue,
  onNFCServiceDead,
  onJavaException,
}
enum EndefFragment_Methods {
  // platform to dart
  updateToUi,
  toastMessage,
  updateDataRate,
  updateProgress,
  updateEditText,
  // dart to platform
  updateToPlatform,
  readNdefClick,
  writeNdefClick
}
enum EndefFragment {
  // assign in dart, upload to platform
  isWriteChosen,
  writeOptions,
  ndefEditBytes,
  ndefEditText,
  ndefEditMac,
  ndefEditName,
  ndefEditClass,
  ndefEditTitle,
  ndefEditLink,
  ndefReadLoop,
  addAar,
  // generate in platform, upload to dart
  ndefText,
  ndefBytes,
  ndefTypeText,
  ndefDataRateCallback,
  ndefCallback,
  ndefRawRecord,
}

String stringfyMap(Map data) {
  String ret = "";
  data.forEach((k, v) {
    if (v == null || v == "" || k == null || k == "")
      return;
    ret += "$k: $v";
  });
  return ret;
}

mixin DelegateMap {
  Map _delegate;

  Map get delegate => _delegate;
}

class NdefRecord{
  ENdefRecords type;
  String content;
  NdefRecord(this.type, this.content);
}

class NdefFragmentOption with DelegateMap {
  static RegExp recordPtn = RegExp("#[0-9] (TextRecord|AndroidApplicationRecord|UriRecord|MimeRecord|SmartPosterRecord|EmptyRecord)");
  // assign in dart, upload to platform
  bool isWriteChosen = false;
  bool ndefReadLoop = false;
  bool addAar = false;
  String ndefEditText = '';
  String ndefEditMac = '';
  String ndefEditName = '';
  String ndefEditClass = '';
  String ndefEditTitle = '';
  String ndefEditLink = '';
  NtagRawRecord ndefRawRecord = null;
  Uint8List ndefEditBytes = Uint8List.fromList([]);
  
  WriteOptions _writeOptions = WriteOptions.RadioNdefText;

  WriteOptions get writeOptions => _writeOptions;

  void set writeOptions(v) {
    setWriteOptions(v);
  }

  // generate in platform, upload to dart
  String _ndefTypeText = ename(WriteOptions.RadioNdefText);
  String _ndefDataRateCallback = "";
  String _ndefCallback = "";
  String _performance = "";
  String ndefContent = "";
  Uint8List ndefContentBytes;
  List<NdefRecord> ndefRecords = [];

  String get datarate => _ndefDataRateCallback;
  String get ndefType => _ndefTypeText;
  String get ndefText {
    return ndefRecords.where((v) =>
      v.type != ENdefRecords.AndroidApplicationRecord)
        .map((v) => v.content)
        .join('\n').trim();
  }
  

  NdefFragmentOption();

  NdefFragmentOption.fromMap(Map map) {
    fromMap(map);
  }

  Map asMap(){
    return _delegate;
  }
  void parseNdefText(){
    if (ndefContent.isEmpty)
      return;
    
    final rawlist = ndefContent.split('\n').toList();
    
    if (rawlist.isEmpty)
      return;
    
    String textRecord, appRecord;
    for (var i = 0; i < rawlist.length; ++i) {
      var s = rawlist[i];
      if (s.startsWith(recordPtn)){
         final tag = FN.range(s.split(' ')[1], 0, -1);
         final e   = ENdefRecords.values.firstWhere((v) => v.toString().endsWith(tag),
             orElse: () => throw Exception("invalid ndef record: $tag"));
         switch(e){
           case ENdefRecords.EmptyRecord:
             ndefRecords.add(NdefRecord(ENdefRecords.EmptyRecord, ""));
             break;
           case ENdefRecords.TextRecord:
             ndefRecords.add(NdefRecord(ENdefRecords.TextRecord, rawlist[i + 1]));
             break;
           case ENdefRecords.AndroidApplicationRecord:
             ndefRecords.add(NdefRecord(ENdefRecords.AndroidApplicationRecord, rawlist[i + 1]));
             break;
           case ENdefRecords.UriRecord:
              ndefRecords.add(NdefRecord(ENdefRecords.UriRecord, rawlist[i + 1]));
              break;
           case ENdefRecords.MimeRecord:
             ndefRecords.add(NdefRecord(ENdefRecords.MimeRecord, rawlist[i + 1]));
             break;
           case ENdefRecords.SmartPosterRecord:
             ndefRecords.add(NdefRecord(ENdefRecords.SmartPosterRecord, rawlist[i + 1]));
             break;
           default:
             ndefRecords.add(NdefRecord(ENdefRecords.TextRecord, rawlist[i + 1]));
         }
         i ++;
         continue;
      }
    }
  }

  void fromUpdate(Map map) {
    ndefContent = map[ename(EndefFragment.ndefText)] as String ?? "";
    _ndefTypeText = map[ename(EndefFragment.ndefTypeText)] as String ?? "";
    _ndefDataRateCallback =
        map[ename(EndefFragment.ndefDataRateCallback)] as String ?? "";
    parseNdefText();
  }

  void fromPlatform(Map map) {
    guard(() {
      addAar = map[ename(EndefFragment.addAar)] as bool ?? false;
      ndefContent = map[ename(EndefFragment.ndefText)] as String ?? "";
      _ndefTypeText = map[ename(EndefFragment.ndefTypeText)] as String ?? "";
      _ndefDataRateCallback =
          map[ename(EndefFragment.ndefDataRateCallback)] as String ?? "";
      _ndefCallback = map[ename(EndefFragment.ndefCallback)] as String ?? "";
      parseNdefText();
      //---------------------------------------
    }, "Initializing NdefFragmentOption failed",
        error: "DataParsingError", raiseOnly: false);
  }

  void fromMap(Map map) {
    _delegate = map;
    guard(() {
      _writeOptions = map[ename(EndefFragment.writeOptions)] != null
          ? WriteOptions.values.firstWhere((v) =>
              v.toString().endsWith(map[ename(EndefFragment.writeOptions)] as String))
          : WriteOptions.RadioNdefText;
      isWriteChosen = put(map, EndefFragment.isWriteChosen, false) as bool;
      ndefReadLoop = put(map, EndefFragment.ndefReadLoop, false) as bool;
      addAar = put(map, EndefFragment.addAar, false) as bool;
      ndefEditText = put(map, EndefFragment.ndefEditText, "") as String;
      ndefEditBytes = put(map, EndefFragment.ndefEditBytes, Uint8List.fromList([])) as Uint8List;

      ndefEditMac = put(map, EndefFragment.ndefEditMac, "") as String;
      ndefEditName = put(map, EndefFragment.ndefEditName, "") as String;
      ndefEditClass = put(map, EndefFragment.ndefEditClass, "") as String;
      ndefEditTitle = put(map, EndefFragment.ndefEditTitle, "") as String;
      ndefEditLink = put(map, EndefFragment.ndefEditLink, "") as String;
      ndefContent = put(map, EndefFragment.ndefText, "") as String;
      ndefContentBytes = put(map, EndefFragment.ndefBytes, Uint8List.fromList([])) as Uint8List;
      _ndefTypeText = put(map, EndefFragment.ndefTypeText, "") as String;
      _ndefDataRateCallback = put(map, EndefFragment.ndefDataRateCallback, "") as String;
      
      final record =  put(map, EndefFragment.ndefRawRecord, {}) as Map;
      ndefRawRecord = NtagRawRecord.fromMap(record);

      parseNdefText();
      //---------------------------------------
    }, "Initializing NdefFragmentOption failed",
        error: "DataParsingError", raiseOnly: false);
  }

  @override
  String toString() {
    return stringfyMap(_delegate);
  }

  setWriteOptions(dynamic val) {
    WriteOptions input = val is WriteOptions
        ? val
        : val is String
            ? WriteOptions.values
                .firstWhere((v) => v.toString().toLowerCase() == val, orElse: () {
                throw Exception('Invalid WriteOption: $val');
              })
            : () {
                throw Exception(
                    'invalid type of arguemnts for setWriteOptions');
              }();

    switch (input) {
      case WriteOptions.RadioNdefText:
        ndefEditText = "";
        break;
      case WriteOptions.RadioNdefUrl:
        ndefEditText = "http://www.";
        break;
      case WriteOptions.RadioNdefBt:
        break;
      case WriteOptions.RadioNdefSp:
        ndefEditLink = "http://www.";
        break;
      case WriteOptions.RadioNdefBytes:
        ndefEditBytes = Uint8List.fromList([]);
        break;
    }
    _writeOptions = val as WriteOptions;
  }
}

enum WriteOptions { RadioNdefText, RadioNdefBytes, RadioNdefUrl, RadioNdefBt, RadioNdefSp }
enum EProductVersion {
  NTAG_I2C_1k,
  NTAG_I2C_1k_T,
  NTAG_I2C_1k_V,
  NTAG_I2C_2k,
  NTAG_I2C_2k_T,
  NTAG_I2C_2k_V,
  NTAG_I2C_1k_Plus,
  NTAG_I2C_2k_Plus,
  MTAG_I2C_1k,
  MTAG_I2C_2k,
  TNPI_6230,
  TNPI_3230
}

enum EProductInfo {
  vendor_ID,
  product_type,
  product_subtype,
  major_product_version,
  minor_product_version,
  storage_size,
  protocol_type,
  product_name,
  memsize
}
enum ERegister {
  NDEF_RAW_RECORD,
  NDEF_Message,
  NDEF_Message_BYTES,
  Manufacture,
  Mem_size,
  I2C_RST_ON_OFF,
  FD_OFF,
  FD_ON,
  LAST_NDEF_PAGE,
  NDEF_DATA_READ,
  RF_FIELD_PRESENT,
  PTHRU_ON_OFF,
  I2C_LOCKED,
  RF_LOCKED,
  SRAM_I2C_READY,
  SRAM_RF_READY,
  PTHRU_DIR,
  SM_Reg,
  WD_LS_Reg,
  WD_MS_Reg,
  SRAM_MIRROR_ON_OFF,
  I2C_CLOCK_STR
}

class ProductInfo with DelegateMap {
  int vendor_ID,
      product_type,
      product_subtype,
      major_product_version,
      minor_product_version,
      storage_size,
      protocol_type;
  int memsize;
  String product_name;

  ProductInfo(
      this.major_product_version,
      this.memsize,
      this.minor_product_version,
      this.product_name,
      this.product_subtype,
      this.product_type,
      this.protocol_type,
      this.storage_size,
      this.vendor_ID);

  ProductInfo.fromMap(Map data) {
    _delegate = data;
    guard(() {
      vendor_ID = put(data, EProductInfo.vendor_ID) as int;
      product_type = put(data, EProductInfo.product_type) as int;
      product_subtype = put(data, EProductInfo.product_subtype) as int;
      major_product_version = put(data, EProductInfo.major_product_version) as int;
      minor_product_version = put(data, EProductInfo.minor_product_version) as int;
      storage_size = put(data, EProductInfo.storage_size) as int;
      protocol_type = put(data, EProductInfo.protocol_type) as int;
      memsize = put(data, EProductInfo.memsize) as int;
      product_name = put(data, EProductInfo.product_name) as String;
    }, "create ProductInfo fromMap failed");
  }
  Map<String,dynamic> tempMap(){
    return {
      "product_name": product_name,
      "memsize": memsize,
    };
  }

  @override
  toString() => stringfyMap(_delegate);
}

class CommonUIArg with DelegateMap {
  String message;
  String title;
  String request;
  int time;
  int bytes;
  bool error;

  CommonUIArg.fromMap(Map map) {
    _delegate = map;
    error = (map.containsKey("error") ? map["error"] : null) as bool;
    message = (map.containsKey("message") ? map["message"] : null) as String;
    title = (map.containsKey("title") ? map["title"] : null) as String;
    request = (map.containsKey("\$request") ? map["\$request"] : null) as String;
    message = (map.containsKey("time") ? map["time"] : null) as String;
    message = (map.containsKey("bytes") ? map["bytes"] : null) as String;
  }

  @override
  toString() {
    return stringfyMap(_delegate);
    String ret = "";
    if (message != null) ret += "message: $message, ";
    if (title != null) ret += "title: $title, ";
    if (time != null) ret += "message: $time, ";
    if (bytes != null) ret += "message: $bytes, ";
    if (error != null) ret += "error: $error, ";
    if (request != null) ret += "request: $request, ";
    return ret;
  }
}

class NtagRawRecord{
  int tlvPlusNdef;
  bool valid;
  int tlvSize;
  int ndefSize;
  Uint8List data;
  NtagRawRecord({this.tlvPlusNdef, this.valid, this.tlvSize, this.ndefSize, this.data});

  NtagRawRecord.mock(){
    tlvPlusNdef =   0;
    valid = true;
    tlvSize =  0;
    ndefSize =  0;
    data =  Uint8List.fromList(PatrolRecord.generate().toMemAddressBytes());
  }

  NtagRawRecord.empty(){
    tlvPlusNdef =   0;
    valid = true;
    tlvSize =  0;
    ndefSize =  0;
    data =  Uint8List.fromList(List.generate(96, (i) => 0));
  }

  NtagRawRecord.fromPatrolRecord(PatrolRecord record){
		try {
			tlvPlusNdef = 0;
			valid     = true;
			tlvSize   = 0;
			ndefSize  = 0;
			data      = Uint8List.fromList(record.toMemAddressBytes());
		} catch (e) {
			throw Exception(
					'NtagRawRecord.fromPatrolRecord failed: \n${StackTrace.fromString(e.toString())}');
		}
  }
  
  NtagRawRecord.fromMap(Map map){
    tlvPlusNdef = (map['tlvPlusNdef'] as int) ?? 0;
    valid = (map['valid'] as bool) ?? false;
    tlvSize = (map['tlvSize'] as int) ?? 0;
    ndefSize = (map['ndefSize'] as int) ?? 0;
    data = (map['data'] as Uint8List) ?? Uint8List(0);
  }
  
  Map<String, dynamic> asMap(){
    return{
    "tlvPlusNdef":tlvPlusNdef,
    "tlvSize" :tlvSize,
    "ndefSize": ndefSize,
    "valid"   :valid,
    "data"    :data
    };
  }
}
class Ntag_I2C_Registers with DelegateMap {
  String errorMessage;
  bool isSuccessfullyWritten;
  String Manufacture, FD_OFF, FD_ON, NDEF_Message;
  Uint8List NDEF_Message_BYTES;
  NtagRawRecord NDEF_RAW_RECORD;
  bool I2C_CLOCK_STR,
      I2C_LOCKED,
      I2C_RST_ON_OFF,
      NDEF_DATA_READ,
      PTHRU_DIR,
      PTHRU_ON_OFF,
      RF_FIELD_PRESENT,
      RF_LOCKED,
      SRAM_I2C_READY,
      SRAM_MIRROR_ON_OFF,
      SRAM_RF_READY;

  int LAST_NDEF_PAGE,
      Mem_size, //number of bytes
      SM_Reg,
      WD_LS_Reg,
      WD_MS_Reg;

  Ntag_I2C_Registers.writtenResponse(this.isSuccessfullyWritten);
  Ntag_I2C_Registers.errorResponse(this.errorMessage);
  
  Ntag_I2C_Registers(
      this.FD_OFF,
      this.FD_ON,
      this.I2C_CLOCK_STR,
      this.I2C_LOCKED,
      this.I2C_RST_ON_OFF,
      this.LAST_NDEF_PAGE,
      this.Manufacture,
      this.Mem_size,
      this.NDEF_DATA_READ,
      this.NDEF_Message,
      this.PTHRU_DIR,
      this.PTHRU_ON_OFF,
      this.RF_FIELD_PRESENT,
      this.RF_LOCKED,
      this.SM_Reg,
      this.SRAM_I2C_READY,
      this.SRAM_MIRROR_ON_OFF,
      this.SRAM_RF_READY,
      this.WD_LS_Reg,
      this.WD_MS_Reg);

  String info() {
    return "FD_OFF     : $FD_OFF         ,FD_ON: $FD_ON\n"
        "Manufacture: $Manufacture\n"
        "message    : $NDEF_Message\n";
  }

  Map<String, dynamic> infoMap(){
    return {
      "Manufacture": Manufacture,
      "Mem_size": Mem_size,
      "TAG_LOCKED": I2C_LOCKED,
      "RF_LOCKED": RF_LOCKED,
      "RF_FIELD": RF_FIELD_PRESENT
    };
  }
  
  Ntag_I2C_Registers.fromBytes(Uint8List bytes){
		try {
			final record = PatrolRecord.fromBytes(bytes);
			NDEF_Message_BYTES = bytes;
			NDEF_RAW_RECORD    = NtagRawRecord.fromPatrolRecord(record);
			print('record: $record');
			print('NDEF_RAW_RECORD: ${NDEF_RAW_RECORD}');
		} catch (e) {
			print("Ntag_I2C_Registers.fromBytes failed: "
					"\n\t${StackTrace.fromString(e.toString())}");
			rethrow;
		}
  
  }
  
  Ntag_I2C_Registers.mock(){
    _delegate = {};
    Manufacture = 'm';
    FD_OFF = 'fd off';
    FD_ON = 'fd on';
    NDEF_Message = 'ndef message';
    NDEF_Message_BYTES = Uint8List.fromList([]);
    NDEF_RAW_RECORD = NtagRawRecord.mock();
  }
  Ntag_I2C_Registers.fromMap(Map data) {
    guard(() {
      _delegate = data;
      Manufacture = put(data, ERegister.Manufacture) as String;
      FD_OFF = put(data, ERegister.FD_OFF) as String;
      FD_ON = put(data, ERegister.FD_ON) as String;
      NDEF_Message = put(data, ERegister.NDEF_Message) as String;
      NDEF_Message_BYTES = put(data, ERegister.NDEF_Message_BYTES, Uint8List.fromList([])) as Uint8List;
      I2C_CLOCK_STR = put(data, ERegister.I2C_CLOCK_STR) as bool;
      I2C_LOCKED = put(data, ERegister.I2C_LOCKED) as bool;
      I2C_RST_ON_OFF = put(data, ERegister.I2C_RST_ON_OFF) as bool;
      NDEF_DATA_READ = put(data, ERegister.NDEF_DATA_READ) as bool;
      PTHRU_DIR = put(data, ERegister.PTHRU_DIR) as bool;
      PTHRU_ON_OFF = put(data, ERegister.PTHRU_ON_OFF) as bool;
      RF_FIELD_PRESENT = put(data, ERegister.RF_FIELD_PRESENT) as bool;
      RF_LOCKED = put(data, ERegister.RF_LOCKED) as bool;
      SRAM_I2C_READY = put(data, ERegister.SRAM_I2C_READY) as bool;
      SRAM_MIRROR_ON_OFF = put(data, ERegister.SRAM_MIRROR_ON_OFF) as bool;
      SRAM_RF_READY = put(data, ERegister.SRAM_RF_READY) as bool;
      LAST_NDEF_PAGE = put(data, ERegister.LAST_NDEF_PAGE) as int;
      Mem_size = put(data, ERegister.Mem_size) as int;
      SM_Reg = put(data, ERegister.SM_Reg) as int;
      WD_LS_Reg = put(data, ERegister.WD_LS_Reg) as int;
      WD_MS_Reg = put(data, ERegister.WD_MS_Reg) as int;

      final record =  put(data, ERegister.NDEF_RAW_RECORD, {}) as Map;
      NDEF_RAW_RECORD = NtagRawRecord.fromMap(record);
    }, 'create Ntag_I2C_Registers fromMap failed');
  }

  @override String toString(){
  	if (_delegate != null)
  		return stringfyMap(_delegate);
		if (NDEF_RAW_RECORD != null)
			return "instance Ntag_I2C_Registers( ${NDEF_RAW_RECORD.asMap()} )";
		return "instance Ntag_I2C_Registers()";
	}
}

dynamic put<T>(Map data, T k, [dynamic _default]) {
  final key = ename(k);
  final result = data[key] ?? _default ?? null;
	print("\t\t$key: ${data[key]?.runtimeType} $result");
  return result;
}
