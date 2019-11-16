import 'dart:async';
import 'dart:convert';

import 'package:PatrolParser/PatrolParser.dart';
import 'package:bloc/bloc.dart';
import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijdevice_state.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/permission.dart';
import 'package:nxp_bloc/mediators/di.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/consts/server.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:rxdart/rxdart.dart';



class DevMainStateGet<ST extends BaseIJDevState> extends BaseGetService<ST> {
   DevMainStateGet(this.get_request_path, this.manager) : super(get_request_path, manager);
   @override String get_request_path;
   @override BaseStatesManager<ST> manager;

   @override Response afterGet(Response res, {int retries = 1}) {
      final body = List<Map<String,dynamic>>.from(res.data as List);
      PatrolRecord.PatrolTypes = <String>[null] + body.map((m) => m['name'] as String).toList();
      return res;
   }
}

class DevMainStatePost <ST extends BaseIJDevState> extends BasePostService<ST>{
   @override BaseStatesManager<ST> manager;
   @override BaseValidationService<ST> validator;
   @override BaseMessageService msgbloC;
   @override String del_request_path;
   @override String post_request_path;
   @override String merge_request_path;
   
   DevMainStatePost(
      this.post_request_path, this.del_request_path,
      this.merge_request_path, this.msgbloC, this.validator, this.manager)
      : super(post_request_path, del_request_path, merge_request_path, msgbloC, validator, manager);
   
   @override
   List<Map<String, dynamic>> getUploadData() {
      final result = <Map<String, dynamic>>[];
      // fixme: sates_forUi
      manager.states_forUi.forEach((k, v) {
         result.add(v.last.model.asMap());
      });
      return result;
   }

   @override
  Response onUploadSuccess(Response res) {
    final body = List<Map<String,dynamic>>.from(res.data as List);
    PatrolRecord.PatrolTypes = <String>[null] + body.map((m) => m['name'] as String).toList();
    return super.onUploadSuccess(res);
  }
}

class DevMainStateValidator <ST extends BaseIJDevState> extends BaseValidationService<ST>{
   DevMainStateValidator(this.manager, this.get): super(manager, get);
   @override BaseGetService<ST>      get;
   @override BaseStatesManager<ST>   manager;
   @override bool validate(ST state, List<Map<String, dynamic>> source) {
      final self = source.firstWhere((d) => d['id'] == manager.matcher.idGetter(state), orElse: () => null);
      if (self != null)
         source.remove(self);
      state.model.validate(source);
      return !state.model.hasValidationErrors;
   }
}

class DevMainStateStore <ST extends BaseIJDevState> extends BaseStoreService<ST>{
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   @override String unsavedpath;
   @override String localpath;
   
   DevMainStateStore(this.localpath, this.unsavedpath, this.manager, this.get)
      : super(localpath, unsavedpath, manager, get);
   
   void dumpServerData(List<Map<String, dynamic>> dataOnServer){
      dataOnServer.add({'inferred_ids': []});
      manager.file(localpath).writeSync(jsonEncode(dataOnServer) );
   }
   
   @override
   List beforeDump(List<BaseIJDevState> statesToBeDump, dynamic json){
      FN.prettyPrint(statesToBeDump);
      //dumpServerData(List<Map<String, dynamic>>.from(json as List));
      final options = statesToBeDump.map((state) => state.model).toList();
      final localdata = options.map((option) => option.asMap()).toList();
      return localdata;
   }

   @override
   List<ST> getStatesToBeDump() {
      final unsaved_keys = manager.unsaved_states.keys.toList();
      return DevState.states.keys.where(unsaved_keys.contains)
         .map((key) => DevState.states[key].last as ST).toList();
//      final result = DevState.states.values.map((v) => v.last as ST).toList();
//      return result;
   }
   
   @override dynamic afterLoad(String data) {
      try {
         if (data != null){
            final result = jsonDecode(data);
            final body = List<Map<String,dynamic>>.from(result as List);
            print('before set PatrolTypes:');
            print(body);
            PatrolRecord.PatrolTypes = <String>[null] + body.map((m) => m['name'] as String).toList();
            return result;
         }
      } catch (e) {
         throw Exception(
             'afterLoad failed: \ndata:$data\n${StackTrace.fromString(e.toString())}');
      }
  }
}

