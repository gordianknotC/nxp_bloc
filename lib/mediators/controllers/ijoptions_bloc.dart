import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/common_states_manager.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_state.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/permission.dart';
import 'package:nxp_bloc/mediators/di.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/consts/server.dart';
import 'package:nxp_bloc/mediators/models/model_error.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';


class DescOptMainStatePost<ST extends BaseIJOptState> extends BasePostService<ST> {
   @override BaseStatesManager<ST> manager;
   @override BaseValidationService<ST> validator;
   @override BaseMessageService msgbloC;
   @override String del_request_path;
   @override String post_request_path;
   @override String merge_request_path;
   
   DescOptMainStatePost(this.post_request_path, this.del_request_path,
                        this.merge_request_path, this.msgbloC, this.validator, this.manager)
      : super(post_request_path, del_request_path, merge_request_path, msgbloC, validator, manager);
   
   @override dynamic onDelRequest() {
      // TODO: implement onDelRequest
      if (manager.del_states.isNotEmpty) {
         return Http().dioPost(
            '${del_request_path}0',
            body: manager.del_states.map((BaseIJOptState s) => s.option_id).toList(),
            headers: {
               'request_type': 'del'
            });
      }
      return null;
   }
   @override
   List<Map<String, dynamic>> getUploadData({List<int> ids}) {
      final result = <Map<String, dynamic>>[];
      // fixme: sates_forUi
      manager.states_forUi.forEach((k, v) {
         if (ids == null)
            result.add(v.last.option.asMap());
         else if (ids.contains(k))
            result.add(v.last.option.asMap());
      });
      return result;
   }
}

class DescOptMainStateGet<ST extends BaseIJOptState> extends BaseGetService<ST> {
   DescOptMainStateGet(String get_request_path, BaseStatesManager<ST> manager) : super(get_request_path, manager);
   
   @override
   Future<Response> onGet({Map<String, dynamic> query, int retries = 1, bool isCached = true}) async {
      //fetch all
      return await Http().dioGet(get_request_path, qparam: {
         'pagenum': -1, 'perpage': -1
      }, isCached: isCached);
   }
}


class DescOptMainStateValidator<ST extends BaseIJOptState> extends BaseValidationService<ST> {
   DescOptMainStateValidator(this.manager, this.get) : super(manager, get);
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   
   @override bool validate(ST state, List<Map<String, dynamic>> source) {
      final self = source.firstWhere((d) => d['id'] == manager.matcher.idGetter(state), orElse: () => null);
      if (self != null)
         source.remove(self);
      state.option.validate(source);
      return !state.option.hasValidationErrors;
   }
}

class DescOptMainStateStore<ST extends BaseIJOptState> extends BaseStoreService<ST> {
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   @override String unsavedpath;
   @override String localpath;
   
   DescOptMainStateStore(this.localpath, this.unsavedpath, this.manager, this.get)
      : super(localpath, unsavedpath, manager, get);
   
   @override
   List beforeDump(List<BaseIJOptState> states, dynamic json) {
      FN.prettyPrint(states);
      final dataOnServer = List<Map<String, dynamic>>.from(json as List);
      final options = states.map((state) => state.option).toList();
      final localdata = options.map((option) => option.asMap()).toList();
      return localdata;
   }
   
   @override
   List<ST> getStatesToBeDump() {
      final result = DescOptState.states.values.map((v) => v.last as ST).toList();
      return result;
   }
}

class DescOptMainStateConverter<ST extends BaseIJOptState> extends BaseStateConverter<ST> {
   DescOptMainStateConverter(this.manager) : super(manager);
   @override BaseStatesManager<ST> manager;
   
   @override ST mapDataToState(Map<String, dynamic> data) {
      final option = IJOptionModel.from(data);
      return OptStateAdd(option) as ST;
   }
   
   @override Map<String, dynamic> mapStateToData(BaseIJOptState state, {bool considerValidation = false}) {
      return state.option.asMap(considerValidation: considerValidation);
   }
}

class DescOptMainStateMatcher<ST extends BaseIJOptState> extends BaseStateMatcher<ST> {
   @override bool uploadMatcher(ST state) => state is OptStateUpload;
   
   @override bool redoMatcher(ST state) => state is OptStateRedo;
   
   @override bool undoMatcher(ST state) => state is OptStateUndo;
   
   @override bool delMatcher(ST state) => state is OptStateDel;
   
   @override int idGetter(ST state) => state.option_id;
   
