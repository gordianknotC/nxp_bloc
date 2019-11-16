import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:PatrolParser/PatrolParser.dart';
import 'package:bloc/bloc.dart';
import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/common_states_manager.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_state.dart';
import 'package:nxp_bloc/mediators/controllers/permission.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/consts/server.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:rxdart/rxdart.dart';


final debug = AppState.getLogger('Patrol');

class PatrolMainStatePost<ST extends BasePatrolState> extends BasePostService<ST> {
   @override BaseStatesManager<ST> manager;
   @override BaseValidationService<ST> validator;
   @override BaseMessageService msgbloC;
   @override String del_request_path;
   @override String post_request_path;
   @override String merge_request_path;
   
   PatrolMainStatePost(this.post_request_path, this.del_request_path,
                       this.merge_request_path, this.msgbloC, this.validator, this.manager)
      : super(post_request_path, del_request_path, merge_request_path, msgbloC, validator, manager);
   
   @override List<Map<String, dynamic>> getUploadData({List<int> ids}) {
      final result = <Map<String, dynamic>>[];
      // fixme: sates_forUi
      manager.states_forUi.forEach((k, List<BasePatrolState>v) {
         if (ids == null)
            result.add(v.last.model.asMap());
         else if (ids.contains(k))
            result.add(v.last.model.asMap());
      });
      return result;
   }
}

class PatrolMainStateGet<ST extends BasePatrolState> extends BaseGetService<ST> {
   PatrolMainStateGet(this.get_request_path, this.manager) : super(get_request_path, manager);
   @override String get_request_path;
   @override BaseStatesManager<ST> manager;
   
   @override Future<Response> onGet({Map<String, dynamic> query, int retries = 1, bool isCached = true}) async {
      return null;
      return await Http().dioGet(get_request_path, isCached: false, qparam: query);
   }




}

class PatrolMainStateValidator<ST extends BasePatrolState> extends BaseValidationService<ST> {
   PatrolMainStateValidator(this.manager, this.get) : super(manager, get);
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   
   @override bool validate(ST state, List<Map<String, dynamic>> source) {
      state.model.validate(source);
      return !state.model.hasValidationErrors;
   }
}

class PatrolMainStateStore<ST extends BasePatrolState> extends BaseStoreService<ST> {
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   @override String unsavedpath;
   @override String localpath;
   
   PatrolMainStateStore(this.localpath, this.unsavedpath, this.manager, this.get)
      : super(localpath, unsavedpath, manager, get);

   @override
   Future<StoreInf> write({bool unsaved = true, String path}) {
      final data = jsonEncode(finaldata);
      debug("write content: $data");
      return manager.file(path ?? localpath).writeAsync(data);
   }
   @override
   List beforeDump(List<BasePatrolState> states, dynamic json) {
      List<Map<String, dynamic>> dataOnServer;
      List<PatrolRecordModel> options;
      try{
         if (json != null)
            dataOnServer = List<Map<String, dynamic>>.from(json as List);
         options = states.map((state) => state.model).toList();
         final localdata = options.map((option) => option.asMap()).toList();
         debug('file to be dump:$localdata');
         if (localdata.isNotEmpty)
            debug('dump keys: ${localdata.map((m) => '${m['id']}, ${m['device_id']}').toString()}');
         return localdata;
      }catch(e){
         final str = "Failed to prepare data before dump, "
            "states to be dump: $states\n"
            "json: $json\n"
            "dataOnServer: $dataOnServer\n"
            "options: $options\n"
            "\n${StackTrace.fromString(e.toString())}";
         debug.error(str);
         throw Exception(str);
      }
   }
   @override
   List<ST> getStatesToBeDump() {
      return manager.states_forUi.values.map((v) => v.last).toList();
   }
   
   
}

class PatrolMainStateConverter<ST extends BasePatrolState> extends BaseStateConverter<ST> {
   PatrolMainStateConverter(this.manager) : super(manager);
   @override BaseStatesManager<ST> manager;
   
   @override ST mapDataToState(Map<String, dynamic> data) {
      /*final int id     = data['id'];
      final machine_id = data['machine_id'];
      data['id']   = machine_id;
      final patrol = PatrolRecord.fromJson(data);
      final model  = PatrolRecordModel(patrol);
      model.id     = id;*/
      final model = PatrolRecordModel.fromMap(data);
      return (BasePatrolState()..model = model) as ST;
   }
   
   @override Map<String, dynamic> mapStateToData(BasePatrolState state, {bool considerValidation = false}) {
      return state.model.asMap(considerValidation: considerValidation);
   }
}

class PatrolMainStateMatcher<ST extends BasePatrolState> extends BaseStateMatcher<ST> {
   @override bool uploadMatcher(ST state) => state is PatrolUploadState;
   
   @override bool redoMatcher(ST state) => state is PatrolRedoState;
   
   @override bool undoMatcher(ST state) => state is PatrolUndoState;
   
   @override bool delMatcher(ST state) => state is PatrolDelState;
   
   @override bool discardMatcher(ST state) => state is PatrolDiscardState;
   
   @override int idGetter(ST state) => state.model.id;
   
   @override int idSetter(ST state, int id) => state.model.id = id;
   
   @override void clearId(ST state) => state.model.id = null;
}

class PatrolMainStateRemembrance<ST extends BasePatrolState> extends HistoryService<ST> {
   PatrolMainStateRemembrance(BaseStatesManager<ST> manager, int length) : super(manager, length);
   @override
   ST afterSaveStateHistory() {
      PatrolState.inferCurrentPatrol();
      final currentId = PatrolState.currentId;
      /*var currentId = PatrolState.currentId;
      if (currentId == null || currentId == -1){
         PatrolState.inferCurrentPatrol();
      }*/
      final data = {
         'currentId': currentId,
         'prevId': PatrolState.prevId
      };
      registeryHistory.add(data, 'currentId');
      return super.afterSaveStateHistory();
  }
  
  void guardIdRecover(){
     final ids = registeryHistory.getCurrent('currentId') as Map<String,dynamic>;
     if (ids == null)
        return;
     try{
        PatrolState.restoreCurrentIdViaHistory(ids);
     }catch(e){
        final str = 'recover currentId failed!'
           '\nrecovered ids: $ids, currentStates: ${PatrolState.states.keys.toList()}'
           '\n${StackTrace.fromString(e.toString())}';
        debug.error(str);
        throw Exception(str);
     }
  }
  