class DevMainStateConverter <ST extends BaseIJDevState> extends BaseStateConverter<ST>{
   DevMainStateConverter(this.manager) : super(manager);
   @override BaseStatesManager<ST> manager;
   @override ST mapDataToState(Map<String, dynamic> data) {
      final model = DeviceModel.from(data);
      return DevStateAdd(model) as ST;
   }
   @override Map<String, dynamic> mapStateToData(BaseIJDevState state, {bool considerValidation = false}) {
      return state.model.asMap(considerValidation: considerValidation);
   }
}

class DevMainStateMatcher<ST extends BaseIJDevState>  extends BaseStateMatcher<ST>{
   @override bool uploadMatcher  (ST state) => state is DevStateUpload;
   @override bool redoMatcher    (ST state) => state is DevStateRedo;
   @override bool undoMatcher    (ST state) => state is DevStateUndo;
   @override bool delMatcher    (ST state) => state is DevStateDel;
   @override bool mergeMatcher     (ST state) => state is DevStateMerge;
   @override int idGetter    (ST state) => state.model.id;
   @override int idSetter    (ST state, int id) => state.model.id = id;
   @override void clearId    (ST state) => state.model.id = null;
}

class DeviceMainStateManager<ST extends BaseIJDevState> extends BaseStatesManager<ST>{
   @override BaseStateConverter<ST> converter;
   @override BaseStateMatcher<ST>   matcher;
   @override BaseStateProgress progressor;
   @override StoreInf Function(String path) file;
   @override ConfigInf config;
   
   DeviceMainStateManager(this.config, this.file, {this.converter, this.matcher, this.progressor, void onInitialError(e)})
      : super(converter, matcher, progressor){
      DevState.manager = this;
      converter = DevMainStateConverter(this);
      matcher = DevMainStateMatcher();
      progressor = BaseStateProgress();
      final localpath   = 'nxp.db.offline.device.json';
      final unsavedpath = 'nxp.db.offline.device.unsaved.json';
      final get_request_path  = ename(ROUTE.device);
      final post_request_path = '/${ename(ROUTE.device)}/batch';
      final merge_request_path  = '/${ename(ROUTE.device)}/merge/';

      final msgBloC = MessageBloC();
      
      msg = BaseMessageService(msgBloC, this);
      get = BaseGetService(get_request_path, this);
      post = DevMainStatePost(
         post_request_path, null,
         merge_request_path, msg,
         DevMainStateValidator(this, get), this
      );
      store = DevMainStateStore(localpath, unsavedpath, this, get);
      remember = HistoryService(this, config.app.history);
      fetchInitialData().catchError(onInitialError);
   }

  //void addInitialState(DevStateReceive state, int id) {}
}



class DevUnitStateMatcher<ST extends BaseIJDevState>  extends BaseStateMatcher<ST>{
   @override bool uploadMatcher (ST state) => state is DevStateUnitUpload;
   @override bool redoMatcher   (ST state) => state is DevStateRedoUnit;
   @override bool undoMatcher   (ST state) => state is DevStateUndoUnit;
   @override bool mergeMatcher     (ST state) => state is DevStateMerge;
   @override int idGetter    (ST state) => state.model.id;
   @override int idSetter    (ST state, int id) => state.model.id = id;
   @override void clearId    (ST state) => state.model.id = null;
}
class DeviceUnitStateManager<ST extends BaseIJDevState> extends BaseStatesManager<ST>{
   @override BaseStateConverter<ST> converter;
   @override BaseStateMatcher<ST>   matcher;
   @override BaseStateProgress progressor;
   @override StoreInf Function(String path) file;
   @override ConfigInf config;
   
