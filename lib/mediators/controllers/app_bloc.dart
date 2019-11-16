import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/activiy_states.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_state.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:common/common.dart' show ELevel, LEVELS, Logger, LoggerSketch;
import 'package:nxp_bloc/mediators/models/debug_model.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/models/userauth_model.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:rxdart/rxdart.dart';

final _D = AppState.getLogger('APPBLC');
List<String> _dumpLogs = [];

const NO_NFC_DEVICE = "NO_NFC_DEVICE";
const NFC_DISABLED = "NFC_DISABLED";
const NFC_AVAILABLE = "NFC_AVAILABLE";

enum ENFCState {
	NO_NFC_DEVICE,
	NFC_DISABLED,
	NFC_AVAILABLE,
	HAS_NFC_FUNCTIONALITY,
	HAS_NONFC_FUNCTIONALITY
}

class AppSetting {
	static bool autoEncode = true;
}

abstract class AppStateDelegate {
	void showLoaded(MsgEvents event);
	
	void showLoadFailed(MsgEvents event);
	
	void showSaved(MsgEvents event);
	
	void showText(MsgEvents event);
	
	void showSaveFailed(MsgEvents event);
	
	void showForm(MsgEvents event);
	
	void showConfirmDialog(MsgEvents event);
	
	void showDiffDialog(MsgEvents event);
	
	void showWarningDialog(MsgEvents event);
	
	void showLoading(MsgEvents event);
	
	void showSaving(MsgEvents event);
	
	void showProgressing();
	
	void onlineMode();
	
	void offlineMode();
}


class AppState {
	//@fmt:off
	AppStateDelegate delegate;
	
	static EIO _IOMode = EIO.patrol;
	static EIO get IOMode => _IOMode;
	static void set IOMode(EIO v){
		_IOMode = v;
		_D.debug('set IOMOde to $v');
	}
	
	
	static bool uilock = false;
	
	static void lockUI() {
		uilock = true;
	}
	
	static void unlockUI() {
		uilock = false;
	}
	
	static void Function()
	call(void Function() call) {
		return () {
			if (!uilock)
				call();
			else
				msg.onWarning("ui locked!");
		};
	}
	
	static void Function(T)
	call1<T>(void Function(T) call) {
		return (T arg) {
			if (!uilock)
				call(arg);
			else
				msg.onWarning("ui locked!");
		};
	}
	
	static ConfigStoreSketch configStore;
	static ENFCState nfcState;
	static AppBloC bloC;
	
	static Permission get permission => UserState.currentUser.permission;
	
	static bool get authenticated => UserState.currentUser.isAuthenticated;
	
	//
	static bool get autoEncode => AppSetting.autoEncode;
	
	static void set autoEncode(bool v) => AppSetting.autoEncode = v;
	
	//
	static Timer get loadingTimer => UserState.manager.loadingTimer;
	
	static int get bytesloaded => UserState.manager.bytesloaded;
	
	static int get bytestotal => UserState.manager.bytestotal;
	
	static int get progress => UserState.manager.progress;
	
	static set bytesloaded(int v) => UserState.manager.bytesloaded = v;
	
	static set loadingTimer(Timer v) => UserState.manager.loadingTimer = v;
	
	static set bytestotal(int v) => UserState.manager.bytestotal = v;
	
	//
	static String get state_message => UserState.manager.state_message;
	
	// static BehaviorSubject<BgProc> processingSink = BehaviorSubject<BgProc>();
	
	
	static set state_message(String v) {
		UserState.manager.state_message = v;
	}
	
	static bool animIO = false;
	
	//
	static MessageBloC msg = MessageBloC();
	
	static bool _offlineMode = false;
	
	static bool get offlineMode => _offlineMode;
	static int _unavailableCounter = 0;
	
	static int get unavailableCounter => _unavailableCounter;
	
	static set unavailableCounter(int v) {
		if (_unavailableCounter > 5) {
			_offlineMode = true;
		}
		_unavailableCounter++;
	}
	
	//@fmt:on
	static void onOnlineMode() {
		msg.onOfflineMode();
	}
	
	static void onOfflineMode() {
		msg.onOfflineMode();
	}
	