   @override
   void clearAndSaveHistory() {
      super.clearAndSaveHistory();
      registeryHistory.resetHistory();
      registeryHistory.registerHistory(JsonHistory(stateHistory.stack.length), 'currentId');
      afterSaveStateHistory();
   }
   @override
   Map<String, dynamic> undo() {
      final res = super.undo();
      registeryHistory.undo('currentId');
      guardIdRecover();
      return res;
   }

   @override
   Map<String, dynamic> redo() {
      final res = super.redo();
      registeryHistory.redo('currentId');
      guardIdRecover();
      return res;
   }
}

class PatrolMainStateManager<ST extends BasePatrolState> extends BaseStatesManager<ST> {
   @override BaseStateConverter<ST> converter;
   @override BaseStateMatcher<ST> matcher;
   @override BaseStateProgress progressor;
   @override StoreInf Function(String path) file;
   @override ConfigInf config;

   PatrolMainStateManager(this.config, this.file, {this.converter, this.matcher, this.progressor,void onInitialError(e)})
      : super(converter, matcher, progressor) {
      PatrolState.manager = this;
      converter = PatrolMainStateConverter(this);
      matcher = PatrolMainStateMatcher();
      progressor = BaseStateProgress();
      final localpath = 'nxp.db.offline.tag.json';
      //final unsavedpath = 'nxp.db.offline.tag.unsaved.json';
      final get_request_path = '/${ename(ROUTE.rawtag)}';
      final post_request_path = '/${ename(ROUTE.rawtag)}/batch/';
      final del_request_path = '/${ename(ROUTE.rawtag)}/del/';
      final msgBloC = MessageBloC();
      
      msg = BaseMessageService(msgBloC, this);
      get = BaseGetService(get_request_path, this);
      post = PatrolMainStatePost(
         post_request_path, del_request_path,
         null, msg,
         PatrolMainStateValidator(this, get), this
      );
      store = PatrolMainStateStore(localpath, null, this, get);
      remember = PatrolMainStateRemembrance(this, config.app.history);
      remember.registerHistory(JsonHistory(remember.stateHistory.stack.length), 'currentId');
   }
   @override
  Future fetchInitialData() {
    return Future.value(get.initialData);
  }

   @override ST saveState(ST state, int id, {bool addToUnsaved = false, ST slave}) {
      /*if (states_forUi.values.any((s) => s.last.model.patrol.getDevId().last == state.model.patrol.getDevId().last)){
      }*/
      return super.saveState(state, id, addToUnsaved: addToUnsaved, slave: slave);
  }
}


class PatrolStateCache {
   static PatrolStateCache instance;
   static Map<String, Response> cache = {};
   PatrolStateCache._();
   factory PatrolStateCache(){
      if (instance != null)
         return instance;
      
      PatrolState.bloC.state.listen((s){
         if (s is PatrolUploadFinishedState){
            if (s.response.statusCode == 200)
               cache = {};
         }
      });
      return PatrolStateCache._();
   }
   
   Future<Response>
   cacheAndSet(String key, Future<Response> cb())   {
   		final completer = Completer<Response>();
      print('cache key: $key');
      if (get(key) != null){
				completer.complete(get(key));
			}else{
				cb().then((result){
					set(key, result);
					completer.complete(result);
				});
			}
      return completer.future;
   }

   Response get(String key){
      print('get $key: ${cache[key]}');
      return cache[key];
   }
   
   void set(String key, Response value){
      if (value.statusCode == 200)
         cache[key] = value;
   }
}




class PatrolCfgState{
	static String localpath = 'nxp.db.tag.config';
	static PatrolBloC bloC;
	static PatrolMainStateManager manager;
	static Map<int, List<BasePatrolState>> get states => manager.states_forUi;
	static PatrolCfgCreateState currentCfgCreation;
	static PatrolRecordModel getModelByTagOrder(int tag_order){
		if (tag_order == -1)
			return null;
		final models = manager.states_forUi.values.map((v) => v.last.model).toList();
		return models[tag_order];
	}
	
	static PatrolRecordModel
	getModelToBeWritten(PatrolRecordModel configured, PatrolRecordModel orig){
		configured.patrol.selectedKeys.forEach((key){
			debug('selected key: $key, value:${configured.patrol.getKeyVal(key, )}');
			orig.patrol.setKeyVal(key, configured.patrol.getKeyVal(key, ), Msg.codec);
			debug('get key: $key, value:${orig.patrol.getKeyVal(key, )}');
		});
		return PatrolRecordModel.fromMap(orig.asMap());;
	}
	
	static Future<bool> saveConfig(PatrolCfgCreateState res, [bool showMessages = true]){
		final completer = Completer<bool>();
		final data = res.asMap();
		if (showMessages)
			PatrolState.manager.msg.bloC.onFileSaving(savingId);
		PatrolState.manager.file(res.path).writeAsync(jsonEncode(data)).then((e){
			completer.complete(true);
			if (showMessages)
				PatrolState.manager.msg.bloC.onFileSuccessfullySaved(savingId);
		}).catchError((e){
			completer.complete(false);
			if (showMessages)
				PatrolState.manager.msg.bloC.onFileSavingFailed(savingId);
		});
		return completer.future;
	}
	
	static Future<bool> delConfig(String path){
		final completer = Completer<bool>();
		PatrolState.manager.msg.bloC.onDispatch(MsgOnDelFile());
		PatrolState.manager.file(path).existsAsync().then((e){
			if (e){
				PatrolState.manager.file(path).deleteSync();
				PatrolState.manager.msg.bloC.onDispatch(MsgOnDelFile());
				completer.complete(true);
			} else{
				PatrolState.manager.msg.bloC.onDispatch(MsgOnDelFileNotFound());
				completer.complete(false);
			}
		}).catchError((e){
			PatrolState.manager.msg.bloC.onDispatch(MsgOnDelFileFailed());
			completer.complete(false);
		});
		return completer.future;
	}
	