   DeviceUnitStateManager(this.config, this.file, {this.converter, this.matcher, this.progressor})
      : super(converter, matcher, progressor){
      converter = DevMainStateConverter(this);
      matcher = DevUnitStateMatcher();
      final post_request_path = '/${ename(ROUTE.device)}/batch';
      final merge_request_path  = '/${ename(ROUTE.device)}/merge/';
      post = DevMainStatePost(
         post_request_path, null,
         merge_request_path, msg,
         DevMainStateValidator(this, get), this
      );
      remember = HistoryService(this, 12);
   }
}




class DevState {
   //@fmt:off
//   static BgProc get processing    => AppState.processing;
   static String get state_message => AppState.state_message;
   static String get file_path     => manager.ident;
//   static        set processing   (BgProc v) => AppState.processing    = v;
   static        set state_message(String v) => AppState.state_message = v;
   static        set file_path    (String v) => manager.ident         = v;
   static DeviceMainStateManager<BaseIJDevState> manager;
   static Map<int, DeviceUnitStateManager> unit_manager;
   //@fmt:on
   static Map<int, List<BaseIJDevState>> get states => manager.states_forUi;
   static Map<int, BaseIJDevState>       get merged_devices => {};
   static Map<int, int>                  get unsaved_devices => manager.unsaved_states;

   static List<List<Map<String, dynamic>>> conflictStack         = [];
   static List<List<bool>>                 resolvedConflictStack = [];

   static LoggerSketch debug = AppState.getLogger('Dev');
   
   static IJDevBloC bloC;

   static Future<DeviceModel>
   getModelByModelId(int device_id) async {
      final modelmap = List<Map<String, dynamic>>.from(
         await manager.fetchInitialData() as List)
         .firstWhere(
            (m) => (m['id'] as int) == device_id
         , orElse: () => null
      );
      if (modelmap != null)
         return DeviceModel.from(modelmap);
      return states[device_id].last.model;
   }

   static BaseIJDevState
   redo(RedoDevEvent event) {
      final result = manager.saveState(
         DevStateRedo(), null, addToUnsaved: false
      );
      return result;
   }

   static BaseIJDevState
   undo(UndoDevEvent event) {
      final result = manager.saveState(
         DevStateUndo(), null, addToUnsaved: false
      );
      return result;
   }

   static Future<BaseIJDevState>
   del(DelDevEvent event) async {
      final id    = event.inferred_id;
      final model = event.model ?? await getModelByModelId(id);
      final result = manager.saveState(
         DevStateDel(model),
         id
      );
      return result;
   }

   static BaseIJDevState undoUnit(UndoUnitDevEvent event) {
      final result = unit_manager[event.device_id].saveState(
         DevStateUndoUnit(DeviceModel(null)..id = event.device_id),
         null, addToUnsaved: false
      );
      return result;
   }
   static BaseIJDevState redoUnit(RedoUnitDevEvent event) {
      final result = unit_manager[event.device_id].saveState(
         DevStateRedoUnit(DeviceModel(null)..id = event.device_id),
         null, addToUnsaved: false
      );
      return result;
   }

   static void initUnitManager(int id, int inferid){
      unit_manager ??= {};
      unit_manager[id] ??= DeviceUnitStateManager(null, null);
      if (manager.inferred_ids.contains(inferid) && unit_manager[id].inferred_ids.isEmpty)
         unit_manager[id].inferId(inferid);
   }

   static Future<BaseIJDevState>
   add(AddDevEvent event) async {
      final inferred_id = event.device_id ?? manager.inferId(event.device_id);
      final model = event.model ?? DeviceModel("");
      model.id ??= inferred_id;
      final result = manager.saveState(
         DevStateAdd(model),
         inferred_id,
         addToUnsaved: true
      );
      try {
         unit_manager ??= {};
         unit_manager[model.id] = DeviceUnitStateManager(null, null);
         if (manager.inferred_ids.contains(inferred_id)){
            unit_manager[model.id].inferred_ids ??= Set();
            unit_manager[model.id].inferred_ids.add(inferred_id);
         }
         unit_manager[model.id].saveState(result, model.id, addToUnsaved: true);
      } catch (e) {
         throw Exception('initialize unit_manager failed: \n${StackTrace.fromString(e.toString())}');
      }
      assert(result is DevStateAdd);
      return result;
   }