   @override int idSetter(ST state, int id) => state.option.id = id;
   
   @override void clearId(ST state) => state.option.id = null;
   
}

class DescOptMainStateManager<ST extends BaseIJOptState> extends BaseStatesManager<ST> {
   @override BaseStateConverter<ST> converter;
   @override BaseStateMatcher<ST> matcher;
   @override BaseStateProgress progressor;
   @override StoreInf Function(String path) file;
   @override ConfigInf config;
   
   
   DescOptMainStateManager(this.config, this.file, {this.converter, this.matcher, this.progressor, void onInitialError(e)})
      : super(converter, matcher, progressor) {
      DescOptState.manager = this;
      converter   = DescOptMainStateConverter(this);
      matcher     = DescOptMainStateMatcher();
      progressor  = BaseStateProgress();
      const localpath   = 'nxp.db.offline.opt.json';
      const unsavedpath = 'nxp.db.offline.opt.unsaved.json';
      final get_request_path  = '/${ename(ROUTE.descoption)}/all/';
      final post_request_path = '/${ename(ROUTE.descoption)}/batch/';
      final del_request_path  = '/${ename(ROUTE.descoption)}/del/';
      final msgBloC           = MessageBloC();
      
      msg   = BaseMessageService(msgBloC, this);
      get   = DescOptMainStateGet(get_request_path, this);
      post  = DescOptMainStatePost(
         post_request_path, del_request_path,
         null, msg,
         DescOptMainStateValidator(this, get), this
      );
      store    = DescOptMainStateStore(localpath, unsavedpath, this, get);
      remember = HistoryService(this, config.app.history);
      fetchInitialData().then((e){
      }).catchError(onInitialError);
   }
}


/*class DescOptMainStateManager2 extends BaseMainStateManager <BaseIJOptState> {
   //@fmt:off
   DescOptMainStateManager2(){
      localpath   = 'nxp.db.offline.opt.json';
      unsavedpath = 'nxp.db.offline.opt.unsaved.json';
      get_request_path  = '/${ename(ROUTE.descoption)}/all/';
      post_request_path = '/${ename(ROUTE.descoption)}/batch/';
      del_request_path  = '/${ename(ROUTE.descoption)}/del/';
      clearId     = (state) => state.option.id = null;
      idGetter    = (state) => state.option.id;
      idSetter    = (state, id) => state.option.id = id;
      msgbloC     = MessageBloC();
      
      fetchInitialData();
   }
   
   @override bool uploadMatcher  (BaseIJOptState state) => state is OptStateUpload;
   @override bool redoMatcher    (BaseIJOptState state) => state is OptStateRedo;
   @override bool undoMatcher    (BaseIJOptState state) => state is OptStateUndo;
   @override bool unsavedMatcher (BaseIJOptState state) => state is OptStateAdd || state is OptStateEdit;
   @override bool delMatcher     (BaseIJOptState state) => state is OptStateDel;
   @override bool validate       (BaseIJOptState state, List<Map<String,dynamic>> source){
      state.option.validate(source);
      return !state.option.hasValidationErrors;
   }
   
   //@fmt:on
   @override beforeDump(List<BaseIJOptState> states, json) {
      FN.prettyPrint(states);
      final dataOnServer = List<Map<String, dynamic>>.from(json as List);
      final options = states.map((state) => state.option).toList();
      final localdata = options.map((option) => option.asMap()).toList();
      return localdata;
   }

   @override
   BaseIJOptState mapDataToState(Map<String, dynamic> data) {
      final option = IJOptionModel.from(data);
      return OptStateAdd(option);
   }

   @override
   Map<String, dynamic> mapStateToData(BaseIJOptState state, {bool considerValidation = false}) {
      return state.option.asMap(considerValidation: considerValidation);
   }

   @override List<Map<String, dynamic>>
   getUploadData() {
      final result = <Map<String, dynamic>>[];
      // fixme: sates_forUi
      states_forUi.forEach((k, v) {
         result.add(v.last.option.asMap());
      });
      return result;
   }

   @override
   dynamic updateInitialData() {}
}*/



class DescOptState {
   //@fmt:off
//   static BgProc get processing    => AppState.processing;
   static String get state_message => AppState.state_message;
   static String get file_path     => manager.ident;
//   static        set processing   (BgProc v) => AppState.processing   = v;
   static        set state_message(String v) => AppState.state_message = v;
   static        set file_path    (String v) => manager.ident         = v;
   static DescOptMainStateManager<BaseIJOptState> manager;
   