	static BasePatrolState
	createConfig(PatrolCfgCreateEvent event){
		debug('createConfig -> ${event.model.patrol.getDevId()}');
		final result = PatrolCfgCreateState(event.model);
		final id     = manager.inferId(event.model.machine_id.last);
		result.model.id = id;
		final ret = manager.saveState(
				result, id, addToUnsaved: true);
		return currentCfgCreation = ret as PatrolCfgCreateState;
	}
	
	// recieve tag while in write mode
	static BasePatrolState
	receiveSource(PatrolCfgReceiveEvent event) {
		debug('receiveSource -> ${event.model.patrol.getDevId()}');
		final result = PatrolCfgReceiveState(event.model);
		final id     = manager.inferId(event.model.machine_id.last);
		result.model.id = id;
		return result;
	}
	
	static BasePatrolState
	del(DelPatrolCfgEvent event) {
		debug('PatrolCfgState.del -> ${event.tag_order}, ${event.model.patrol.getDevId()}');
		final state = states.values.firstWhere((v) =>
         v.last.model.patrol.getDevId().last == event.model.patrol.getDevId().last,
         orElse: () => throw Exception("uncuahgt error")
      );
		states.removeWhere((k, v) => v.last == state.last);
		final result =  manager.saveState(
				state.last,
				event.model.patrol.getDevId().last,
				addToUnsaved: false);
		return result;
	}
	
	static BasePatrolState
	edit(EditPatrolCfgEvent event) {
		debug('PatrolCfgState.edit -> ${event.model}');
		final result = manager.saveState(
				PatrolCfgUnitEditState(event.key, event.value, event.model),
				event.model.patrol.getDevId().last,
				addToUnsaved: true
		);
		final state = states.values.firstWhere((v) => v.last.model.id == event.model.id,
				orElse: () => throw Exception('Uncuahgt Error'));
		return result;
	}
	
	static BasePatrolState
	redoCfg(PatrolCfgRedoEvent event) {
		final result = manager.saveState(
				PatrolCfgRedoState(), null, addToUnsaved: false
		);
		return result;
	}
	
	static BasePatrolState
	undoCfg(PatrolCfgUndoEvent event) {
		final result = manager.saveState(
				PatrolCfgUndoState(), null, addToUnsaved: false
		);
		return result;
	}
   
   static final String savingId = uuid.v4();
   static final String uploadingId = uuid.v4();
   static final String loadingId = uuid.v4();
   
	static BasePatrolState
	load(PatrolCfgLoadEvent event){
		final answer = event.answer;
		if (answer.cancel)
			return null;
		// todo:
		//    1) load data discard all changes
		//    2) load data incorporate existing changes;
		if (manager.file(event.path ?? manager.store.localpath).existsSync()){
			manager.store.load(path: event.path).then((res) async {
				final content = List<Map<String,dynamic>>.from(res as List);
				final logcontent = content.map((c){
					final data = c.toString();
					return "${data.substring(0, min(data.length, 15))}...";
				}).toList();
				debug('load saved file: $logcontent, ${manager.file(event.path ?? manager.store.localpath).getPath()}');
				await manager.loadLastSavedStatesAndMergeIntoUi(content:content, answer: answer.answers.first, byCache: true);
				manager.remember.clearAndSaveHistory();
				manager.msg.bloC.onFileLoadingSuccess(loadingId);
				bloC.onLoadCfgFinished(Msg.OK);
			}).catchError((e){
				debug('failed to load...');
				manager.msg.bloC.onFileLoadingParsingFailed(loadingId);
				raise(StackTrace.fromString(e.toString()));
			});
		}else{
			manager.msg.bloC.onFileNotFound();
		}
		return PatrolCfgLoadState(answer);
	}
	
	static BasePatrolState
	loadFinished(PatrolCfgLoadFinishedEvent event){
		final result = manager.saveState(PatrolCfgLoadFinishedState(Msg.OK), null);
		return result;
	}
}

class ConfigurablePatrolState {
	Map<String, dynamic> configModel;
	Map<String, dynamic> initialModel;
	
	JsonHistory history;
	
	PatrolCfgCreateState get cfg =>
			PatrolCfgCreateState(PatrolRecordModel.fromMap(configModel ?? initialModel));
	
	PatrolRecordModel get initialRecord =>
			initialModel != null ? PatrolRecordModel.fromMap(initialModel) : null;
	
	ConfigurablePatrolState({PatrolCfgCreateState cfg, BasePatrolState currentModel, bool showHistory = false}){
		configModel  = cfg?.asMap();
		initialModel = currentModel?.model?.asMap();
		if (showHistory){
			history = JsonHistory(12, codec: 'utf8');
			history.add(configModel);
		}
	}
	
	void updateCurrentModel(BasePatrolState state){
		initialModel = state.model.asMap();
		debug.info('updateCurrentModel to ${state.runtimeType}');
		debug.critical('updateCurrentModel to ${state.runtimeType}');
	}
	
	void updateConfig(PatrolCfgCreateState state){
		configModel = state.asMap();
	}
	
	void onEdit(PatrolEvents evt){
		configModel = evt.model.asMap();
		(configModel['nullProperties'] as List).remove(evt.key);
		if (history!= null){
			history.add(configModel);
		}
	}
	
	Map<String,dynamic> undo(){
		return history?.undo();
	}
	
	Map<String,dynamic> redo(){
		return history?.redo();
	}
}


//@fmt:off
class PatrolState {
   static final String savingId = uuid.v4();
   static final String uploadingId = uuid.v4();
   static final String loadingId = uuid.v4();
   
	 static Set<int> selectedItemsToBeSaved;

//   static BgProc get processing    => AppState.processing;
   static String get state_message => AppState.state_message;
   static String get file_path     => manager.ident;
//   static        set processing   (BgProc v) => AppState.processing    = v;
   static        set state_message(String v) => AppState.state_message = v;
   static        set file_path    (String v) => manager.ident         = v;
   
   static PatrolMainStateManager manager;
   static Map<int, List<BasePatrolState>> get states => manager.states_forUi;
   
   static Map<int, int>      get unsaved_states  => manager.unsaved_states;
   static List<PatrolRecord> get pendingDiscards => [];
   
   static PatrolRecordModel currentPatrol;
   static PatrolBloC bloC;

   static List<List<Map<String, dynamic>>> conflictStack         = [];
   static List<List<bool>>                 resolvedConflictStack = [];
   