   static Future<BaseIJDevState>
   edit(EditDevEvent event) async {
      final device_id = event.device_id;
      final model = event.model ?? await getModelByModelId(device_id);
//      final result = manager.saveState(
//         DevStateEdit(device_id, model),
//         device_id,
//         addToUnsaved: true
//      );
      final result = DevStateEdit(device_id, model);
      try {
         
         unit_manager ??= {};
         unit_manager[model.id] ??= DeviceUnitStateManager(null, null);
         if (manager.inferred_ids.contains(device_id) && unit_manager[model.id].inferred_ids.isEmpty)
            unit_manager[model.id].inferId(device_id);
         unit_manager[model.id].saveState(result, device_id, addToUnsaved: true);
      } catch (e) {
         throw Exception('initialize unit manager failed: \n${StackTrace.fromString(e.toString())}');
      }
      return result;
   }

   //@fmt:off
   static BaseIJDevState _findModelById(int device_id){
      return states[device_id]?.last;
   }
   //@fmt:on
   
   static BaseIJDevState
   merge(MergeDevEvent event) {
      final device_id = event.device_id;
      final merged_id = event.merged_id;
      final master = _findModelById(device_id);
      final drop = _findModelById(merged_id);
      if (drop == null || master == null){
         debug.error('Internal App Error: drop model not found by device id:$merged_id');
         throw Exception('Internal App Error: drop model not found by device id:$merged_id');}
      assert (master.model.id != null);
      final result =  manager.saveState(
         DevStateMerge(master.model, drop.model),
         device_id,
         slave: drop
      );

      unit_manager ??= {};
      unit_manager[master.id] ??= DeviceUnitStateManager(null, null);
      if (manager.inferred_ids.contains(device_id) && unit_manager[master.id].inferred_ids.isEmpty)
         unit_manager[master.id].inferId(device_id);

      final mgr = unit_manager[master.model.id];
      mgr.merge_states = [[master, drop]];
      edit(EditDevEvent(device_id: master.model.id));
      assert (master.model.id != null);
      return result;
   }

   static BaseIJDevState
   browse(BrowseDevEvent event) {
      // todo:
      // 1) dump file to disk
      // 2) notify users of unsaved states
      /// dump data to disk
      /// upload data to server
   
      return DevStateBrowse();
   }
   
   static final String savingId = uuid.v4();
   static final String loadingId = uuid.v4();
   static final String uploadingId = uuid.v4();
   
   static BaseIJDevState
   save(SaveDevEvent event) {
      final filepath = event.filename ?? file_path;
      final result = manager.saveState(DevStateSave(filepath), null);
      manager.msg.bloC.onFileSaving(savingId);
      manager.dumpToDisk(unsaved: true).then((e) {
         bloC.onDeviceSaveFinished(Msg.OK);
      }).catchError((e) {
         bloC.onDeviceSaveFinished(e.toString());
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         throw Exception(str);
      });
      return result;
   }

   static BaseIJDevState
   saveFinished(SaveDevFinishedEvent event) {
      final result = manager.saveState(DevStateSaveFinisehd(event.message), null);
      if (event.message == Msg.OK)
         manager.msg.bloC.onFileSuccessfullySaved(savingId);
      else
         manager.msg.bloC.onFileSavingFailed(savingId);
      return result;
   }
   
   static BaseIJDevState
   uploadUnit(UploadUnitDevEvent event){
      final result = DevStateUnitUpload();
      final model = event.model;
      final mgr = unit_manager[model.id];
      final id = model.id;
      print('upload on modelid: $id, mgr: $mgr');
      manager.msg.bloC.onFileUploading(uploadingId);
      mgr.saveState(result, null);
      mgr.uploadToServer()
         .then((res){
            print('uploaded, code: ${res.statusCode}, mgr: $mgr, id:$id');
            return afterUploadUnit(mgr,  res, id );
         })
         .catchError((e) {
               afterUploadUnit(mgr ,null,model.id, e.toString());
      });
      return result;
   }