   //@fmt:on
   static Map<int, List<BaseIJOptState>> get states => manager.states_forUi;

   static Map<int, int> get unsaved_devices => manager.unsaved_states;

   static Map<int, BaseIJOptState> get merged_devices => {};
   static List<List<Map<String, dynamic>>> conflictStack = [];
   static List<List<bool>> resolvedConflictStack         = [];

   static IJOptBloC bloC;

   static LoggerSketch debug = AppState.getLogger('Desc');

   static Future<IJOptionModel>
   getOptionByOptionId(int option_id) async {
      final modelmap = List<Map<String, dynamic>>.from(
         await manager.fetchInitialData() as List)
         .firstWhere(
            (m) => (m['id'] as int) == option_id
         , orElse: () => null
      );
      if (modelmap != null)
         return IJOptionModel.from(modelmap);
      return states[option_id].last.option;
   }

   static List<Map<String,dynamic>>
   inferValidationSampleByResponseIds(IJOptionModel model, Map<String,dynamic> body){
      final name        = model.name;
      final desc    = model.description;
      final isCurrentName = body['name'] as int == model.id;
      final isCurrentDesc = body['desc'] as int == model.id;
      final nameNotFound = body['name'] == null ;
      final descNotFound = body['desc'] == null;
      var result     = <Map<String,dynamic>>[];
   
      if (isCurrentName){
      }else{
         if(!nameNotFound)
            result.add({'name': name});
      }
      if (isCurrentDesc){
      }else{
         if (!descNotFound)
            result.add({'description': desc});
      }
      return result;
   }
   /*
   *     called from ui for user form data validation
   *     return a data map, mapping to existing user id
   *
   * */
   static Future<Map<String,dynamic>> validateOptForm(IJOptionModel model) async {
      final name = model.name;
      final desc = model.description;
      const url = '/descoption/validate/';
      final res = await Http().dioGet(url, qparam: {
         'name': name,
         'description': desc
      });
      final completer = Completer<Map<String,dynamic>>();
      final emptyResult = <String,dynamic>{};
   
      if (res.statusCode != 404 && res.statusCode != 200 && res.statusCode != 409) {
         manager.msg.bloC.onInferNetworkError(res.statusCode, null, null);
         completer.complete(null);
      
      } else if (res.statusCode == 404){
         debug('query not found');
         completer.complete(null);
      
      } else if (res.statusCode == 200){
         final body = res.data as Map<String, dynamic>;
         final validate_source = inferValidationSampleByResponseIds(model, body);
         debug('validate query: $body');
         debug('validate body : $validate_source');
         debug('validate model: ${model.asMap()}');
         model.validate(validate_source);
         final validated = model.asMap(considerValidation: true)[ResponseConst.ERR_CONTAINER]
         as Map<String,dynamic> ?? emptyResult;
         final result = <String,dynamic>{};
      
         FN.updateMembers(result, validated,
             members:['name', 'description']);
      
         completer.complete(result);
      
      } else if (res.statusCode == 409) {
         // note: since no data sync check on server, so it can't be 409
         debug.error('statusCode 409 Uncaught exception');
         throw Exception('statusCode 409 Uncaught exception');
         /*final map = currentUser.asMap();
         (res.data as Map<String,dynamic>).forEach((k, v){
            map[k] = v;
         });
         return map;*/
      }
   
      return completer.future;
   }
   
   static BaseIJOptState
   redo(RedoOptEvent event) {
      final result = manager.saveState(
         OptStateRedo(), null, addToUnsaved: false
      );
      return result;
   }

   static BaseIJOptState
   undo(UndoOptEvent event) {
      final result = manager.saveState(
         OptStateUndo(), null, addToUnsaved: false
      );
      return result;
   }

   static Future<BaseIJOptState>
   add(AddOptEvent event) async {
      final inferred_id = event.option_id ?? manager.inferId(event.option_id);
      final option = event.option ?? IJOptionModel("", "");
      option.id ??= inferred_id;
      final result = manager.saveState(
         OptStateAdd(option),
         inferred_id,
         addToUnsaved: true
      );
      assert(result is OptStateAdd);
      return result;
   }

   static Future<BaseIJOptState>
   edit(EditOptEvent event) async {
      final option_id = event.option_id;
      final option = event.option ?? await getOptionByOptionId(option_id);
      final result = manager.saveState(
         OptStateEdit(option_id, option),
         option_id,
         addToUnsaved: true
      );
      return result;
   }