   static PatrolRecordModel
   getModelByTagOrder(int tag_order){
      if (tag_order == -1)
         return null;
      final models = manager.states_forUi.values.map((v) => v.last.model).toList();
      return models[tag_order];
   }

   static onUniquePatrol(PatrolRecord patrol, void cb()){
      if (!states.values.any((state) => state.last.model.patrol.getDevId().last == patrol.getDevId().last)){
         cb();
      }
   }
   static PatrolStateCache cache = PatrolStateCache();
   
   
   static bool isUnsaved(BasePatrolState state){
   		//note: subid in unsaved_states indicates different version of that state
			return unsaved_states.entries.any((e) => e.key == state.model.id);
	 }
   
   static PatrolRecordModel
   inferCurrentPatrol() {
      final states = manager.states_forUi.values.map((v) => v.last).toList();
      final maxlen = states.length;
      final _currentId = currentId;
      currentPatrol ??= states?.first?.model; // while it's null
      if (states.isNotEmpty){
         if (_currentId != -1) {
            // remain unchanged...
         } else {
            // has already been removed
            if (states.isEmpty){
               currentPatrol = null;
            }else if (states.length == 1) {
               currentPatrol = states.first.model;
            } else {
               if (prevId == null){
               
               } else {
                  if (prevId >= maxlen -1){
                     currentPatrol = states.last.model;
                  } else if (prevId <= 0){
                     currentPatrol = states.first.model;
                  }else{
                     currentPatrol = states[prevId].model;
                  }
               }
            }
         }
      }
      return currentPatrol;
   }
   
   /// discard patrol record saved temporary
   static BasePatrolState
   discard(PatrolDiscardEvent event) {
      if (states.isNotEmpty){
         debug('beforediscard: ${states.keys.toList()}');
         debug('PatrolState.discard -> ${event.tag_order}, ${event.model.patrol.getDevId().last}, ${event.model.id}');
         final id = event.model.patrol.getDevId();
         prevId = currentId;
				 BasePatrolState result;
         if (event.undoable){
						result = manager.saveState(
								PatrolDiscardState(event.model),
								id.last,
								addToUnsaved: false
						);
				 }else{
         		result = PatrolDiscardState(event.model);
         		states.remove(id.last);
				 }
         //inferCurrentPatrol(); redundant, since we've been inferred ids in afterSaveStateHistory
         return result;
      }else{
         return PatrolDiscardState(null);
      }
   }
   
   static int prevId;

   static bool get isLast  => states.length - 1 == currentId;
   static bool get isFirst => currentId == 0;

   static int _currentId;
   
   static int get currentId {
      final patrols = states.values.map((v) => v.last.model).toList();
      if (patrols.isNotEmpty){
         final result = patrols.indexOf(currentPatrol);
         if (result == -1){
            currentPatrol = patrols.first;
            /*raise(
               'cannot infer  currentId! or has been deleted\n'
               'patrols: $patrols\n'
               'currentPatrol: $currentPatrol');*/
         }
         return result;
      }
      return -1;
   }
   
   static void restoreCurrentIdViaHistory(Map<String,dynamic> ids) {
      final prev = ids['prevId'] as int;
      var  current = ids['currentId'] as int;
      if (current == -1){
         final patrol = inferCurrentPatrol();
         if (patrol == null)
            return;
         current = states.values.map((v) => v.last.model).toList().indexOf(patrol);
      }
      currentPatrol = states.values.toList()[current].last.model;
   }


   static void loadUnsaved(){
      manager.store.load().then((res) async {
         final content = List<Map<String,dynamic>>.from(res as List);
         await manager.loadLastUnsavedStatesAndMergeIntoUi(content);
         debug('loaded...');
         manager.msg.bloC.onFileLoadingSuccess(loadingId);
         bloC.onLoadFinished(Msg.OK);
      }).catchError((e){
         debug('failed to load...');
         manager.msg.bloC.onFileLoadingFailed(loadingId);
      });
   }
   
   
   

   static BasePatrolState
   next(PatrolNextEvent event) {
      try {
         final patrols = manager.states_forUi.values.map((v) => v.last.model).toList();
         if (patrols.isNotEmpty) {
            final currentid = currentId;
            prevId = currentid;
            if (currentid >= patrols.length - 1) {
               // remain unchanged
            } else {
               currentPatrol = patrols[min(currentId + 1, patrols.length -1)];
               event.model = currentPatrol;
            }
         }
         return PatrolNextState(event.model);;
      } catch(e) {
         final str = 'next failed: \n${StackTrace.fromString(e.toString())}';
         debug.error(str);
         throw Exception(str);
      }
   }
   
   static BasePatrolState
   prev(PatrolPrevEvent event) {
      try {
         final patrols = manager.states_forUi.values.map((v) => v.last.model).toList();
         if (patrols.isNotEmpty) {
            final currentid = currentId;
            prevId = currentid;
            if (currentid == 0) {
               // remain unchanged
            } else {
               currentPatrol = patrols[max(currentId -1, 0)];
               event.model = currentPatrol;
            }
         }
         return PatrolPrevState(event.model);;
      } catch(e) {
         final str = 'prev failed: \n${StackTrace.fromString(e.toString())}';
         debug.error(str);
         throw Exception(str);
      }
   }
   
   /// fixme:todo: del patrol records which already upload onto server
   static BasePatrolState
   del(DelPatrolEvent event) {
      debug('PatrolState.del -> ${event.tag_order}, ${event.model.patrol.getDevId().last}');
      final state = states.values.firstWhere(
         (v) => v.last.model.patrol.getDevId().last == event.model.patrol.getDevId().last,
         orElse: () => throw Exception("uncuahgt error")
      );
      states.removeWhere((k, v) => v.last == state.last);
      final result =  manager.saveState(
          state.last,
          event.model.patrol.getDevId().last,
          addToUnsaved: false);
      return result;
   }
   
   
   
   /// fixme:todo:
   /// add current record into imagejournal
   /// 1) call onNewSheet on IJBloC with NDEF tag
   static BasePatrolState
   addToJournal(AddPatrolEvent event) {
      debug('PatrolState.add -> ${event.model}');
      final result = manager.saveState(
         AddPatrolState(event.model),
         event.model.patrol.getDevId().last,
         addToUnsaved: true
      );
      return result;
   }