   static void unitIdUpdate(DeviceUnitStateManager mgr, Response data, int previd){
      final int updated_id = data.data.last['id'] as int;
      print('updateUnit, data: ${data.data}, previd:$previd, updatedId: $updated_id\n'
          'prevstate: ${manager.states_forUi[previd]}, currentState: ${mgr.states_forUi[updated_id]}');;

      unit_manager.remove(previd);
      unit_manager[updated_id] = mgr;
      
      manager.states_forUi[previd].last.model.update(mgr.states_forUi[updated_id].last.model);
      final updatedModel = manager.states_forUi[previd];
      manager.states_forUi[updated_id] = updatedModel;
      manager.states[updated_id] = updatedModel;
      manager.states_forUi.remove(previd);
      //      manager.states.remove(previd);
      manager.inferred_ids.remove(previd);
      manager.unsaved_states.remove(previd);
      manager.saveState(
         mgr.states_forUi[updated_id].last,
         updated_id
      );
   }
   
   static Response afterUploadUnit(DeviceUnitStateManager mgr, Response data, int previd, [String error = null]){
      if (error != null) {
         final str = StackTrace.fromString(error.toString());
         if (data?.statusCode != null){
               manager.msg.bloC.onInferNetworkError(data.statusCode, uploadingId, str.toString());
         }else{
            if (AppState.offlineMode)
               manager.msg.bloC.onNetworkUnavailable();
            else
               manager.msg.bloC.onRequestTimeout(uploadingId);
            
         }
//         print('errors...., undo: ${mgr.inferred_ids}, ${manager.inferred_ids}');
//         mgr.undo();
//         print('after undo: ${mgr.inferred_ids}, ${mgr.inferred_ids}');
         throw Exception(str);
      }

      if (mgr.isSyncConflictResponse(data)){
         saveSyncConflict(data); // fixme:
         manager.msg.bloC.onConfict(uploadingId);
         bloC.onSyncConflict();  // fixme:
      }else{
         if (manager.isValidationResponse(data)) {
            //bloC.onDeviceUploadFinished(Msg.onUploadValidationError, null);
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadValidationError, uploadingId);
            bloC.onDeviceValidationError(data);
         } else if (data.statusCode == 200){
            unitIdUpdate(mgr, data, previd);
            manager.msg.bloC.onFileUploadingSuccess(uploadingId);
            bloC.onDeviceUnitUploadFinished(Msg.OK, data);
         }else{
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadFailed(""), uploadingId);
            bloC.onDeviceUnitUploadFinished(Msg.onUploadFailed(""), data);
         }
      }
      return data;
   }
   
   static BaseIJDevState
   upload(UploadDevEvent event) {
      final result = manager.saveState(DevStateUpload(), null);
      manager.msg.bloC.onFileUploading(uploadingId);
      manager.uploadToServer()
         .then(afterUpload)
         .catchError((e) {
         afterUpload(null, e.toString());
      });
      return result;
   }

   static BaseIJDevState
   uploadUnitFinished(UploadDevUnitFinishedEvent event) {
      final result = unit_manager[event.response.data.last['id']].saveState(
         DevStateUploadFinished(event.message, event.response), null);
      updateStatesByResponse(event.response);
      return result;
   }
   
   static BaseIJDevState
   uploadFinished(UploadDevFinishedEvent event) {
      final result = manager.saveState(
         DevStateUploadFinished(event.message, event.response), null);
      updateStatesByResponse(event.response);
      return result;
   }

   static void updateStatesByResponse(Response response) {
      if (response == null)
         return;
   }
   
   static BaseIJDevState
   onValidationError(ValidationErrorDevEvent event){
      final result = DevStateValidationError(event.response);
      //final bodies = List<Map<String,dynamic>>.from(event.response.data as List);
      state_message = Msg.onUploadFormValidationError;
      return result;
   }
 
   static void saveSyncConflict(Response data){
      final bodies   = data.data as Map<String,dynamic>;
      final success  = bodies['success'];
      final conflict = bodies['conflict'] as List;
      for (var i = 0; i < conflict.length; ++i) {
         final conflict_set = conflict[i] as List;
         final data_onserver = conflict_set.first as Map<String,dynamic>;
         final data_onclient = conflict_set.last as  Map<String,dynamic>;
         conflictStack.add([data_onserver, data_onclient]);
      }
   }
   
   static Response afterUpload(Response data, [String error = null]){
      if (error != null) {
         final str = StackTrace.fromString(error.toString());
         debug.error(str);
         throw Exception(str);
      }
      if (manager.isSyncConflictResponse(data)){
         saveSyncConflict(data);
         manager.msg.bloC.onFileUploadingFailed(Msg.onSyncConflict, uploadingId);
         bloC.onSyncConflict();
      }else{
         if (manager.isValidationResponse(data)) {
            //bloC.onDeviceUploadFinished(Msg.onUploadValidationError, null);
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadFormValidationError, uploadingId);
            bloC.onDeviceValidationError(data);
         } else if (data.statusCode == 200){
            manager.msg.bloC.onFileUploadingSuccess(uploadingId);
            bloC.onDeviceUploadFinished(Msg.OK, data);
         }else{
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadFailed(""), uploadingId);
            bloC.onDeviceUploadFinished(Msg.onUploadFailed(""), data);
         }
      }
      return data;
   }
   
   static BaseIJDevState
   onSyncConflict(SyncConflictDevEvent event){
      return DevStateSyncConflict();
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
   
   static BaseIJDevState
   onResolveSyncConflict(ResolvedSyncConflictDevEvent event){
      if (conflictStack.isEmpty)
         return null;
      if (event.confirmConflict.first){
         _discardClient();
      }else{
         _discardServer();
      }
      return DevStateResolveSyncConflict(event.confirmConflict);
   }

  
}