	static Future<bool> testNetwork() async {
		final completer = Completer<bool>();
		try {
			final result = await InternetAddress.lookup('google.com');
			if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
				_offlineMode = false;
				completer.complete(true);
			}
		} on SocketException catch (_) {
			_offlineMode = true;
			completer.complete(false);
		}
		return completer.future;
	}
	
	static List<String> get dumpLogs => _dumpLogs;
	
	/*static set dumpLogs(String msg){
		 
	 }*/

	 
	static LoggerSketch getLogger(String name, {bool showOutput = true, bool disabled = false}) {
		if (disabled)
			Logger.disabledModules.add(name);
		
		final result = Logger(
			showOutput: showOutput,
			name: name,
			levels: [
				ELevel.info, ELevel.error, ELevel.debug
			],
			dumpOnMemory: true
		);
		result.memWriter = (msg, newline) {
			_dumpLogs.add(msg);
			if (_dumpLogs.isEmpty) {
				throw Exception("------------------------------------EEEE");
			}
		};
		result.write = (String m, bool newline) {
			if (Logger.disabledModules.contains(result.name))
				return;
			result.memWriter(m, newline);
			if (Logger.disabledModules.contains(result.name)) {
				return;
			}
			print(m);
		};
		return result;
	}
	
	static String time() {
		final t = DateTime.now();
		return "${t.year}${t.month}${t.day}-${t.hour}${t.minute}";
	}
	
	static MsgEvents Function(MsgEvents event) eventCatcher = (MsgEvents event) {
		return event;
	};
	
	/*
   *           N D E F      W R I T E     C O N F I G
   *
   * */
	
	/// static RegExp  writeConfigPtn = RegExp("nxp.writconfig.");
	/// current selected
	static BasePatrolState _selectedConfig;
	
	static BasePatrolState get selectedConfig =>
			_selectedConfig; //note multiple states in one config
	static void set selectedConfig(BasePatrolState v) {
		_selectedConfig = v;
		if (v != null)
			ndefMode = ENdefMode.writeConfigActivated;
		else
			ndefMode = ENdefMode.writeConfigInactivated;
	}
	
	/// ever selected before
	static BehaviorSubject<ENdefMode> ndefModeStream = BehaviorSubject<ENdefMode>();
	static StreamSink <ENdefMode> ndefModeSink = ndefModeStream.sink;
	static ENdefMode rememberdNdefWriteMode;
	static ENdefMode _ndefMode = ENdefMode.read;
	
	static ENdefMode get ndefMode => _ndefMode;
	
	static void set ndefMode(ENdefMode v) {
		if (v != ENdefMode.read)
			rememberdNdefWriteMode = v;
		if (v == ENdefMode.writeConfigInactivated)
			_selectedConfig = null;
		_ndefMode = v;
		ndefModeSink.add(v);
	}
	
	AppState(this.delegate);
	
	static Future<List<Map<String, dynamic>>> onStart() async {
		final result = await UserState.load(unsaved: false);
		_D.info('loading user auth: $result');
		return result;
	}
	
	static final String SAVING_ID = uuid.v4();
	static final String LOADING_ID = uuid.v4();
	static final String DEBUG_UP_ID = uuid.v4();
	
	static Future<String> onDumpForDebug(Map<String, dynamic> body) async {
		_D.info(body);
		PatrolState.manager.msg.bloC.onFileUploading(DEBUG_UP_ID);
		return await Http().dioPost('/debug', body: body).then((res) {
			if (res.statusCode == 200) {
				final server = Http.host;
				final port = Http.port;
				final id = res.data['id'];
				return 'http://$server:$port/debug/id/$id';
			} else {
				PatrolState.manager.msg.bloC.onInferNetworkError(
						res.statusCode, DEBUG_UP_ID, null);
			}
		}).catchError((e) {
			PatrolState.manager.msg.bloC.onFileUploadingFailed(
					"timeout, server not responding", DEBUG_UP_ID);
		});
	}
	
	static Future<String> dumpAllLogsToServer(List<String> files) async {
		//rewrite into bloc??
		final log = AppState.dumpLogs;
	}
}

enum ENdefMode {
	read,
	writeConfigInactivated,
	writeConfigActivated,
}