   static BasePatrolState
   edit(EditPatrolEvent event) {
      debug('PatrolState.edit -> ${event.model}');
      final result = manager.saveState(
         EditPatrolUnitState(event.key, event.value, event.model),
         event.model.patrol.getDevId().last,
         addToUnsaved: true
      );
      final state = states.values.firstWhere((v) => v.last.model.id == event.model.id,
          orElse: () => throw Exception('Uncuahgt Error'));
      //state.last.model.setValue();
      //todo:
      return result;
   }
   
   
   ///   1) discard without confirmation
   ///   2) save 20 records temporary dump into disk
   ///   3) upload one by one or batch upload
   static BasePatrolState
   receive(PatrolReceiveEvent event) {
      final patrolId = event.model.patrol.getDevId();
      /*if (states.values.any((s) => s.last.model.patrol.getDevId() == patrolId)){
         debug('block receving patrolrecord: $patrolId');
         return states.values.any((s) => s.last.model.patrol.getDevId() == patrolId);
      }*/
      debug('PatrolState.receive -> ${event.model.patrol.getDevId()}');
      final result = PatrolReceiveState(event.model);
      final id     = manager.inferId(event.model.machine_id.last);
      result.model.id = id;
      prevId = currentId;
      currentPatrol = result.model;
      print(result);
      final ret = manager.saveState(
         result, id, addToUnsaved: true);
      print(ret);
      return ret;
   }
   
   static Future<Response>
   getById(int id) async {
      final path = '/${ename(ROUTE.rawtag)}/id/$id';
      return  await Http().dioGet(path);
      return await cache.cacheAndSet(path, (){
         return Http().dioGet(path);
      });
   }
   
   static Future<Response>
   getByDeviceId(int id, int page, [int max_num = 5]) async {
      final path = '/${ename(ROUTE.rawtag)}/device/$id';
      return await Http().dioGet(path, qparam: {
         'page_num': page,
         'max_num': max_num
      });
   }
   
   static BasePatrolState
   redo(PatrolRedoEvent event) {
      final result = manager.saveState(
         PatrolRedoState(), null, addToUnsaved: false
      );
      inferCurrentPatrol();
      return result;
   }
   
   static BasePatrolState
   undo(PatrolUndoEvent event) {
      final result = manager.saveState(
         PatrolUndoState(), null, addToUnsaved: false
      );
      inferCurrentPatrol();
      return result;
   }
   
   static BasePatrolState
   upload(PatrolUploadEvent event) {
      final answer = event.answer;
      if (answer.cancel)
         return null;
      
      final result = manager.saveState(PatrolUploadState(event.answer), null);
      //manager.msg.bloC.onFileUploading();
      manager.uploadToServer().then((e){
         afterUpload(e);
         //bloC.onUploadFinished(res: e);
      }).catchError((e) {
         bloC.onUploadFinished( error: true);
         afterUploadFailed(null);
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         throw Exception(str);
      });
      return result;
   }
   
   static void updateUIAfterUpload(Response data, List<Map<String,dynamic>> bodies) {
      try{
         if (data == null)
            throw Exception("Uncuahgt exception");
         final uistates = states.values.map((s) => s.last).toList();
         final keys = states.keys.toString();
         for (var i = 0; i < bodies.length; ++i) {
            final id          = bodies[i]['id'] as int;
            final machine_id  = List<int>.from(bodies[i]['machine_id'] as List).last;
            final matched_state = uistates.firstWhere((u) => u.model.patrol.getDevId().last == machine_id, orElse: (){
               final str = "Uncaught Exception, cannot update response date on ui."
                  "\nmachine_ids on ui: ${uistates.map((u) => u.model.patrol.getDevId().last)}"
                  "\nresponse ids: ${bodies.map((b) => b['machine_id'])}";
               debug.error(str);
               throw Exception(str);
            });
            matched_state.model = PatrolRecordModel.fromMap(bodies[i]);
         }
      }catch(e){
         final str = "updateUIAfterUpload failed: ${StackTrace.fromString(e.toString())}";
         debug.error(str);
         throw Exception(str);
      }
      
   }
   
   static void afterUploadFailed(Response data) {
      manager.msg.bloC.onFileUploadingFailed("", uploadingId);
   }
   
   static void saveSyncConflict(Response data){
      final bodies   = data.data as Map<String,dynamic>;
      final success  = List<Map<String,dynamic>>.from(bodies['success'] as List);
      final conflict = List<List>.from(bodies['conflict'] as List);
      for (var i = 0; i < conflict.length; ++i) {
         final conflict_set = conflict[i];
         final data_onserver = conflict_set.first as Map<String,dynamic>;
         final data_onclient = conflict_set.last as  Map<String,dynamic>;
         conflictStack.add([data_onserver, data_onclient]);
      }
      updateUIAfterUpload(data, success);
   }
   
   static BasePatrolState
   uploadFinished(PatrolUploadFinishedEvent event) {
      final result = manager.saveState(
         PatrolUploadFinishedState(event.message, event.response), null
      );
      //afterUpload(event.response);
      return result;
   }
   
   static BasePatrolState
   onValidationError(ValidationErrorPatrolEvent event){
      final result = PatrolStateValidationError(event.response);
      //final bodies = List<Map<String,dynamic>>.from(event.response.data as List);
      state_message = Msg.onUploadFormValidationError;
      return result;
   }
   
