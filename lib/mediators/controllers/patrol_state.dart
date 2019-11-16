import 'package:dio/dio.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_bloc.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';


enum EPatrolEvent {
	undoCfg,
	redoCfg,
	loadCfgFinished,
	loadCfg,
	add,
	edit,
	createConfig,
	delCfg,
	editCfg,
	receiveCfgTarget,
	redo,
	undo,
	browse,
	discard,
	receive,
	next,
	prev,
	del,
	upload,
	uploadFinished,
	promptUpload,
	browseResult,
	save,
	saveFinished,
	load,
	loadFinished,
	promptLoad,
	syncConflict,
	resolveConflict,
	validationError,
	setState
}


abstract class PatrolEvents {
	List<bool> confirmConflict;
	bool undoable;
	int tag_order;
	String path;
	String message;
	String key;
	dynamic value;
	PatrolRecordModel model;
	Response response;
	EPatrolEvent event;
	bool onDel;
	PromptAnswer answer;
	int page;
	int max_num;
	int queryid;
	EQtype querytype;
}


class PatrolSetStateEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.setState;
}

class PatrolPromptLoadEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.promptLoad;
}

class PatrolCfgLoadEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.loadCfg;
	@override PromptAnswer answer;
	@override String path;
	
	PatrolCfgLoadEvent({this.answer, this.path});
}

class PatrolLoadEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.load;
	@override PromptAnswer answer;
	@override String path;
	
	PatrolLoadEvent({this.answer, this.path});
}

class PatrolSaveEvent extends PatrolEvents {
	@override String path;
	@override EPatrolEvent event = EPatrolEvent.save;
	
	PatrolSaveEvent({this.path});
}

class PatrolSaveFinishedEvent extends PatrolEvents {
	@override String message;
	@override EPatrolEvent event = EPatrolEvent.saveFinished;
	
	PatrolSaveFinishedEvent(this.message);
}

class PatrolCfgReceiveEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override EPatrolEvent event = EPatrolEvent.receiveCfgTarget;
	
	PatrolCfgReceiveEvent(this.model);
}

class PatrolReceiveEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override EPatrolEvent event = EPatrolEvent.receive;
	
	PatrolReceiveEvent(this.model);
}

class AddPatrolEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override EPatrolEvent event = EPatrolEvent.add;
	
	AddPatrolEvent(this.model);
}


class PatrolCfgCreateEvent extends PatrolEvents {
	@override String path;
	@override PatrolRecordModel model;
	@override EPatrolEvent event = EPatrolEvent.createConfig;
	
	PatrolCfgCreateEvent(this.model, {this.path});
}

class EditPatrolEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override EPatrolEvent event = EPatrolEvent.edit;
	@override String key;
	@override dynamic value;
	
	EditPatrolEvent(this.key, this.value, this.model);
}

class EditPatrolCfgEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override EPatrolEvent event = EPatrolEvent.editCfg;
	@override String key;
	@override dynamic value;
	
	EditPatrolCfgEvent(this.key, this.value, this.model);
}


class DelPatrolCfgEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override int tag_order;
	@override EPatrolEvent event = EPatrolEvent.delCfg;
	
	DelPatrolCfgEvent(this.model, this.tag_order);
}


class DelPatrolEvent extends PatrolEvents {
	@override PatrolRecordModel model;
	@override int tag_order;
	@override EPatrolEvent event = EPatrolEvent.del;
	
	DelPatrolEvent(this.model, this.tag_order);
}

class PatrolPromptUploadEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.promptUpload;
	
	PatrolPromptUploadEvent();
}

class PatrolUploadEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.upload;
	@override PromptAnswer answer;
	
	PatrolUploadEvent(this.answer);
}

class PatrolUploadFinishedEvent extends PatrolEvents {
	@override String message;
	@override Response response;
	@override bool onDel;
	@override EPatrolEvent event = EPatrolEvent.uploadFinished;
	
	PatrolUploadFinishedEvent(this.message, this.response, this.onDel);
}

class PatrolCfgLoadFinishedEvent extends PatrolEvents {
	@override String message;
	@override EPatrolEvent event = EPatrolEvent.loadCfgFinished;
	
	PatrolCfgLoadFinishedEvent(this.message);
}

class PatrolLoadFinishedEvent extends PatrolEvents {
	@override String message;
	@override EPatrolEvent event = EPatrolEvent.loadFinished;
	
	PatrolLoadFinishedEvent(this.message);
}

class PatrolRedoEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.redo;
	
	PatrolRedoEvent();
}

class PatrolUndoEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.undo;
	
	PatrolUndoEvent();
}

class PatrolCfgRedoEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.redoCfg;
	
	PatrolCfgRedoEvent();
}

class PatrolCfgUndoEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.undoCfg;
	
	PatrolCfgUndoEvent();
}

enum EQtype {
	type,
	user,
	date
}

class PatrolBrowseEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.browse;
	@override int page;
	@override int max_num;
	@override int queryid;
	@override EQtype querytype;
	
	PatrolBrowseEvent(this.page,
			{this.max_num = 5, this.querytype = EQtype.date, this.queryid});
}

class PatrolBrowseResultEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.browseResult;
	@override Response response;
	@override int page;
	@override int max_num;
	
	PatrolBrowseResultEvent(this.response, this.page, [this.max_num = 5]);
}


class PatrolDiscardEvent extends PatrolEvents {
	@override int tag_order;
	@override EPatrolEvent event = EPatrolEvent.discard;
	@override PatrolRecordModel model;
	@override bool undoable;
	
	PatrolDiscardEvent(this.tag_order, this.model, this.undoable);
}

class PatrolPrevEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.prev;
	
	PatrolPrevEvent();
}

class PatrolNextEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.next;
	
	PatrolNextEvent();
}

class SyncConflictPatrolEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.syncConflict;
	
	SyncConflictPatrolEvent();
}

class ResolvedSyncConflictPatrolEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.resolveConflict;
	@override List<bool> confirmConflict;
	
	ResolvedSyncConflictPatrolEvent(this.confirmConflict);
}

class ValidationErrorPatrolEvent extends PatrolEvents {
	@override EPatrolEvent event = EPatrolEvent.validationError;
	@override Response response;
	
	ValidationErrorPatrolEvent(this.response);
}


class BasePatrolState {
	String path;
	List<bool> confirmConflict;
	Response response;
	PatrolRecordModel model;
	String message;
	String key;
	int page;
	dynamic value;
	PromptAnswer answer;

/*@override bool operator ==(other) {
      return (other.runtimeType == this.runtimeType)
         && (other?)
   }*/
}

class PatrolStateSetState extends BasePatrolState {
}

class DefaultPatrolState extends BasePatrolState {
	DefaultPatrolState() {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolStateBrowse extends BasePatrolState {
	int page;
	
	PatrolStateBrowse(this.page) {
		//AppState.processing = BgProc.onLoad;
	}
}

class PatrolStateBrowseResult extends BasePatrolState {
	@override Response response;
	@override int page;
	
	PatrolStateBrowseResult(this.response, this.page) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolSaveState extends BasePatrolState {
	PatrolSaveState() {
		//AppState.processing = BgProc.onSave;
	}
}

class PatrolSaveFinishedState extends BasePatrolState {
	@override String message;
	
	PatrolSaveFinishedState(this.message) {
		//AppState.processing = BgProc.onIdle;
	}
}

class AddPatrolState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	AddPatrolState(this.model) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolCfgCreateState extends BasePatrolState {
	@override PatrolRecordModel model;
	@override String path;
	
	PatrolCfgCreateState(this.model, {this.path}) {
		//AppState.processing = BgProc.onIdle;
	}
	
	Map<String, dynamic> asMap() {
		final ret = model.asMap();
		ret['path'] = path;
		return ret;
	}
	
	
}

class PatrolReceiveState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	PatrolReceiveState(this.model) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolCfgReceiveState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	PatrolCfgReceiveState(this.model) {
		//AppState.processing = BgProc.onIdle;
	}
}


class PatrolCfgUnitEditState extends BasePatrolState {
	@override String key;
	@override dynamic value;
	@override PatrolRecordModel model;
	
	PatrolCfgUnitEditState(this.key, this.value, this.model) {
		//AppState.processing = BgProc.onLoad;
	}
}

class EditPatrolUnitState extends BasePatrolState {
	@override String key;
	@override dynamic value;
	@override PatrolRecordModel model;
	
	EditPatrolUnitState(this.key, this.value, this.model) {
		//AppState.processing = BgProc.onLoad;
	}
}

class PatrolDelState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	PatrolDelState(this.model) {
		//AppState.processing = BgProc.onLoad;
	}
}


class PatrolDiscardState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	PatrolDiscardState(this.model) {
		//AppState.processing = BgProc.onIdle;
	}
}


class PatrolPromptUploadState extends BasePatrolState {
	PatrolPromptUploadState() {
		//AppState.processing = BgProc.onPrompt;
	}
}

class PatrolUploadState extends BasePatrolState {
	@override PromptAnswer answer;
	
	PatrolUploadState(this.answer) {
		//AppState.processing = BgProc.onUpload;
	}
}

class PatrolUploadFinishedState extends BasePatrolState {
	@override String message;
	@override Response response;
	