class AppBloC extends Bloc<MsgEvents, MsgEvents> {
	static AppBloC instance;
	MsgEvents last_event;
	
	AppBloC.empty();
	
	factory AppBloC(){
		if (instance != null)
			return instance;
		return instance = AppBloC.empty();
	}
	
	@override MsgEvents
	get initialState {
		AppState.bloC = this;
		return AppDefaultEvent();
	}
	
	@override
	Stream<MsgEvents> mapEventToState(MsgEvents event) async* {
		if (event == last_event)
			yield null;
		last_event = event;
		final result =  AppState.eventCatcher(event);
		_D('app yield: ${result.runtimeType}/${event.runtimeType} ${event.message}');
		yield result;
	}
	
	//todo:
	void onOfflineMode(String msg) {
		if (AppState.offlineMode == false) {
			AppState._offlineMode = true;
			dispatch(AppOfflineModeEvent());
		}
	}
	
	//todo:
	void onOnlineMode(String msg) {
		if (AppState.offlineMode == true) {
			_D('turn onlineMode');
			AppState._offlineMode = false;
			dispatch(AppOnlineModeEvent());
		}
	}
	
	void onDispatch(MsgEvents event) {
		_D('send ${event.runtimeType}, msg:${event.message}, id: ${event.id}');
		dispatch(event);
	}
}


class AppPermissionDenied extends MsgEvents {
	AppPermissionDenied() :super(message: Msg.PermissionDenied);
}

class AppLoginFirst extends MsgEvents {
	AppLoginFirst() :super(message: Msg.permissionLogin(null));
}

class AppFieldPermissionDenied extends MsgEvents {
	AppFieldPermissionDenied(String field)
			:super(message: Msg.fieldPermissionDenied(field));
}


class AppSetState extends MsgEvents {
	void Function() cb;
	
	AppSetState(this.cb);
}

class AppRestartEvent extends MsgEvents {
	AppRestartEvent(String message): super(message: message);
}

class AppIdleEvent extends MsgEvents {
}

class AppOnlineModeEvent extends MsgEvents {
}

class AppOfflineModeEvent extends MsgEvents {
}

class AppCrashEvent extends MsgEvents {
	@override String message;
	
	AppCrashEvent(this.message);
}

class AppShowFeatureNotImplemented extends MsgEvents {
	@override String message;
	
	AppShowFeatureNotImplemented(this.message);
}


class AppNtagWriting extends MsgEvents {
	AppNtagWriting() :super(message: Msg.onWritingNtag);
}

class AppNtagSuccesfullyWritten extends MsgEvents {
	AppNtagSuccesfullyWritten() :super(message: Msg.onNtagSuccessfullyWritten);
}

class AppNtagWritingFailed extends MsgEvents {
	AppNtagWritingFailed() :super(message: Msg.onWriteNtagError);
}

class AppNtagReading extends MsgEvents {
	AppNtagReading() : super(message: Msg.onReadingNtag);
}

class AppNtagSuccessfullyRead extends MsgEvents {
	AppNtagSuccessfullyRead() : super(message: Msg.onReadingNtagSuccess);
	
}

class AppNtagReadingFailed extends MsgEvents {
	AppNtagReadingFailed() : super(message: Msg.onReadingNtagFailed);
}


class AppShowScanning extends MsgEvents {
	@override EMsgType msg_type = EMsgType.loading;
	@override String message;
	
	AppShowScanning(this.message);
}

class AppCloseScanning extends MsgEvents {
	@override EMsgType msg_type = EMsgType.close;
	AppCloseScanning();
}

class AppShowScanningFailed extends MsgEvents {
	@override EMsgType msg_type = EMsgType.loadFailed;
	@override String message;
	AppShowScanningFailed(String id, {this.message, int duration}):super(
		id: id, message: message ?? Msg.onNFCommunicationError(),
		duration: duration, msg_type: EMsgType.loadFailed,
	);
}

class AppShowScanningSuccess extends MsgEvents {
	@override EMsgType msg_type = EMsgType.loaded;
	@override String message;
	
	AppShowScanningSuccess(String id, {this.message, int duration}):super(
		id: id, message: message ?? Msg.onNFCommunicationSuccess,
		duration: duration, msg_type: EMsgType.loaded,
	);
}