   static Response
   afterUpload(Response data, [String error = null]){
      if (error != null) {
         final str = StackTrace.fromString(error.toString());
         manager.msg.bloC.onFileUploadingFailed(error.toString(), uploadingId);
         debug.error(str);
         throw Exception(str);
      }
      if (manager.isSyncConflictResponse(data)){
         saveSyncConflict(data);
         manager.msg.bloC.onFileUploadingFailed(Msg.onSyncConflict, uploadingId);
         bloC.onSyncConflict();
      }else{
         if (manager.isValidationResponse(data)) {
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadValidationError, uploadingId);
            bloC.onValidationError(data);
         } else if (data.statusCode == 200){
            final bodies = List<Map<String,dynamic>>.from(data.data as List);
            updateUIAfterUpload(data, bodies);
            //manager.remember.clearHistory();
            manager.msg.bloC.onFileUploadingSuccess(uploadingId);
            bloC.onUploadFinished(error: false, res: data);
         }else{
            afterUploadFailed(data);
            bloC.onUploadFinished(res: data, error: true);
         }
      }
      return data;
   }
   
   static BasePatrolState
   onSyncConflict(SyncConflictPatrolEvent event){
      return PatrolStateSyncConflict();
   }
   
   static void _discardServer(){
      final dataUpload = conflictStack.first;
      conflictStack.remove(dataUpload);
      Http().dioPost('/${ename(ROUTE.descoption)}', body: dataUpload).then(afterUpload).catchError((e){
         afterUpload(null, e.toString());
      });
   }
   
   static void _discardClient(){
      conflictStack.remove(conflictStack.first);
   }
   
   static BasePatrolState
   onResolveSyncConflict(ResolvedSyncConflictPatrolEvent event){
      if (conflictStack.isEmpty)
         return null;
      if (event.confirmConflict.first){
         _discardClient();
      }else{
         _discardServer();
      }
      return PatrolStateResolveSyncConflict(event.confirmConflict);
   }
   
   static BasePatrolState
   browseResult(PatrolBrowseResultEvent event){
      return PatrolStateBrowseResult(event.response, event.page);
   }
   
   static Future<Response>
   getAllByType(int queryid, int page){
      final path = '/rawtag/type/${queryid}';
      final qparam = {
         'page_num': page,
         'max_num' : 5,
      };
      return cache.cacheAndSet('$path?${qparam}', (){
         return Http().dioGet(path, qparam: qparam).then((response){
            return response;
         }).catchError((e){
            throw Exception(e);
         });
      });
//      return Http().dioGet(path, qparam: qparam).then((response){
//         return response;
//      }).catchError((e){
//         throw Exception(e);
//      });
   }

   static Future<Response>
   getAllByUserId(int queryid, int page, [int max_num = 5]){
      final path = '/rawtag/uid/${queryid}';
      final qparam = {
         'page_num': page,
         'max_num' : max_num,
      };
      return cache.cacheAndSet('$path?${qparam}', (){
         return Http().dioGet(path, qparam: qparam).then((response){
            return response;
         }).catchError((e){
            throw Exception(e);
         });
      });
//      return Http().dioGet(path, qparam: qparam).then((response){
//         return response;
//      }).catchError((e){
//         throw Exception(e);
//      });
   }
   
   
   static Future<BasePatrolState>
   browse(PatrolBrowseEvent event) {
      final page = event.page;
      print('browse: $page');
      if(event.querytype == EQtype.date){
         final path = '/rawtag/date/0';
         final qparam = {
            'date':DateTime.now().toUtc(),
            'duration': -365,
            'page_num': page,
            'max_num' : 5,
         };
         cache.cacheAndSet('$path?$qparam', (){
            return Http().dioGet(path, qparam: qparam).then((response){
               bloC.onBrowseResult(response, page);
               return response;
            }).catchError((e){
               throw Exception(e);
            });
         }).then((response){
					 bloC.onBrowseResult(response, page);
				 });;
//         Http().dioGet(path, qparam: qparam).then((response){
//            bloC.onBrowseResult(response, page);
//         }).catchError((e){
//            throw Exception(e);
//         });
      }else if (event.querytype == EQtype.type){
         final path = '/rawtag/type/${event.queryid}';
         final qparam = {
            'page_num': page,
            'max_num' : 5,
         };
         cache.cacheAndSet("$path?$qparam", (){
            return Http().dioGet(path, qparam: qparam).then((response){
               bloC.onBrowseResult(response, page);
               return response;
            }).catchError((e){
               throw Exception(e);
            });
         }).then((response){
					 bloC.onBrowseResult(response, page);
				 });
//         Http().dioGet(path, qparam: qparam).then((response){
//            bloC.onBrowseResult(response, page);
//         }).catchError((e){
//            throw Exception(e);
//         });
      }else{
         throw Exception("not implemented yet");
      }
      return Future.value(PatrolStateBrowse(event.page));
   }
   
   
   static void saveUnsaved() async {
      debug('[saveunsaved] dumpToDisk');
      await manager.dumpToDisk(unsaved: true).then((e) {
         bloC.onSaveFinished(Msg.OK);
      }).catchError((e) {
         bloC.onSaveFinished(e.toString());
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         throw Exception(str);
      });
   }
   
   
   
   static Future<BasePatrolState> saveSelected(String path) {
   		final _states = states.values.map((v) => v.last).toList();
			for (var i = 0; i < _states.length; ++i) {
				var s = _states[i];
				states.remove(s);
			}
			final event = PatrolSaveEvent(path: path);
			return save(event);
	 }
	 
   static Future<BasePatrolState>
   save(PatrolSaveEvent event) async {
      final result = manager.saveState(PatrolSaveState(), null);
      manager.msg.bloC.onFileSaving(savingId);
      debug('[save] dumpToDisk');
      await manager.dumpToDisk(unsaved: false, path: event.path).then((e) {
         bloC.onSaveFinished(Msg.OK);
         manager.msg.bloC.onFileSuccessfullySaved(savingId);
      }).catchError((e) {
         bloC.onSaveFinished(e.toString());
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         manager.msg.bloC.onFileSavingFailed(savingId);
         throw Exception(str);
      });
      return result;
   }
   
   static BasePatrolState
   saveFinished(PatrolSaveFinishedEvent event) {
      final result = manager.saveState(PatrolSaveFinishedState(event.message), null);
      if (event.message == Msg.OK)
         manager.msg.bloC.onFileSuccessfullySaved(savingId);
      else
         manager.msg.bloC.onFileSavingFailed(savingId);
      return result;
   }
   
   static BasePatrolState
   promptLoad(PatrolPromptLoadEvent event){
      return PatrolPromptLoadState();
   }
	
	
	 static Future<List<PatrolRecordModel>>
	 loadAsync(String filePath, {void onRead(Map)}){
		 //notice: save state on finished
		 final completer = Completer<List<PatrolRecordModel>>();
		 //    1) load data discard all changes
		 //    2) load data incorporate existing changes;
		 if (manager.file(filePath).existsSync()){
		 		print('file exists: ${manager.file(filePath).getPath()}');
		 		
           manager.msg.bloC.onFileLoading(loadingId);
			  manager.store.load(path: filePath).then((res) async {
				if (onRead != null)
					onRead(res);
				final content = FN.head(List<Map<String,dynamic>>.from(res as List));
				final records = content.map((c) => PatrolRecordModel.fromMap(c)).toList();
				print('loadAsync, content: $content');
				completer.complete(records);
			 }).catchError((e){
				 debug('failed to load...');
				 manager.msg.bloC.onFileLoadingParsingFailed(loadingId);
				 raise(StackTrace.fromString(e.toString()));
				 completer.complete(null);
			 });
		 }else{
			 manager.msg.bloC.onFileNotFound();
			 completer.complete(null);
		 }
		 return completer.future;
	 }
	 
   static BasePatrolState
   load(PatrolLoadEvent event){
      //notice: save state on finished
      final answer = event.answer;
      if (answer.cancel)
         return null;
      // todo:
      //    1) load data discard all changes
      //    2) load data incorporate existing changes;
      if (manager.file(event.path ?? manager.store.localpath).existsSync()){
         manager.store.load(path: event.path).then((res) async {
            final content = List<Map<String,dynamic>>.from(res as List);
            final logcontent = content.map((c){
               final data = c.toString();
               return "${data.substring(0, min(data.length, 15))}...";
            }).toList();
            debug('load saved file: $logcontent, ${manager.file(event.path ?? manager.store.localpath).getPath()}');
            await manager.loadLastSavedStatesAndMergeIntoUi(
               content:content, answer: answer.answers.first, byCache: true);
            manager.remember.clearAndSaveHistory();
            manager.msg.bloC.onFileLoadingSuccess(loadingId);
            bloC.onLoadFinished(Msg.OK);
         }).catchError((e){
            debug('failed to load...');
            manager.msg.bloC.onFileLoadingParsingFailed(loadingId);
            raise(StackTrace.fromString(e.toString()));
         });
      }else{
         manager.msg.bloC.onFileNotFound();
      }
      return PatrolLoadState(answer);
   }

   static BasePatrolState
   loadFinished(PatrolLoadFinishedEvent event){
      final result = manager.saveState(PatrolLoadFinishedState(Msg.OK), null);
      return result;
   }

}