   static Future<BaseIJOptState>
   del(DelOptEvent event) async {
      try {
         final option_id = event.option_id;
         final option = event.option ?? await getOptionByOptionId(option_id);
         debug('before del option: ${manager.states.values.map((l) => l.map((o) => o.option.name).join('\n'))}');
         final result = manager.saveState(
             OptStateDel(option_id, option),
             option_id,
             addToUnsaved: false
         );
         debug('after del option: ${manager.states.values.map((l) => l.map((o) => o.option.name).join('\n'))}');
         debug('del: ${option_id}, ${option.name}, ${option.description}, ${result.runtimeType}');
         return result;;
      } catch (e, s) {
         print('[ERROR] DescOptState.del failed: \n$s');
         rethrow;
      }
   }



   static BaseIJOptState
   browse(BrowseOptEvent event) {
      // todo:
      // 1) dump file to disk
      // 2) notify users of unsaved states
      /// dump data to disk
      /// upload data to server
   
      return OptStateBrowse();
   }

   static final String savingId = uuid.v4();
   
   static Future saveAction({void onSaving(), void onSaved(), void onSaveFailed()}){
      FN.callEither(onSaving, () => manager.msg.bloC.onFileSaving(savingId));
      return manager.dumpToDisk().then((e) {
         FN.callEither(onSaved, () => manager.msg.bloC.onFileSuccessfullySaved(savingId));
         bloC.onOptSaveFinished(Msg.OK);
      }).catchError((e, s) {
         FN.callEither(onSaveFailed, () => manager.msg.bloC.onFileSavingFailed(savingId));
         bloC.onOptSaveFinished(e.toString());
         debug.error("$e");
         throw Exception('$s');
      });
   }
   
   static BaseIJOptState
   save(SaveOptEvent event) {
      final filepath = event.filename ?? file_path;
      final result = manager.saveState(OptStateSave(filepath), null);
      saveAction();
      return result;
   }

   static BaseIJOptState
   saveFinished(SaveOptFinishedEvent event) {
      debug.info('${event.runtimeType} save finished');
      debug.info('options: ${manager.states.values.map((l) => l.map((o) => o.option.name).join('\n'))}');
      final result = manager.saveState(OptStateSaveFinisehd(event.message), null);
      return result;
   }
   
   static BaseIJOptState
   onSyncConflict(SyncConflictOptEvent event){
      return OptStateSyncConflict();
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
   
   static BaseIJOptState
   onResolveSyncConflict(ResolvedSyncConflictOptEvent event){
      if (conflictStack.isEmpty)
         return null;
      if (event.confirmConflict.first){
         _discardClient();
      }else{
         _discardServer();
      }
      return OptStateResolveSyncConflict(event.confirmConflict);
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
      if (manager.isSyncConflictResponse(data)){
         saveSyncConflict(data);
         manager.msg.bloC.onFileUploadingFailed(Msg.onSyncConflict, uploadingId);
         bloC.onSyncConflict();
      }else{
         if (manager.isValidationResponse(data)) {
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadValidationError, uploadingId);
            bloC.onOptValidationError(data);
         } else if (data.statusCode == 200){
            manager.msg.bloC.onFileUploadingSuccess(uploadingId);
            bloC.onOptUploadFinished(Msg.OK, data);
         }else{
            manager.msg.bloC.onFileUploadingFailed(Msg.onUploadFailed(""), uploadingId);
            bloC.onOptUploadFinished(Msg.onUploadFailed(""), data);
         }
      }
      return data;
   }
   static final String uploadingId = uuid.v4();
   
   static Future<Response> uploadAction(){
      manager.msg.bloC.onFileUploading(uploadingId);
      return manager.uploadToServer().then(afterUpload).catchError((e) {
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         manager.msg.bloC.onFileUploadingFailed(e.toString(), uploadingId);
         throw Exception(str);
      });
   }
   
   static BaseIJOptState
   upload(UploadOptEvent event) {
      final result = manager.saveState(OptStateUpload(), null);
      uploadAction();
      return result;
   }

   static BaseIJOptState
   uploadFinished(UploadOptFinishedEvent event) {
      final result = manager.saveState(
         OptStateUploadFinished(event.message, event.response), null);
      updateStatesByResponse(event.response);
      return result;
   }

   static void updateStatesByResponse(Response response) {
      if (response == null)
         return;
   }