class AppShowSaving extends MsgEvents {
	AppShowSaving(String id, {String message, int duration}) :super(
		id: id, message: message ?? Msg.onSaving,
			duration: duration, msg_type: EMsgType.saving);
}

class AppShowSaveFailed extends MsgEvents {
	AppShowSaveFailed(String id, {String message, int duration}) :super(
		id: id, msg_type: EMsgType.saveFailed,
		message: message ?? Msg.onSavingFailed, duration: duration);
}

class AppShowSaved extends MsgEvents {
	AppShowSaved(String id, {String message, int duration}) :super(
		id: id, msg_type: EMsgType.saved,
		message: message ?? Msg.onSaveSuccess,
		duration: duration);
}

class AppCloseSaving extends MsgEvents {
	AppCloseSaving(String id) :super(id: id);
}

class AppShowTextMessenger extends MsgEvents {
	AppShowTextMessenger(MsgEvents event) {
		clone(event);
	}
}

class AppShowLoading extends MsgEvents {
	AppShowLoading(String id, {String message, int duration})
			:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.loadFailed);
}

class AppShowLoadFailed extends MsgEvents {
	AppShowLoadFailed(String id, {String message, int duration})
		:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.loadFailed);
}

class AppShowLoaded extends MsgEvents {
	AppShowLoaded(String id, {String message, int duration})
			:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.loaded);
}

class AppCloseLoading extends MsgEvents {
	AppCloseLoading(String id) :super(id: id);
}

class AppDialogWarning extends MsgEvents{
	AppDialogWarning(String id, String message): super(id: id, message: message);
}

class AppShowConfirm extends MsgEvents {
	AppShowConfirm([MsgEvents event]) {
		clone(event);
	}
}

// infer whether to close saving or loading...
class AppCloseXing extends MsgEvents {
	AppCloseXing(String id) :super(id: id);
}

class AppShowDiff extends MsgEvents {
	@override Map<String, dynamic> diffA;
	@override Map<String, dynamic> diffB;
	
	AppShowDiff(this.diffA, this.diffB);
}

class AppShowProgressing extends MsgEvents {
	@override int progress;
	
	AppShowProgressing([this.progress]);
}

class AppShowTrying extends MsgEvents {
	@override int cycleTime;
	@override int maxRetries;
	
	AppShowTrying(this.cycleTime, this.maxRetries, [MsgEvents event]) {
		clone(event);
	}
}

class AppShowSeeking extends MsgEvents {
	@override int cycleTime;
	
	AppShowSeeking(this.cycleTime, [MsgEvents event]) {
		clone(event);
	}
}


class AppNFCServiceDead extends MsgEvents {
}

class AppJavaException extends MsgEvents {
	@override String message;
	
	AppJavaException(this.message);
}

class AppMessage extends MsgEvents {
	@override String message;
	@override EMsgType msg_type = EMsgType.stack;
	AppMessage(this.message);
}

class AppInfoMessage extends MsgEvents {
	@override String message;
	@override EMsgType msg_type = EMsgType.stack;
	AppInfoMessage(String id, {this. message, int duration})
			:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.stack);
}

class AppWarningMessage extends MsgEvents {
	@override String message;
	@override EMsgType msg_type = EMsgType.stack;
	AppWarningMessage(String id, {this. message, int duration})
			:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.stack);
}

class AppShowWarningEvent extends MsgEvents {
	@override String message;
	@override EMsgType msg_type = EMsgType.stack;
	AppShowWarningEvent(String id, {this. message, int duration})
			:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.stack);
}

class AppErrorMessage extends MsgEvents {
	@override String message;
	@override EMsgType msg_type = EMsgType.stack;
	AppErrorMessage(String id, {this. message, int duration})
			:super(id: id,
			message: message,
			duration: duration,
			msg_type: EMsgType.stack);
}


class AppDefaultEvent extends MsgEvents {
}

class AppCloseNoNfcEvent extends MsgEvents {
}

class AppShowSettingNoNfcEvent extends MsgEvents {
}

class AppNFCAvailableEvent extends MsgEvents {
}

class AppShowForm extends MsgEvents {
}

class AppNFCTransceiveFailed extends MsgEvents {
}

class AppNFCTagLost extends MsgEvents {
}