// mapping from other state into PatrolBloC
class PatrolBloCStateMapping<T>{
   Map<String, void Function(T state, PatrolBloC bloc)> records = {};

   bool isUnionWithState<T>(T key){
      return records.containsKey(key.toString());
   }

   map(T key, void cb(T state, PatrolBloC bloc)){
      records[key.toString()] = cb;
   }

   void Function(T state, PatrolBloC bloc)
   get(T key){
      return records[key.toString()];
   }
}




class PatrolBloC extends Bloc<PatrolEvents, BasePatrolState> {
   BasePatrolState        last_state;
   PatrolEvents           last_event;
   PatrolAuthGuard        readAuthGuard;
	 PatrolAuthGuard        writeAuthGuard;
   StreamTransformer<PatrolEvents, PatrolEvents> readAuthTransformer;
	 StreamTransformer<PatrolEvents, PatrolEvents> writeAuthTransformer;
   PatrolBloC(PatrolMainStateManager managerA, PatrolMainStateManager managerB){
      PatrolState.manager = managerA;
			PatrolCfgState.manager = managerB;
      readAuthGuard  = PatrolAuthGuard(PatrolState.manager);
			writeAuthGuard = PatrolAuthGuard(PatrolCfgState.manager);
   }

   @override BasePatrolState
   get initialState {
      PatrolState.bloC = this;
			PatrolCfgState.bloC = this;
      readAuthGuard  = PatrolAuthGuard(PatrolState.manager);
			writeAuthGuard = PatrolAuthGuard(PatrolCfgState.manager);
      readAuthTransformer = getAuthTransformer(readAuthGuard);
			writeAuthTransformer = getAuthTransformer(writeAuthGuard);
			return DefaultPatrolState();
   }
   
   @override void onError(Object error, StackTrace stacktrace) {
      // TODO: implement onError
      final str = "error obj: $error\n${stacktrace.toString()}";
      debug(str);
      throw Exception(str);
   }
   @override Stream<BasePatrolState>
   mapEventToState(PatrolEvents event) async* {
//      if (currentState.runtimeType == last_state.runtimeType &&)
      debug('p mapEventToState, current:${currentState.runtimeType} dup:${last_state == currentState}, evt:${event.runtimeType}');
      last_state = currentState;
      last_event = event;
      BasePatrolState new_state;
      switch (event.event) {
				case EPatrolEvent.promptUpload:
				case EPatrolEvent.promptLoad:
					throw Exception('not implemented yet');
					
				case EPatrolEvent.loadCfg:
					new_state = PatrolCfgState.load(event as PatrolCfgLoadEvent);
					break;
				case EPatrolEvent.loadCfgFinished:
					new_state = PatrolCfgState.loadFinished(event as PatrolCfgLoadFinishedEvent );
					break;
				case EPatrolEvent.redoCfg:
					new_state = PatrolCfgState.redoCfg(event as PatrolCfgRedoEvent);
					break;
				case EPatrolEvent.undoCfg:
					new_state = PatrolCfgState.undoCfg(event as PatrolCfgUndoEvent);
					break;
					
				case EPatrolEvent.delCfg:
					new_state = PatrolCfgState.del(event as DelPatrolCfgEvent);
					break;
				case EPatrolEvent.editCfg:
					new_state = PatrolCfgState.edit(event as EditPatrolCfgEvent);
					break;
				case EPatrolEvent.receiveCfgTarget:
					new_state = PatrolCfgState.receiveSource(event as PatrolCfgReceiveEvent);
					break;
				case EPatrolEvent.createConfig:
					new_state = PatrolCfgState.createConfig(event as PatrolCfgCreateEvent);
					break;
         case EPatrolEvent.add:
            new_state = PatrolState.addToJournal(event as AddPatrolEvent);
            break;
         case EPatrolEvent.edit:
            new_state = PatrolState.edit(event as EditPatrolEvent);
            break;
         case EPatrolEvent.undo:
            new_state = PatrolState.undo(event as PatrolUndoEvent);
            break;
         case EPatrolEvent.redo:
            new_state = PatrolState.redo(event as PatrolRedoEvent);
            break;
         case EPatrolEvent.browse:
            new_state = await PatrolState.browse(event as PatrolBrowseEvent);
            break;
         case EPatrolEvent.browseResult:
            new_state = PatrolState.browseResult(event as PatrolBrowseResultEvent);
            break;
         case EPatrolEvent.discard:
            new_state = PatrolState.discard(event as PatrolDiscardEvent);
            break;
         case EPatrolEvent.next:
            new_state = PatrolState.next(event as PatrolNextEvent);
            break;
         case EPatrolEvent.prev:
            new_state = PatrolState.prev(event as PatrolPrevEvent);
            break;
         case EPatrolEvent.receive:
            new_state = PatrolState.receive(event as PatrolReceiveEvent);
            print('yield patrol recieve: ${new_state.runtimeType}');
            break;
         case EPatrolEvent.del:
            new_state = PatrolState.del(event as DelPatrolEvent);
            break;
         case EPatrolEvent.load:
            new_state = PatrolState.load(event as PatrolLoadEvent);
            break;
         case EPatrolEvent.loadFinished:
            new_state = PatrolState.loadFinished(event as PatrolLoadFinishedEvent);
            break;
         case EPatrolEvent.save:
            new_state = await PatrolState.save(event as PatrolSaveEvent);
            break;
         case EPatrolEvent.saveFinished:
            new_state = PatrolState.saveFinished(event as PatrolSaveFinishedEvent);
            break;
         case EPatrolEvent.upload:
            new_state = PatrolState.upload(event as PatrolUploadEvent);
            break;
         case EPatrolEvent.uploadFinished:
            new_state = PatrolState.uploadFinished(event as PatrolUploadFinishedEvent);
            break;
         case EPatrolEvent.syncConflict:
            new_state = PatrolState.onSyncConflict(event as SyncConflictPatrolEvent);
            break;
         case EPatrolEvent.resolveConflict:
            new_state = PatrolState.onResolveSyncConflict(event as ResolvedSyncConflictPatrolEvent);
            break;
         case EPatrolEvent.validationError:
            new_state = PatrolState.onValidationError(event as ValidationErrorPatrolEvent);
            break;
         case EPatrolEvent.setState:
            new_state = PatrolStateSetState();
            break;
      }
      print('yield: ${new_state.runtimeType}');
      yield new_state;
   }
   