class IJDevBloC extends Bloc<IJDevEvents, BaseIJDevState> {
   static String get jsonPath => 'nxp.db.offline.device.json';
   static bool disableGuard = false;
   StreamTransformer<IJDevEvents, IJDevEvents> authTransformer;
   BaseIJDevState last_state;
   DevAuthGuard<IJDevEvents> authGuard;
   
   IJDevBloC(DeviceMainStateManager manager){
      DevState.manager = manager;
      DevState.bloC = this;
      DevState.debug("IJBloC init ###");
   }
   
   @override
   void onError(Object error, StackTrace stacktrace) {
    // TODO: implement onError
    throw Exception('$error\n$stacktrace');
  }
   
   @override BaseIJDevState
   get initialState {
      DevState.bloC = this;
      authGuard = DevAuthGuard(DevState.manager);
      
      return DevStateDefault();
   }

   @override
   Stream<BaseIJDevState> transform(Stream<IJDevEvents> events, Stream<BaseIJDevState> Function(IJDevEvents event) next) {
    // TODO: implement transform
      if(disableGuard)
         return super.transform(events, next);
      return super.transform((events as Observable<IJDevEvents>).where((e) => authGuard.guard(e)), next);
  }
   
   @override
   Stream<BaseIJDevState> mapEventToState(IJDevEvents event) async* {
      if (currentState == last_state)
         yield null;

      last_state = currentState;
      BaseIJDevState new_state;
      switch (event.event) {
         case EIJDevEvents.add:
            new_state = await DevState.add(event as AddDevEvent);
            assert(new_state is DevStateAdd);
            break;
         case EIJDevEvents.edit:
            new_state = await DevState.edit(event as EditDevEvent);
            break;
         case EIJDevEvents.del:
            new_state = await DevState.del(event as DelDevEvent);
            break;
         case EIJDevEvents.merge:
            new_state = DevState.merge(event as MergeDevEvent);
            break;
         case EIJDevEvents.undo:
            new_state = DevState.undo(event as UndoDevEvent);
            break;
         case EIJDevEvents.redo:
            new_state = DevState.redo(event as RedoDevEvent);
            break;
         case EIJDevEvents.undoUnit:
            new_state = DevState.undoUnit(event as UndoUnitDevEvent);
            break;
         case EIJDevEvents.redoUnit:
            new_state = DevState.redoUnit(event as RedoUnitDevEvent);
            break;
         
         case EIJDevEvents.browse:
            new_state = DevState.browse(event as BrowseDevEvent);
            break;
         case EIJDevEvents.save:
            new_state = DevState.save(event as SaveDevEvent);
            break;
         case EIJDevEvents.upload:
            new_state = DevState.upload(event as UploadDevEvent);
            break;
         case EIJDevEvents.uploadUnit:
            new_state = DevState.uploadUnit(event as UploadUnitDevEvent);
            break;
         case EIJDevEvents.uploadFinished:
            new_state = DevState.uploadFinished(event as UploadDevFinishedEvent);
            break;
         case EIJDevEvents.uploadUnitFinished:
            new_state = DevState.uploadUnitFinished(event as UploadDevUnitFinishedEvent);
            break;
         case EIJDevEvents.saveFinished:
            new_state = DevState.saveFinished(event as SaveDevFinishedEvent);
            break;
         case EIJDevEvents.syncConflict:
            new_state = DevState.onSyncConflict(event as SyncConflictDevEvent);
            break;
         case EIJDevEvents.resolveConflict:
            new_state = DevState.onResolveSyncConflict(event as ResolvedSyncConflictDevEvent);
            break;
         case EIJDevEvents.validationError:
            new_state = DevState.onValidationError(event as ValidationErrorDevEvent);
            break;
         case EIJDevEvents.setState:
            new_state = DevStateSetState();
            break;
         default:
            throw Exception('Uncuahgt exception');
      }
      DevState.debug('yield state: ${new_state}');
      yield new_state;
   }
   void onSetState(){
      dispatch(DevSetStateEvent());
   }
   void onDeviceEdit(int device_id, [DeviceModel model]) {
      dispatch(EditDevEvent(device_id: device_id, model: model));
   }
   void onDeviceDel(int inferredId) {
      dispatch(DelDevEvent(inferred_id: inferredId));
   }
   