   static BaseIJOptState
   onValidationError(ValidationErrorOptEvent event){
      final result = OptStateValidationError(event.response);
      //final bodies = List<Map<String,dynamic>>.from(event.response.data as List);
      state_message = Msg.onUploadFormValidationError;
      return result;
   }
}



class IJOptBloC extends Bloc<IJOptEvents, BaseIJOptState> {
   BaseIJOptState last_state;
   OptAuthGuard authGuard;
   IJOptBloC(DescOptMainStateManager manager){
      DescOptState.manager = manager;
      DescOptState.bloC = this;
      authGuard = OptAuthGuard(manager);
   }
   
   @override BaseIJOptState
   get initialState {
      DescOptState.bloC = this;
      return OptStateDefault();
   }
   
   @override
   void onError(Object error, StackTrace stacktrace) {
      // TODO: implement onError
      super.onError(error, stacktrace);
      throw Exception(stacktrace);
   }
   @override
   Stream<BaseIJOptState> mapEventToState(IJOptEvents event) async* {
      if (currentState == last_state)
         yield null;
      
      last_state = currentState;
      BaseIJOptState new_state;
      switch (event.event) {
         case EIJOptEvents.add:
            new_state = await DescOptState.add(event as AddOptEvent);
            assert(new_state is OptStateAdd);
            break;
         case EIJOptEvents.edit:
            new_state = await DescOptState.edit(event as EditOptEvent);
            break;
         case EIJOptEvents.del:
            new_state = await DescOptState.del(event as DelOptEvent);
            break;
         case EIJOptEvents.undo:
            new_state = DescOptState.undo(event as UndoOptEvent);
            break;
         case EIJOptEvents.redo:
            new_state = DescOptState.redo(event as RedoOptEvent);
            break;
         case EIJOptEvents.browse:
            new_state = DescOptState.browse(event as BrowseOptEvent);
            break;
         case EIJOptEvents.setState:
            new_state = OptStateSetState();
            break;
         case EIJOptEvents.save:
            new_state = DescOptState.save(event as SaveOptEvent);
            break;
         case EIJOptEvents.upload:
            new_state = DescOptState.upload(event as UploadOptEvent);
            break;
         case EIJOptEvents.uploadFinished:
            new_state = DescOptState.uploadFinished(event as UploadOptFinishedEvent);
            break;
         case EIJOptEvents.saveFinished:
            new_state = DescOptState.saveFinished(event as SaveOptFinishedEvent);
            break;
         case EIJOptEvents.syncConflict:
            new_state = DescOptState.onSyncConflict(event as SyncConflictOptEvent);
            break;
         case EIJOptEvents.resolvedSyncConflict:
            new_state = DescOptState.onResolveSyncConflict(event as ResolvedSyncConflictOptEvent);
            break;
         case EIJOptEvents.validationError:
            new_state = DescOptState.onValidationError(event as ValidationErrorOptEvent);
            break;
         default:
            throw Exception('Uncuahgt exception');
      }
      DescOptState.debug('yield state: ${new_state}');
      yield new_state;
   }
   
   
   
   void onOptEdit(int option_id, [IJOptionModel option]) {
      dispatch(EditOptEvent(option_id: option_id, option: option));
   }
   
   void onOptAdd({int option_id, IJOptionModel option}) {
      dispatch(AddOptEvent(option_id: option_id, option: option));
   }
   
   void onOptDel(int option_id, [IJOptionModel option]) {
      dispatch(DelOptEvent(option_id: option_id, option: option));
   }
   
   void onOptSave([String filename]) {
      dispatch(SaveOptEvent());
   }
   
   void onOptUpload() {
      dispatch(UploadOptEvent());
   }
   
   void onOptSaveFinished(String message) {
      dispatch(SaveOptFinishedEvent(message));
   }
   
   void onOptUploadFinished(String message, Response response) {
      dispatch(UploadOptFinishedEvent(message, response));
   }
   
   void onOptBrowse() {
      dispatch(BrowseOptEvent());
   }
   void onOptSetState() {
      dispatch(SetStateOptEvent());
   }
   
   void onOptUndo() {
      dispatch(UndoOptEvent());
   }
   
   void onOptRedo() {
      dispatch(RedoOptEvent());
   }
   
   void onSyncConflict(){
      dispatch(SyncConflictOptEvent());
   }
   
   void onResolveConflict(List<bool> confirmConflict){
      dispatch(ResolvedSyncConflictOptEvent(confirmConflict));
   }
   
   void onOptValidationError(Response data){
      dispatch(ValidationErrorOptEvent(data));
   }
}