	PatrolUploadFinishedState(this.message, this.response) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolLoadFinishedState extends BasePatrolState {
	@override String message;
	
	PatrolLoadFinishedState(this.message) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolCfgLoadFinishedState extends BasePatrolState {
	@override String message;
	
	PatrolCfgLoadFinishedState(this.message) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolRedoState extends BasePatrolState {
	PatrolRedoState() {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolUndoState extends BasePatrolState {
	PatrolUndoState() {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolCfgRedoState extends BasePatrolState {
	PatrolCfgRedoState() {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolCfgUndoState extends BasePatrolState {
	PatrolCfgUndoState() {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolNextState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	PatrolNextState(this.model) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolPrevState extends BasePatrolState {
	@override PatrolRecordModel model;
	
	PatrolPrevState(this.model) {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolCfgLoadState extends BasePatrolState {
	@override PromptAnswer answer;
	@override String path;
	
	PatrolCfgLoadState(this.answer, {this.path}) {
		//AppState.processing = BgProc.onLoad;
	}
	
	Map<String, dynamic> asMap() {
		final ret = model.asMap();
		ret['path'] = path;
		return ret;
	}
	
	PatrolCfgLoadState.fromMap(Map<String, dynamic> data){
		model = PatrolRecordModel.fromMap(data);
		path = data['path'] as String;
	}
}

class PatrolLoadState extends BasePatrolState {
	@override PromptAnswer answer;
	
	PatrolLoadState(this.answer) {
		//AppState.processing = BgProc.onLoad;
	}
}

class PatrolPromptLoadState extends BasePatrolState {
	PatrolPromptLoadState() {
		//AppState.processing = BgProc.onPrompt;
	}
}


class PatrolStateSyncConflict extends BasePatrolState {
	PatrolStateSyncConflict() {
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolStateResolveSyncConflict extends BasePatrolState {
	PatrolStateResolveSyncConflict(List<bool> confirmConflict) {
		this.confirmConflict = confirmConflict;
		//AppState.processing = BgProc.onIdle;
	}
}

class PatrolStateValidationError extends BasePatrolState {
	@override Response response;
	
	PatrolStateValidationError(this.response) {
		//AppState.processing = BgProc.onIdle;
	}
}


class _PatrolFieldPermission {
	final bool id;
	final bool setup;
	final bool hh;
	final bool mm;
	final bool ss;
	final bool type1;
	final bool type2;
	final bool inject1;
	final bool inject2;
	final bool patrol1;
	final bool patrol2;
	final bool temperature;
	final bool voltage;
	final bool pressure1;
	final bool pressure2;
	final bool status1;
	final bool status2;
	final bool status3;
	final bool status4; // 19
	final bool motor; // 20
	final bool command; // 21
	final bool devid1; // 22
	final bool devid2; // 23
	final bool devid3; // 24
	final bool rest; // 25, 26, ...32
	final bool areaSection;
	final bool nameSection;
	
	const _PatrolFieldPermission({
		this.id = false, this.setup = false, this.hh = false, this.mm = false, this.ss = false,
		this.type1 = false, this.type2 = false, this.patrol1 = false, this.patrol2 = false,
		this.inject1 = false, this.inject2 = false, this.temperature = false, this.voltage = false,
		this.pressure1 = false, this.pressure2 = false, this.status1 = false, this.status2 = false,
		this.status3 = false, this.status4 = false, this.motor = false, this.command = false,
		this.devid1 = false, this.devid2 = false, this.devid3 = false, this.rest = false,
		this.areaSection = false, this.nameSection = false,
	});
	
	
}



class PatrolFieldPermission extends _PatrolFieldPermission {
	static const PatrolFieldPermission patrol = PatrolFieldPermission._patrol();
	static const PatrolFieldPermission boot = PatrolFieldPermission._switchOn();
	static const PatrolFieldPermission shutdown = PatrolFieldPermission._switchOff();
	static const PatrolFieldPermission uop = PatrolFieldPermission._uop();
	static const PatrolFieldPermission urst = PatrolFieldPermission._urst();
	static const PatrolFieldPermission initial = PatrolFieldPermission._initial();
	
	@override String toString() {
		if (this == patrol)
			return "<PatrolFieldPermission( patrol )>";
		else if (this == uop)
			return "<PatrolFieldPermission( uop )>";
		else if (this == urst)
			return "<PatrolFieldPermission( urst )>";
		else if (this == initial)
			return "<PatrolFieldPermission( initial )>";
		return "<PatrolFieldPermission( ? )>";
	}
	
	const PatrolFieldPermission._patrol();
	const PatrolFieldPermission._switchOn();
	const PatrolFieldPermission._switchOff();
	const PatrolFieldPermission._uop() :super(
			setup: true,
			type2: true,
			nameSection: true,
			areaSection: true);
	const PatrolFieldPermission._urst() :super(
			id: true,
			setup: true,
			hh: true,
			mm: true,
			ss: true,
			type1: true,
			type2: true,
			inject1: true,
			inject2: true,
			patrol1: true,
			patrol2: true,
			voltage: true,
			temperature: true,
			pressure1: true,
			pressure2: true,
			status1: true,
			status2: true,
			status3: true,
			status4: true,
			motor: true,
			nameSection: true,
			areaSection: true
	);
	
	const PatrolFieldPermission._initial() :super(
		id: true,
		setup: true,
		hh: true,
		mm: true,
		ss: true,
		type1: true,
		type2: true,
		inject1: true,
		inject2: true,
		patrol1: true,
		patrol2: true,
		temperature: true,
		voltage: true,
		pressure1: true,
		pressure2: true,
		status1: true,
		status2: true,
		status3: true,
		status4: true,
		motor: true,
		command: true,
		devid1: true,
		devid2: true,
		devid3: true,
		rest: true,
		areaSection: true,
		nameSection: true,
	);


}