   void onUploadFinished({Response res, bool error = false, bool onDel = false}) {
      if (error) {
         dispatch(PatrolUploadFinishedEvent(Msg.onUploadFailed(""), res, onDel));
      } else {
         dispatch(PatrolUploadFinishedEvent(Msg.OK, res, onDel));
      }
   }
   void onSetState(){
      dispatch(PatrolSetStateEvent());
   }
   
   void onUpload([PatrolPromptUploadEvent event]){
      final answer = event?.answer ?? PromptAnswer(length: 1, answers:[EAnswer.white]);
      dispatch(PatrolUploadEvent(answer));
   }
   
   // add NDEFTag explicity by clicking add
   void onAddToJournal(AddPatrolEvent event) {
      dispatch(event);
   }
   void onCreateCfg(PatrolCfgCreateEvent event){
   		dispatch(event);
	 }

	 void onEdit(EditPatrolEvent event) {
		 dispatch(event);
	 }
	 void onEditCfg(EditPatrolCfgEvent event) {
		 dispatch(event);
	 }
   
   // receive NDEFTag by scan not added explicitly
   void onReceive(PatrolReceiveEvent event) {
      dispatch(event);
   }
	 void onReceiveCfgTarget(PatrolCfgReceiveEvent event) {
		 dispatch(event);
	 }
   
   void undo(){
      dispatch(PatrolUndoEvent());
   }
   
   void redo(){
      dispatch(PatrolRedoEvent());
   }

	 void undoCfg(){
		 dispatch(PatrolCfgUndoEvent());
	 }

	 void redoCfg(){
		 dispatch(PatrolCfgRedoEvent());
	 }
   
   void onLoad([PatrolLoadEvent event]){
      final answer = event?.answer ?? PromptAnswer(length: 1, answers: [EAnswer.white]);
      dispatch(PatrolLoadEvent(answer: answer, path: event.path));
   }

	 void onLoadFinished(String message){
		 dispatch(PatrolLoadFinishedEvent(message));
	 }
	 
	 void onLoadCfgFinished(String message){
		 dispatch(PatrolCfgLoadFinishedEvent(message));
	 }
   
   void onSave() {
      dispatch(PatrolSaveEvent());
   }
   
   void onSaveFinished(String message) {
      dispatch(PatrolSaveFinishedEvent(message));
   }
   
   void onBrowseResult(Response response, int page){
      dispatch(PatrolBrowseResultEvent(response, page));
   }
   void onBrowse(int page, {EQtype querytype = EQtype.date, int queryid}) {
      dispatch(PatrolBrowseEvent(page, querytype: querytype, queryid: queryid));
   }
   
   void onNext() {
      dispatch(PatrolNextEvent());
   }
   
   void onPrev() {
      dispatch(PatrolPrevEvent());
   }
	 void onDel(int tag_order) {
		 final model = PatrolState.getModelByTagOrder(tag_order);
		 final event = DelPatrolEvent(model, tag_order);
		 dispatch(event);
	 }
   void onDiscard({int tag_order, BasePatrolState state, bool undoable = true}) {
   	PatrolRecordModel model;
   	if (tag_order != null){
			model = PatrolState.getModelByTagOrder(tag_order ?? PatrolState.currentId);
		}else if (state != null){
   		model = state.model;
		}else{
   		throw Exception("invalid usage");
		}
		if (model != null)
			 dispatch(PatrolDiscardEvent(tag_order, model, undoable));
   }
   

	 void onDelCfg(int tag_order) {
		 final model = PatrolCfgState.getModelByTagOrder(tag_order);
		 final event = DelPatrolCfgEvent(model, tag_order);
		 dispatch(event);
	 }

   void onSyncConflict(){
      dispatch(SyncConflictPatrolEvent());
   }

   void onResolveConflict(List<bool> confirmConflict){
      dispatch(ResolvedSyncConflictPatrolEvent(confirmConflict));
   }
   
   void onValidationError(Response data){
      dispatch(ValidationErrorPatrolEvent(data));
   }
}