   void onDevAdd({int device_id, DeviceModel model}) {
      final event = AddDevEvent(device_id: device_id, model: model);
      dispatch(event);
   }
   
   void onDeviceMerge(int master_id, int slave_id) {
      dispatch(MergeDevEvent(
         device_id: master_id,
         merged_id: slave_id));
   }

   void onDeviceSave([String filename]) {
      dispatch(SaveDevEvent(
         filename: filename));
   }
   
   void onDevUpload() {
      dispatch(UploadDevEvent());
   }
   
   void onDevUnitUpload(DeviceModel model) {
      dispatch(UploadUnitDevEvent(model));
   }
   
   void onDeviceSaveFinished(String message) {
      dispatch(SaveDevFinishedEvent(message));
   }
   
   void onDeviceUnitUploadFinished(String message, Response response) {
      final event = UploadDevUnitFinishedEvent(message, response);
      dispatch(event);
   }
   
   void onDeviceUploadFinished(String message, Response response) {
      dispatch(UploadDevFinishedEvent(message, response));
   }
   
   void onDeviceBrowse() {
      dispatch(BrowseDevEvent());
   }
   
   void onDevUndo() {
      dispatch(UndoDevEvent());
   }
   
   void onDevRedo() {
      dispatch(RedoDevEvent());
   }
   
   void onDevUndoUnit(int device_id) {
      dispatch(UndoUnitDevEvent(device_id));
   }
   
   void onDevRedoUnit(int device_id) {
      dispatch(RedoUnitDevEvent(device_id));
   }
   
   void onSyncConflict(){
      dispatch(SyncConflictDevEvent());
   }
   
   void onResolveConflict(List<bool> confirmConflict){
      dispatch(ResolvedSyncConflictDevEvent(confirmConflict));
   }
   
   void onDeviceValidationError(Response data){
      dispatch(ValidationErrorDevEvent(data));
   }
   
}