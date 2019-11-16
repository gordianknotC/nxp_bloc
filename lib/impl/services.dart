import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' show Response, StreamedResponse, MultipartRequest;
import 'package:http/http.dart' as http;
import 'package:common/common.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:nxp_bloc/consts/http.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/common_states_manager.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/mediators/di.dart';
import 'package:nxp_bloc/mediators/models/model_error.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';


class BaseValidationService<ST> {
   BaseValidationService(this.manager, this.get);
   BaseStatesManager<ST> manager;
   BaseGetService<ST> get;
   
   bool checkValidation() {
      var hasErrors = false;
      try {
         final data = List<Map<String, dynamic>>.from(get.initialData as List);
         manager.states_forUi.forEach((k, v) {
            if (!validate(v.last, data))
               hasErrors = true;
         });
         return !hasErrors;
      } catch (e) {
         throw Exception(StackTrace.fromString(e.toString()));
      } finally {
         return !hasErrors;
      }
   }

   bool validate(ST state, List<Map<String, dynamic>> source) =>
      throw Exception('NotImplemented yet');

   Dio.Response genValidationResponse() {
      final body = <Map<String, dynamic>>[];
      manager.states_forUi.forEach((k, v) {
         body.add(manager.converter.mapStateToData(v.last, considerValidation: true));
      });
      return Dio.Response(statusCode: 409, data: body);
   }
   
   

   bool isValidationResponse(Dio.Response res) {
      if (res.statusCode != 409)
         return false;
      final data = List<Map<String,dynamic>>.from(res.data as List);
      return data.any((rec) => rec.containsKey(ResponseConst.ERR_CONTAINER));
   }
}

class BaseMessageService<ST> {
   BaseMessageService(this.bloC, this.manager);
   BaseStatesManager<ST> manager;
   MessageBloC bloC;
   StreamSubscription<MsgEvents> subscription;
   //incompleted:
   Future<Dio.Response> receiveUserInqueryUploadOperation(Future<Dio.Response> request()) {
      return _receiveUserInqueryOnece<Dio.Response>(
         matchedEvents: [MsgInquiryUploadResponseOKEvent, MsgInquiryUploadResponseCancelEvent],
         onDoEvent: MsgInquiryUploadResponseOKEvent,
         onDo: () {
            /// clear all histories after
            ///      1) deleting operation on server
            ///      2) overriding operation on server
            /// no matter which records on server are involved in current history.
            /// this can be fixed in the future todo:
   
            manager.remember?.stateHistory?.flag = 0;
            manager.remember?.saveAndClearPrevHistory();
            //clearStatesByFlag(0);
            return request();
         }
      );
   }
   
   //incompleted:
   void receiveUserInqueryUndoableOperation() {
      _receiveUserInqueryOnece<void>(
         matchedEvents: [MsgNonUndoableResponseOKEvent, MsgNonUndoableResponseCancelEvent],
         onDoEvent: MsgNonUndoableResponseOKEvent,
         onDo: () {
            /// clear all histories after
            ///      1) deleting operation on server
            ///      2) overriding operation on server
            /// no matter which records on server are involved in current history.
            /// this can be fixed in the future todo:
            manager.remember?.stateHistory?.flag = 0;
            manager.remember?.saveAndClearPrevHistory();
            return;
         }
      );
   }

   Future<E> _receiveUserInqueryOnece<E>({List<Type> matchedEvents, Type onDoEvent, Future<E> onDo()}) {
      final completer = Completer<E>();
      subscription = bloC.state.listen((event) {
         if (matchedEvents.any((event_type) => event.runtimeType == event_type)) {
            subscription?.cancel();
            if (event.runtimeType == onDoEvent) {
               completer.complete(onDo());
            }
         }
      });
      return completer.future;
   }
}

class BasePostService<ST> {
   BasePostService(
      this.post_request_path, this.del_request_path, this.merge_request_path,
      this.msgbloC, this.validator, this.manager
   );
   BaseMessageService msgbloC;
   BaseValidationService<ST> validator;
   BaseStatesManager<ST> manager;
   String post_request_path;
   String edit_request_path;
   String del_request_path;
   String merge_request_path;
   List<Map<String, dynamic>> body;
   List<Dio.Response> response_list;
   
   /*
      uploadToServer
         | beforeUpload
         |    - updateInitialData
         | getUploadData
         | messageBloc
         | validatorResponse
      onUploadRequest | onDelRequest | onMergeRequest
      onUploadSuccess
         resetOnUploadSuccess();
         saveOnUploadSuccess();
   */
   
   /// called before uploading, for preparing uploading data
   List<Map<String, dynamic>> getUploadData() {
      throw Exception('NotImplemented yet');
   }
   
   void updateInitialData() {}
   
   
   void beforeUpload() {
      manager.clearInferredIdsInStates();
      updateInitialData();
   }

   Dio.Response onValidateFailed(){
      return validator.genValidationResponse();
   }
   
   Future<Dio.Response> uploadToServer({bool safety = false}) async {
      if (validator.checkValidation()) {
         beforeUpload();
         body = getUploadData();
         final isDbOverriden = manager.hasOverridingIds(body);
         
         if (!safety) {
            return await _uploadRequest(isDbOverriden);
         } else {
            // todo:
            // 1) implementing history reset while isDbOverriden
            if (isDbOverriden) {
               // found overriding operation on server - reset history
               msgbloC.bloC.onUserInquiryUploadRequest();
               return await msgbloC.receiveUserInqueryUploadOperation(() {
                  return _uploadRequest(isDbOverriden);
               });
            } else {
               return await _uploadRequest(isDbOverriden);
            }
         }
      } else {
         return onValidateFailed();
      }
   }
   //untested:
   dynamic onDelRequest() {
      if (manager.del_states.isNotEmpty) {
         final del_body = manager.del_states.map(manager.converter.mapStateToData).toList();
         manager.del_states = [];
         return Http().dioPost(del_request_path, body: del_body, headers: {
            'request_type': 'del'
         });
      }
      return null;
   }

   //untested:
   dynamic onMergeRequest() {
      if (manager.merge_states.isNotEmpty) {
         final params = <String, dynamic>{
            'merged_data': <String, dynamic>{}
         };
         for (var i = 0; i < manager.merge_states.length; ++i) {
            final list_states = manager.merge_states[i];
            params['merged_data'][i.toString()] = [
               manager.converter.mapStateToData(list_states[0]),
               manager.converter.mapStateToData(list_states[1])
            ];
         }
         manager.merge_states = [];
         return Http().dioPost(merge_request_path, body: params, headers:{
            'request_type': 'merge'
         });
      }
      return null;
   }
   Future<Dio.Response> onPost() {
      return Http().dioPost(post_request_path, body: body, headers: {
         'request_type': 'post'
      });
   }
   
   Future<List<Dio.Response>> onUploadRequest([Future<Dio.Response> del_request, Future<Dio.Response> merge_request]) {
      Future<List<Dio.Response>> final_request;
      Future<Dio.Response> post_request;
      List<Future<Dio.Response>> final_res = [];
      try{
         post_request = onPost();
         if (del_request != null)
            final_res.add(del_request);
         if (merge_request != null)
            final_res.add(merge_request);
         if (post_request != null)
            final_res.add(post_request);
         return Future.wait(final_res);
         /*if (del_request == null && merge_request == null) {
            final_request = Future.wait([post_request]);
         } else if (del_request == null) {
            final_request = Future.wait([merge_request, post_request]);
         } else if (merge_request == null) {
            final_request = Future.wait([del_request, post_request]);
         } else {
            final_request = Future.wait([del_request, merge_request, post_request]);
         }
         return final_request;*/
      }catch (e){
         throw Exception(StackTrace.fromString(e.toString()));
      }
   }
   
   //untested:
   Future<Dio.Response> _uploadRequest(bool isDbOverriden) async {
         Future<Dio.Response> del_request, merge_request ;
         final d = onDelRequest();
         final m = onMergeRequest();
         guard((){
            del_request = d == null
                          ? null
                          : d as Future<Dio.Response>;
            merge_request = m == null
                            ? null
                            : m as Future<Dio.Response>;
         }, 'onSending delrequest/mergerequest failed', raiseOnly: false);
         
         //fixme:
         return await onUploadRequest(del_request, merge_request)
             .then((List<Dio.Response> response) async {
                  return guard(() async {
                     final completer = Completer<List<Dio.Response>>();
                     final result    = <Dio.Response>[];
                     response_list = response;
                     response_list.forEach((res) {
                        if (res.statusCode == 200 && res.data != null){
                           result.add(onUploadSuccess(res));
                        }else if (res.statusCode == 409){
                           result.add(onUploadConflict(res));
                        }else{
                           result.add(onUploadFailed(res));
                        }
                     });
                     return await onUploadComplete(result, isDbOverriden);
                  }, 'onSending upload request failed', raiseOnly:false);
            }).catchError((e){
               onUploadError(e);
         });
   }
   Future<Dio.Response>  onUploadComplete(List<Dio.Response> res, bool isDbOverriden) async {
      final response = response_list.last;
      ///
      /// clear all histories after
      ///      1) deleting operation on server
      ///      2) overriding operation on server
      ///   no matter which records on server are involved in current history.
      ///   this can be fixed in the future todo:
      ///
      return guard((){
         if (response.statusCode == 200){
            print('[service] upload success');
            assert(response.data is List);
            resetOnUploadSuccess();
            saveOnUploadSuccess();
         }else{
            print('[service] upload failed');
            /* resetOnUploadFailed(res);
               saveOnUploadFailed(res);*/
            //manager.undo();
         }
         return response;
      }, "uploadComplete failed");
      
   }

   void onUploadError(Object message){
      print('[service] onuploadError');
      manager.inferred_ids.forEach((k){
         if(manager.states[k]?.last != null && manager.matcher.idGetter(manager.states[k]?.last) == null){
            manager.matcher.idSetter(manager.states[k]?.last, k);
         }
      });
   }
   Dio.Response onUploadSuccess(Dio.Response res){
      print('[service] onUploadSuccess');

      //todo:
      return res;
   }
   Dio.Response onUploadConflict(Dio.Response res) {
      print('[service] onUploadConflict');

      //todo:
      return res;
   }
   Dio.Response onUploadFailed(Dio.Response res) {
      print('[service] onUploadFailed');

      //todo:
      return res;
   }
   
   void resetOnUploadSuccess() {
      manager.inferred_ids = Set.from([]);
      manager.unsaved_states = {};
      manager._renewUiStatesByMap(
         List<Map<String, dynamic>>.from(response_list.last.data as List));
      manager._recordStatesByUiStates();
   }
   
   void saveOnUploadSuccess() {
      manager.remember?.saveAndClearPrevHistory();
      manager._appendUiStatesIntoIntialData();
   }

  


   
   
   
}

class BaseGetService<ST> {
   BaseGetService(this.get_request_path, this.manager);
   BaseStatesManager<ST> manager;
   
   String get_request_path;
   dynamic initialData;
   
   Future<dynamic> renew() async {
      initialData = null;
      Http.cache.clearKeysContains(get_request_path);
      return await fetch();
   }
   
   Future<Dio.Response> beforeGet(){
      return null;
   }

   Future<Dio.Response> onRetry({Map<String, dynamic> query, int max_retries = 5}) async {
      for (var i = 2; i < max_retries; ++i) {
         final res =  await onGet(query: query, retries: i);
         if (res.statusCode == 200)
            return afterGet(res, retries: i);
         afterGet(res, retries: i);
      }
   }
   
   Future<Dio.Response> onGet({Map<String, dynamic> query, int retries = 1, bool isCached = true}) async {
      return await Http().dioGet(get_request_path, isCached: isCached, qparam: query).then((res){
         return res;
      }).catchError((e){
         final error = e.toString();
         if (error.contains('Connection failed')){
            onConnectionFailed();
         } else if (error.contains("No route to host")){
            onNoRouteToHost();
         }
         throw Exception(StackTrace.fromString(e.toString()));
      });
   }

   void onConnectionFailed(){

   }
   void onNoRouteToHost(){

   }
   
   Future<Dio.Response> fetch({Map<String, dynamic> query}) async {
      if (get_request_path == null)
         return null;
      final gorequest = await beforeGet();
      final result = gorequest == null
         ? await onGet(query: query, isCached: false)
         : gorequest;
      return afterGet(result);
   }

   Dio.Response afterGet(Dio.Response response, {int retries = 1}){
      if (manager.store != null){
         if (response.statusCode != 200) {
            manager.msg.bloC.onInferNetworkError(response.statusCode, 'tempid', null);
            return response;
         } else {
            manager.file(manager.store.localpath).writeSync(jsonEncode(response.data) );
            initialData = response.data;
         }
      }
      return response;
   }
}



 class BaseStoreService<ST> {
   BaseStoreService(this.localpath, this.unsavedpath, this.manager, this.get);
   // fixme: the same with finaldata, but not sure.
   // combine those two into one while make uncertain certain.
   dynamic cache;
   List finaldata;
   String localpath;
   String unsavedpath;
   
   BaseStatesManager<ST> manager;
   BaseGetService<ST>   get;

   bool get hasSavedLocalFile =>
      manager.file(localpath).existsSync();
   bool get hasUnsavedFile =>
      manager.file(unsavedpath).existsSync();

   List<ST> getStatesToBeDump() {
      //fixme: it's problematic....
      // getStatesToBeDump implicitly indicates states_forUi
      return manager.converter.unsavedRefsToStates();
   }
   
   List beforeWrite() {
      finaldata.add({
         'inferred_ids': manager.inferred_ids.toList()
      });
      return finaldata;
   }
   
   Future<StoreInf> write({bool unsaved = true, String path}) {
      print('manager.file write at path: ${path ?? (unsaved ? unsavedpath : localpath)}');
      return manager.file(
          path ?? (unsaved ? unsavedpath : localpath)
      ).writeAsync(jsonEncode(finaldata));
   }
   
   Future<StoreInf> dump({bool unsaved = true, String path}) async {
      List<ST> states_tobe_dump;
      try{
         states_tobe_dump = getStatesToBeDump();
         if (states_tobe_dump == null)
            return null;   
      }catch(e){
         throw Exception('Failed to get states while dumping to disk\n${StackTrace.fromString(e.toString())}');
      }
      
      finaldata = beforeDump(states_tobe_dump, get.initialData);
      finaldata = beforeWrite();
      return write(unsaved: unsaved, path: path).then(afterDump);
   }

   StoreInf afterDump(StoreInf file) {
      return file;
   }
   
   List beforeDump(List<ST> statesToBeDump, dynamic dataOnServer) {
      throw Exception('NotImplemented');
   }
   
   dynamic afterLoad(String data){
      if (data != null)
         return jsonDecode(data);
   }
   Future load({String path}) async {
   		final _path = path ?? localpath;
      if (_path == null)
         return cache = afterLoad(null);
      if (!manager.file(_path).existsSync())
         return cache = afterLoad(null);
      final string = await manager.file(_path).readAsync();
      return cache = afterLoad(string);
   }
}


class HistoryService<ST> {
   HistoryService(this.manager, int length){
      history = JsonHistory(length);
      stateHistory = RefHistory(length);
      inferredHistory = RefHistory(length);
      accumulatedStateHistory = AccRefHistory(length);
   }
   BaseStatesManager<ST> manager;
   JsonHistory history;
   RefHistory stateHistory;
   RefHistory inferredHistory;
   AccRefHistory accumulatedStateHistory;
   HistoryRegistry registeryHistory;
   
   void registerHistory<T extends HistoryRecord>(T type, String key){
      registeryHistory ??= HistoryRegistry(history.stack.length);
      registeryHistory.registerHistory(type, key);
   }
   
   D beforeSaveJsonHistory<D extends Map<String, dynamic>>(D data) {
      return data;
   }
   
   dynamic saveJsonHistory(dynamic data) {
      history.add(beforeSaveJsonHistory({
         'server': data
      }));
   }
   
   ST beforeSaveStateHistory() {
   
   }
   ST afterSaveStateHistory() {
   
   }
   /*void clearHistory(){
      try{
         history = JsonHistory(history.length);
         stateHistory = RefHistory(history.length);
         inferredHistory = RefHistory(history.length);
         accumulatedStateHistory = AccRefHistory(history.length);
      }catch(e){
         throw Exception("clear history failed:\n${StackTrace.fromString(e.toString())}");
      }
   }*/

   void clearAndSaveHistory(){
      try{
         manager.remember?.stateHistory?.flag = 0;
         manager.remember?.saveAndClearPrevHistory();
      }catch(e){
         throw Exception("clear history failed:\n${StackTrace.fromString(e.toString())}");
      }
   }
   
   /// clear states and states_forUi
   void clearStatesByFlag(int flag) {
      try{
         if (stateHistory.isLastPosition(flag))
            return;
         final available_states = accumulatedStateHistory[flag];
         final unavailable_subids = <int, List<int>>{};
         manager.states.forEach((int k, List<ST> v) {
            if (available_states?.isNotEmpty ?? false){
               final matched_values = available_states.where((rec) => rec[0] == k).toList();
               if (matched_values.isNotEmpty) {
                  final keep_ids = matched_values.map((rec) => rec[1]).toList();
                  final _unavailable = <int>[];
                  for (var i = 0; i < v.length; ++i) {
                     if (!keep_ids.contains(i)) {
                        _unavailable.add(i);
                     }
                  }
                  unavailable_subids[k] ??= _unavailable;
               } else {
                  unavailable_subids[k] ??= List.generate(v.length, (i) => i).toList();
               }
            }
         });
   
         unavailable_subids.forEach((int k, List<int>ids) {
            ids.forEach((id) {
               manager.states[k][id] = null;
            });
            if (manager.states[k].every((state) => state == null)) {
               manager.states.remove(k);
            } else {
               manager.states[k] = manager.states[k].where((state) => state != null).toList();
            }
         });
      }catch(e){
         throw Exception("clearStatesByFlag Failed:\n${StackTrace.fromString(e.toString())}");
      }
   }

   // fixme: it's anoring, since it fetches initial data into disk implicitly
   void saveHistoryWithoutClearance(List<List<int>> statesSnapshot,List<List<int>> inferredSnapshot){
      try {
         for (var key in manager.states_forUi.keys) {
            final subkey = manager.states[key].indexOf(manager.states_forUi[key].last);
            statesSnapshot.add([key, subkey]);
         }
         inferredSnapshot.add(manager.inferred_ids.toList());
      
         inferredHistory.add(inferredSnapshot);
         stateHistory.add(statesSnapshot);
         accumulatedStateHistory.add(statesSnapshot);
         // :: for undo upload
         if (manager.get != null)
            manager.fetchInitialData().then(saveJsonHistory);
         clearStatesByFlag(stateHistory.flag);
      } catch (e) {
         throw Exception('saveHistoryWithoutClearance failed: \n${StackTrace.fromString(e.toString())}');
      }
   }

   // fixme: it's anoring, since it fetches initial data into disk implicitly
   void clearPrevHistoryAndSave(List<List<int>> statesSnapshot, List<List<int>> inferredSnapshot){
      try {
         clearStatesByFlag(stateHistory.flag);
         for (var key in manager.states_forUi.keys) {
            var subkey = manager.states.containsKey(key)
                         ? manager.states[key].indexOf(manager.states_forUi[key].last)
                         : -1;
            if (subkey != -1) {
               statesSnapshot.add([key, subkey]);
            } else {
               manager.states[key] ??= manager.states_forUi[key];
               manager.states[key][manager.states[key].length - 1] = manager.states_forUi[key].last;
               subkey = manager.states[key].indexOf(manager.states_forUi[key].last);
               statesSnapshot.add([key, subkey]);
            }
         }
         inferredSnapshot.add(manager.inferred_ids.toList());
      
         inferredHistory.add(inferredSnapshot);
         stateHistory.add(statesSnapshot);
         accumulatedStateHistory.add(statesSnapshot);
         // :: for undo upload
         if (manager.get != null)
            manager.fetchInitialData().then(saveJsonHistory);
      } catch (e) {
         throw Exception('clearPrevHistoryAndSave failed: \n${StackTrace.fromString(e.toString())}');
      }
   }
   
   void saveAndClearPrevHistory() {
      try{
         final statesSnapshot = <List<int>>[];
         final inferredSnapshot = <List<int>>[];
         beforeSaveStateHistory();
         if (stateHistory.flag == stateHistory.length - 1) {
            saveHistoryWithoutClearance(statesSnapshot, inferredSnapshot);
         } else {
            clearPrevHistoryAndSave(statesSnapshot, inferredSnapshot);
         }
         afterSaveStateHistory();
      }catch(e){
         throw Exception('saveAndClearPrevHistory failed: \n${StackTrace.fromString(e.toString())}');
      }

   }
   
   ST saveHistory({bool undoable = true}) {
      try {
         if (undoable == false) {
            manager.msg?.bloC?.onUserInquiryNonUndoableRequest();
            manager.msg?.receiveUserInqueryUndoableOperation();
         } else {
            saveAndClearPrevHistory();
         }
      } catch (e) {
         throw Exception('saveHistory failed: \n${StackTrace.fromString(e.toString())}');
      }
   }

   List<ST> _refUndo() {
      final refs = stateHistory.undo();
      if (refs == null)
         return null;
      return manager.converter.refsToValue(refs).toList();
   }

   List<ST> _refRedo() {
      final refs = stateHistory.redo();
      if (refs == null)
         return null;
      return manager.converter.refsToValue(refs).toList();
   }

   Map<String, dynamic> _jsonUndo() {
      // {'server': jsonData}
      return history.undo();
   }

   Map<String, dynamic> _jsonRedo() {
      // {'server': jsonData}
      return history.redo();
   }

   Map<String, dynamic> undo() {
      manager.inferred_ids = Set.from(inferredHistory.undo()?.first ?? []);
      final json   = _jsonUndo();
      final states = _refUndo();
      final acc    =  accumulatedStateHistory.undo();
      if (states != null){
         manager._renewUiStatesByMap(states?.map(manager.converter.mapStateToData)?.toList());
         manager._recordStatesByUiStates();
      }
      return json;
   }

   Map<String, dynamic> redo() {
      manager.inferred_ids = Set.from(inferredHistory.redo()?.first ?? []);
      final json = _jsonRedo();
      final states = _refRedo();
      if (states != null){
         accumulatedStateHistory.redo();
         manager._renewUiStatesByMap(states.map(manager.converter.mapStateToData).toList());
         manager._recordStatesByUiStates();
      }
      return json;
   }

   ST beforeSaveState(ST state) {
   
   }
}



abstract class BaseStateMatcher<ST>{
   bool undoMatcher(ST state) =>
      throw Exception('NotImplemented yet');
   
   bool redoMatcher(ST state) =>
      throw Exception('NotImplemented yet');
   
   bool mergeMatcher(ST state) => false;
   
   bool delMatcher(ST state) => false;
   
   bool discardMatcher(ST state) => false;
   
   bool uploadMatcher(ST state) =>
      throw Exception('NotImplemented yet');
   
   int idGetter(ST state) =>
      throw Exception('NotImplemented yet');
   
   void idSetter(ST state, int id) =>
      throw Exception('NotImplemented yet');
   
   void clearId(ST state){
      throw Exception('NotImplemented yet');
   }
}



abstract class BaseStateConverter<ST>{
   BaseStateConverter(this.manager);
   
   BaseStatesManager<ST> manager;
   
   Map<String, dynamic> mapStateToData(ST state, {bool considerValidation = false}) {
      throw Exception('NotImplemented yet');
   }

   /// called while loading json into staes
   ST mapDataToState(Map<String, dynamic> data) {
      throw Exception('NotImplemented yet');
   }

   List<ST> unsavedRefsToStates() {
      final result = <ST>[];
      manager.unsaved_states.forEach((id, subid) {
         result.add(manager.states[id][subid]);
      });
      return result;
   }

   Iterable<ST> refsToValue(List<List<int>> refs) {
      return refs.map((ref) {
         final id = ref[0];
         final subid = ref[1];
         final state = manager.states[id][subid];
         if (manager.inferred_ids.contains(id)) {
            manager.matcher.idSetter(state, id);
         }
         return state;
      });
   }
}

class BaseStateProgress {
   Timer loadingTimer;
   int bytesloaded = -1;
   int bytestotal = -1;
   BgProc _processing;
   
   int get progress => max(min((100 * bytesloaded / bytestotal).floor(), 100), 0);

   BgProc get processing => _processing;

    set processing(BgProc v) {
      _processing = v;
      switch (v) {
         case BgProc.onPrompt:
         case BgProc.onIdle:
            bytesloaded = bytestotal = -1;
            break;
         case BgProc.onUpload:
         case BgProc.onLoad:
         case BgProc.onSave:
            bytesloaded = bytestotal = -1;
            break;
         
      }
   }
}



class BaseStatesManager<ST>  {
   BaseStatesManager(this.converter, this.matcher, this.progressor){
         states = {};
         states_forUi = {};
         unsaved_states = {};
         del_states = [];
         merge_states = [];
   }
   BaseStateConverter<ST> converter;
   BaseStateMatcher<ST> matcher;
   BaseStateProgress progressor;
   
   BaseStoreService<ST> store;
   BaseGetService<ST> get;
   BasePostService<ST> post;
   BaseMessageService msg;
   HistoryService<ST> remember;
   
   StoreInf Function(String path) file;
   ConfigInf config;
   
   String state_message;
   String ident;
   
   int pagenumber;
   int current_id;
   int current_subid;
   
   Map<int, List<ST>> states; // cleared after 1) uploading 2) history eliminated
   Map<int, List<ST>> states_forUi; // cleared after 1) uploading 2) history changed
   Map<int, int>      unsaved_states; // cleared after 1) uploading 2) history changed
   List<List<ST>>     merge_states;
   List<ST> del_states;
   Set<int> inferred_ids = Set.from([]);
   Set<int> cleared_ids  = Set.from([]);
   Timer get loadingTimer => progressor.loadingTimer;
   int   get bytesloaded  => progressor.bytesloaded;
   int   get bytestotal   => progressor.bytestotal;
   int   get progress     => progressor.progress;
   BgProc get processing  => progressor.processing;

   set loadingTimer(Timer t)  => progressor.loadingTimer = t;
   set bytesloaded(int v)     => progressor.bytesloaded  = v;
   set bytestotal(int v)      => progressor.bytestotal   = v;
   set processing(BgProc v)   => progressor.processing   = v;
   
   void addGetService(BaseGetService<ST> get){
      this.get = get;
      assert(get.get_request_path != null);
   }
   void addMsgService(BaseMessageService<ST> msg){
      this.msg = msg;
      assert(msg.manager != null);
      assert(msg.bloC != null);
   }
   void addPostService(BasePostService<ST> post){
      this.post = post;
      assert(post.validator != null);
      assert(post.manager != null);
      assert(post.msgbloC != null);
      assert(post.post_request_path != null);
   }
   
   /*
   
   
      P R O C E S S I N G    U N S A V E D     S T A T E S
   
   
   */
   List<ST> unsavedRefsToStates() {
      final result = <ST>[];
      unsaved_states.forEach((id, subid) {
         result.add(states[id][subid]);
      });
      return result;
   }

   bool get hasUnsavedFile => store.hasUnsavedFile;
   bool get hasSavedLocalFile => store.hasSavedLocalFile;
   
   Future loadLastUnsavedStatesAndMergeIntoUi([List<Map<String,dynamic>> content]) async {
      try {
         if(store == null)
            throw Exception('uncuahgt exception');
         if (hasUnsavedFile) {
            final content = List<Map<String, dynamic>>.from(
               // load from "unsaved" local path
               jsonDecode( await file(store.unsavedpath).readAsync() ) as List);
            inferred_ids = Set.from(content.last['inferred_ids'] as List);
            final unsaved_states = content.take(content.length - 1).toList();
            _renewUiStatesByMap(unsaved_states);
            _recordStatesByUiStates();
         }
      } catch (e) {
         throw Exception('loadLastUnsavedStatesAndMergeIntoUi failed: \n${StackTrace.fromString(e.toString())}');
      }
   }

   List<Map<String,dynamic>> _processLastSavedStates(List<Map<String,dynamic>> content) {
      
      inferred_ids = Set.from(content.last['inferred_ids'] as List ?? []); // incase no inferred_ids written???
      return content.take(content.length - 1).toList() ?? [];
   }
   Future<List<Map<String, dynamic>>>
   loadLastSavedStates([List<Map<String,dynamic>> content]) async {
      try{
         if(store == null)
            throw Exception('uncuahgt exception');
         if (hasSavedLocalFile) {
            content ??= List<Map<String, dynamic>>.from(
               //load from localpath
                jsonDecode( await file(store.localpath).readAsync()) as List);
            return _processLastSavedStates(content);
         }
         return null;
      }catch(e){
         throw Exception('loadLastSavedStates failed: ${StackTrace.fromString(e.toString())}');
      }
   }


   void loadLastSavedStatesAndMergeIntoUiSync({List<Map<String,dynamic>> saved_states, EAnswer answer = EAnswer.black, bool byCache = false}) async {
      try{
         print('loadLastSavedStatesAndMergeIntoUiSync: ${saved_states?.map((s) => s['id'])}');
         if (answer == EAnswer.black){
            // load saved states and replace current one, discard all current states whether conflict or not;
         } else if (answer == EAnswer.white){
            // load saved states and merge into current one, keep all current states if conflict.
            processConflictContent<Map<String,dynamic>>(saved_states, (content, conflict){
               return conflict;
            });
         } else if (answer == EAnswer.grey){
            // load saved states and merge into current one, discard all current states if conflict.
            processConflictContent<Map<String,dynamic>>(saved_states, (content, conflict){
               return content;
            });
         } else{
            throw Exception('Invalid option: $answer');
         }

         if(saved_states != null){
            _renewUiStatesByMap(saved_states);
            _recordStatesByUiStates();
         }
      }catch(e){
         throw Exception('loadLastSavedStatesAndMergeIntoUiSync failed \n${StackTrace.fromString(e.toString())}');
      }
   }

   Future loadLastSavedStatesAndMergeIntoUi({List<Map<String,dynamic>> content, EAnswer answer = EAnswer.black, bool byCache = false}) async {
      try{
         final saved_states = !byCache
             ? await loadLastSavedStates(content)
             : _processLastSavedStates(content);
         print('saved_states: $saved_states');
         loadLastSavedStatesAndMergeIntoUiSync(saved_states: saved_states, answer: answer, byCache: byCache);
      }catch (e){
         throw Exception('LoadLastSavedStatesAndMergeIntoUi failed!, byCache:$byCache \n${StackTrace.fromString(e.toString())}');
      }
   }

   /*Future<String> loadLastSavedStatesAndMergeIntoUi({List<Map<String,dynamic>> content, EAnswer answer = EAnswer.black}) async {
      if(store == null)
         throw Exception('uncuahgt exception');
      try{
         if (hasSavedLocalFile) {
            content ??= List<Map<String, dynamic>>.from(
                jsonDecode( await file(store.unsavedpath).readAsync() ) as List);
            inferred_ids = Set.from(content.last['inferred_ids'] as List);
            final saved_states =  content.take(content.length - 1).toList();
            _renewUiStatesByMap(saved_states);
            _recordStatesByUiStates();
            return null;
         }
         return "File Parsing Error";
      } catch (e){
         raise(StackTrace.fromString(e.toString()));
         return "Uncaught Exception";
      }

   }*/

   List<E> processConflictContent<E extends Map<String,dynamic>>
      (List<E> savedContent, E onConflict(E content, E conflict))    {
      try{
         if (savedContent == null)
            return null;
         print("[processConflictContent]");
         final currentContent = List<E>.from(states_forUi.values.map((v) => converter.mapStateToData(v.last)));
         print('currentContent: $currentContent');
         for (var i = 0; i < savedContent.length; ++i) {
            final c = savedContent[i];
            print('i:$i, savedContent:$c');
            final conflict_state = currentContent.firstWhere((v) => v['id'] == c['id'], orElse: () => null);
            print('conflict_state: $conflict_state');
            if (conflict_state != null){
               currentContent.remove(conflict_state);
               savedContent[i] = onConflict(c, conflict_state);
            }else{

            }
         }
         savedContent.addAll(currentContent);
         return savedContent;
      }catch(e){
         throw Exception('processConflictContent failed\n${StackTrace.fromString(e.toString())}');
      }
   }
   

   
   bool hasOverridingIds(List<Map<String, dynamic>> data) {
      return data.any((rec) {
         final isNewUpload = inferred_ids.contains(rec['id']);
         return !isNewUpload;
      });
   }
   /*
   *           store
   *
   * */
   /*StoreInf file(String path){
      return throw Exception("Store not implemented yet");
   }*/
   
   Future<StoreInf> dumpToDisk({bool unsaved = true, String path}) async {
      if (store == null)
         throw Exception('uncuahgt exception');
      return await store.dump(unsaved: unsaved, path: path);
   }
   /*
   *
   *           post
   */
   bool isValidationResponse(Dio.Response res) {
      if (post == null)
         throw Exception('uncuahgt exception');
      return post?.validator?.isValidationResponse(res);
   }

   bool isSyncConflictResponse(Dio.Response res){
      if (res.data is Map<String, dynamic>){
         final body = res.data as Map<String, dynamic>;
         return body != null
                && res.statusCode == 409
                && body.containsKey('conflict')
                && body.containsKey('success');
      }
      return false;
   }

   Future<Dio.Response> uploadToServer({bool safety = false}) async {
      if (post == null)
         throw Exception('uncuahgt exception');
      return await post.uploadToServer(safety: safety);
   }
   /*
   *
   *           get
   * */
   Future<dynamic> renewInitialData() async {
      if (get == null)
         throw Exception('uncuahgt exception');
      return (await get.renew()).data;
   }
   dynamic getInitailData() {
      if (get == null)
         throw Exception('uncuahgt exception');
      return get.initialData;
   }
   Future<dynamic> fetchInitialData() async {
      if (get == null)
         throw Exception('uncuahgt exception');
      dynamic body;
      if (get.initialData != null){
         final data = get.initialData;
         if (data is Map){
            if (data.isNotEmpty)  return data;
         }else if (data is List){
            if (data.isNotEmpty)  return data;
         }
      }
      
      body = await store.load();
      
      // return nothing....
      try {
         Dio.Response response;
         if (body == null) {
            response = await get.fetch();
            return response.data;
            
         } else {
            get.initialData = body;
            response = await get.fetch();
            return response.data;
         }
      } catch (e) {
         //raise('fetchInitialData failed: \n${StackTrace.fromString(e.toString())}');
         throw Exception('fetchInitialData failed: \n${StackTrace.fromString(e.toString())}');
      }
   }

   

   //incompleted:
   Future<Dio.Response> receiveUserInqueryUploadOperation(Future<Dio.Response> request()) {
      if(msg == null)
         throw Exception('uncuahgt exception');
      return msg.receiveUserInqueryUploadOperation(request);
   }

   //incompleted:
   void receiveUserInqueryUndoableOperation() {
      if(msg == null)
         throw Exception('uncuahgt exception');
      msg.receiveUserInqueryUndoableOperation();
   }


   Iterable<ST> refsToValue(List<List<int>> refs) {
      return refs.map((ref) {
         final id = ref[0];
         final subid = ref[1];
         final state = states[id][subid];
         if (inferred_ids.contains(id)) {
            matcher.idSetter(state, id);
         }
         return state;
      });
   }
   /*
   *
   *        history
   *
   * */
   Map<String, dynamic> undo() {
      if (remember == null)
         return null;
      return remember.undo();
   }

   Map<String, dynamic> redo() {
      if (remember == null)
         return null;
      return remember.redo();
   }
   void clearStatesByFlag(int flag) {
      if (remember == null)
         return null;
      remember.clearStatesByFlag(flag);
   }

   ST saveHistory({bool undoable = true}) {
      if (remember == null)
         return null;
      return remember?.saveHistory(undoable: undoable);
   }
   /*
   
         I D    I N F E R R A N C E
   
   */
   void clearInferredIdsInStates() {
      inferred_ids.forEach((id) {
         print("[service] clearid: $id");
         states[id].forEach(matcher.clearId);
//         cleared_ids.add(id);
      });
   }

   int inferId(int id, [ST state]) {
      final keys = states.keys.toList();
      if (keys.length == 0) {
         id ??= 100000;
      } else {
         keys.sort((a, b) => b - a);
         id ??= ((keys.first ?? 0) + 100000);
      }
      inferred_ids.add(id);
      return id;
   }

   /*
   
   
         S T A T E    R E C O R D E R
   
   
   */
   void _appendUiStatesIntoIntialData() {
      if (get == null)
         return;
      final data = List<Map<String, dynamic>>.from(get.initialData as List ?? []);
      states_forUi.forEach((id, list) {
         if (!data.any((rec) => (rec['id'] as int) == id)) {
            data.add(converter.mapStateToData(list.last));
         }
      });
      get.initialData = data;
   }
   void _recordStatesByUiStates() {
      try{
         for (var k in states_forUi.keys) {
            final v = states_forUi[k].last;
            states[k] ??= [];
            states[k].add(v);
         }
      }catch(e){
         throw Exception('_recordStatesByUiStates failed\n${StackTrace.fromString(e.toString())}');
      }
   }

   void _renewUiStatesByMap(List<Map<String, dynamic>> data) {
      try{
         if (data == null)
            return;
         states_forUi = {};
         for (var i = 0; i < data.length; ++i) {
            final rec = data[i];
            final state = converter.mapDataToState(rec);
            final state_id = matcher.idGetter(state);
            states_forUi[state_id] = [state];
         }
      }catch(e){
         throw Exception('renewUiStatesByMap failed\n${StackTrace.fromString(e.toString())}');
      }
   }
   
   void addUnsavedState(int id, int subid) {
      unsaved_states[id] = subid;
   }

   void clearInferredIdByState(ST state){
      final del_id = matcher.idGetter(state);
      if (states_forUi.containsKey(del_id)) {
         inferred_ids.remove(del_id);
         states_forUi.remove(del_id);
      } else {
         throw Exception('Uncaught Exception, cannot found deleted id on ui side');
      }
   }
   bool _delStateOnLoadedState(ST del_state) {
      clearInferredIdByState(del_state);
      del_states.add(del_state);
      return true;
   }

   bool _delStateOnServer(ST del_state) {
      final data = List<Map<String, dynamic>>.from(get.initialData as List);
      final matched = data.firstWhere(
            (d) => d['id'] == matcher.idGetter(del_state), orElse: () => null);
      if (matched != null) {
         del_states.add(converter.mapDataToState(matched));
         data.remove(matched);
         return true;
      }
      return false;
   }

   void delState(ST del_state) {
      // fixme: all states must be loaded before deleted, hence _delStateOnServer
      //        seeams never executed.
      if (!_delStateOnLoadedState(del_state))
         _delStateOnServer(del_state);
   }

   void mergeState(ST master_state, ST slave_state) {
      assert(master_state != null);
      assert(slave_state != null);
      final master_id = matcher.idGetter(master_state);
      final slave_id = matcher.idGetter(slave_state);
      if (states_forUi.containsKey(slave_id)) {
         inferred_ids.remove(slave_id);
         states_forUi.remove(slave_id);
         merge_states.add([master_state, slave_state]);
      } else {
         throw Exception('Uncaught Exception, cannot found merged state on ui side');
      }
   }

   ST saveState(ST state, int id, {bool addToUnsaved = false, ST slave}) {
      if (id == null) {
         if (matcher.undoMatcher(state)) {
            undo();
         } else if (matcher.redoMatcher(state)) {
            redo();
         } else if (matcher.uploadMatcher(state)) {
            //saveHistory();
         }
         return state;
      }
      if (matcher.delMatcher(state)) {
         delState(state);
      } else if (matcher.mergeMatcher(state) || slave != null) {
         mergeState(state, slave);
      } else if (id != null) {
         if (matcher.discardMatcher(state)){
            clearInferredIdByState(state);
            //del_states.add(state);
         }else{
            states[id] ??= [];
            states[id].add(state);
            states_forUi[id] = [state];
         }
         if (addToUnsaved)
            addUnsavedState(id, states[id].length - 1);
      }
      saveHistory();
      return state;
   }
}


class _Cache implements CacheSketch{
   @override DateTime time;
   @override Dio.Response value;
   
   bool get outdated =>
      time == null || DateTime.now().toUtc().difference(time).inMinutes > 5;
   
   void set(Dio.Response v) {
      if (outdated) {
         value = v;
         time = DateTime.now().toUtc();
      }
   }

   Dio.Response get() {
      if (outdated)
         return null;
      return value;
   }
   
   
}

class QueryCache implements QCacheSketch{
   @override Map<String, CacheSketch> cache = {};

   Dio.Response get(String key) {
      if (cache.containsKey(key))
         return cache[key].get();
      return null;
   }
   
   void set(String key, Dio.Response value) {
      if (cache.containsKey(key))
         return cache[key].set(value);
      cache[key] = _Cache()
         ..set(value);
   }
   
   void clearKeysContains(String key) {
      final keys = cache.keys.toList();
      keys.forEach((k) {
         if (key.contains(key))
            cache.remove(k);
      });
   }
   Map<String,dynamic> asMap(bool matcher(String key)){
      final result = <String,dynamic>{};
      cache.forEach((k, _cache){
         final value = _cache.value;
         if (matcher(k)){
            result[k] = value.data;
         }
         /*if (value.data is List){
            result[k] = value.data;
         }else if (value.data is Map){
            result[k] = value.data;
         }else if (value.data is String){
            result[k] = value.data;
         } else if (value.data == null){
            result[k] = value.data;
         }else{
            throw Exception("uncaught exception on Cache");
         }*/
      });
      return result;
   }
}





// todo:
// don't use dio package
class Http implements HttpSketch {
   static Http instance;
   static String host;
   static int port;
   static Map<String, dynamic> headers;
   static QueryCache cache = QueryCache();


   Logger _log;
   String path;
   @override Uri request_uri;
   @override Map<String, String> query;
   @override String get base_url => '$host:$port';
   
   Dio.Dio dio;
   
   
   Http._({String host, int port, bool dumplog, String logpath = "log.log"}) {
      instance = this;
      Http.host = host;
      Http.port = port;
      if (dumplog) {
         _log = Logger(
            name: "Http",
            stream_path: logpath,
            levels: [
               ELevel.info, ELevel.error, ELevel.debug
            ]
         );
      }
      // or new Dio with a Options instance.
      Dio.BaseOptions options = Dio.BaseOptions(
         baseUrl: "http://${host}:${port}",
         connectTimeout: 5000,
         receiveTimeout: 3000,
      );
      
      dio = Dio.Dio()
         ..options = options;
   }
   
   Http.newInstance();
   
   factory Http({String host, int port, bool dumplog = true, String logpath = "log.log"}){
      if (instance != null)
         return instance;
      return Http._(host: host, port: port, dumplog: dumplog, logpath: logpath);
   }
   
   void log(String m, [ELevel level = ELevel.info]) => _log?.call(m, level, false);
   
   
   Map<String, String> toJsonObj(Map<String, dynamic> query) {
      if (query == null) return null;
      final ret = <String, String>{};
      query.forEach((key, val) {
         ret[key] = val.toString();
      });
      return ret;
   }
   
   String refinePath(String path) {
      if (path == null)
         throw Exception('path should not be null');
      while (path.startsWith("/")) {
         path = path.substring(1);
      }
      return path;
   }



   @override Future<bool>
   testNetwork() async {
      final completer = Completer<bool>();
      try {
         final result = await InternetAddress.lookup('google.com');
         if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            completer.complete(true);
         }
      } on SocketException catch (_) {
         completer.complete(false);
      }
      return completer.future;
   }

   @override Future<Response>
   get(String pth, {Map<String, String> headers, Map<String, dynamic> qparam, String contentType}) async {
      if (_onHttp()){
         try{
            path = refinePath(pth);
            query = toJsonObj(qparam);
            request_uri = Uri.http("${host}:${port}", path, query);

            headers ??= {};
            headers[HttpHeaders.contentTypeHeader] ??= contentType ?? ContentTypes.json;
            headers[HttpHeaders.contentEncodingHeader] ??= 'utf8';

            final result = await http.get(request_uri, headers: headers);
            if (result.statusCode >= 500){
               _onFailed(result.statusCode);
            }
            return result;
         }catch(e){
            throw Exception(StackTrace.fromString(e.toString()));
         }
      }
   }
   
   @override Future<Response>
   post(String pth, {Map<String, String> headers, dynamic body, String contentType}) async {
      if (_onHttp()){
         try{
            headers ??= Http?.headers?.map((k, v) => MapEntry(k, v.toString()));
            path = refinePath(pth);
            request_uri = Uri.http("${host}:${port}", path);

            //      headers[HttpHeaders.contentTypeHeader] ??= contentType?.value ?? ContentTypes.json.value;
            final bd = body is Map<String,dynamic>
                ? toJsonObj(body)
                : body;
            final result =  await http.post(request_uri, headers: headers, body: bd);
            if (result.statusCode >= 500){
               _onFailed(result.statusCode);
            }
            return result;
         }catch(e){
            throw Exception(StackTrace.fromString(e.toString()));
         }
      }
   }
   
   Future<StreamedResponse> multiRequest(String pth, {MultipartForm body}) async {
      path = refinePath(pth);
      final base_uri = Uri.http("${host}:${port}", path);
      final request = MultipartRequest("POST", base_uri);
      request.fields.addAll(body.fields);
      //request.files.addAll(body.files);
      final ret = await request.send();
      return ret;
   }
   
   Future<Dio.Response> dioMultiPost(String pth, {
      Map<String, String> headers,     Map<String, dynamic> data,
      onReceive(int send, int total),  TwoDBytes binary_data,
      int progressSteps = 75,          String contentType,     onSend(int send, int total)}) async {
      try {
         if (_onHttp()){
            final path = refinePath(pth);
            request_uri = Uri.http("${host}:${port}", path);
            headers ??= {};
      
            if (binary_data == null) {
               final formData = Dio.FormData.from(data);
               final response = await dio.post(
                   request_uri.toString(),
                   data: formData,
                   options: Dio.Options(headers: headers),
                   onSendProgress: onSend
               );
               return response;
            }
      
            var send_ct = 0;
            var receive_ct = 0;
            final percent = (binary_data.length / progressSteps).floor();
            final newOnSend = (int send, int total) {
               send_ct ++;
               if (send_ct % percent == 0)
                  onSend(send, total);
            };
            final newOnReceive = (int send, int total) {
               receive_ct ++;
               if (receive_ct % percent == 0)
                  onReceive(send, total);
            };
      
            headers[HttpHeaders.contentTypeHeader] = "application/binary_json";
            headers[HttpHeaders.contentEncodingHeader] ??= 'utf8';
            // for onSend to be work on sending stream data
            // contentLength must be set.
            headers[HttpHeaders.contentLengthHeader] ??= binary_data.length.toString();

            print('multiPost: ${request_uri.toString()}');
            final response = await dio.post(
                request_uri.toString(),
                options: Dio.Options(headers: headers),
                data: Stream.fromIterable(binary_data.bytes.map((e) => [e])),
                onSendProgress: newOnSend,
                onReceiveProgress: newOnReceive
            );
            return response;
         }
      } on Dio.DioError catch (e) {
         _onFailed(e.response?.statusCode ?? 500);
         if (e.response != null){
            return e.response;
         }else{
            final error = e.toString();
            if (error.contains("No route to host")){
            
            } else if (error.contains("Connection failed")){
            
            } else if (error.contains("CONNECT_TIMEOUT")){
            
            }
            throw Exception(
              '\n[ERROR] occurs while sending MultiPost request'
              '\nstatus     : ${e.response?.statusCode}'
              '\nrequest url: ${request_uri.toString()}'
              '\n${StackTrace.fromString(e.toString())}'
            );
         }
      } catch (e){
         throw Exception('Uncuahg Exception while sending request\n${StackTrace.fromString(e.toString())}');
      }
   }
   
   @override Future<Dio.Response>
   dioGet(String pth, {Map<String, String> headers, Map<String, dynamic> qparam,
                       String contentType, bool isCached = false}) async {
      if (_onHttp()){
         try {
            final path = refinePath(pth);
            request_uri = Uri.http("${host}:${port}", path);
            query = toJsonObj(qparam);
            final key = '${request_uri.toString()} $query';
            if (isCached && cache.get(key) != null)
               return cache.get(key);

            final response = await dio.get(request_uri.toString(),
                queryParameters: qparam,
                options: Dio.Options(headers: headers));
            
            /*if (isCached && response.statusCode == 200)
               cache.set(key, response);*/
            if (response.statusCode == 200)
               cache.set(key, response);
            
            return response;
         } on Dio.DioError catch (e) {
            _onFailed(e.response?.statusCode ?? 500);
            if (e.response != null){
               return e.response;
            }else{
               final error = e.toString();
               if (error.contains("No route to host")){
               
               } else if (error.contains("Connection failed")){
      
               } else if (error.contains("Timeout")){
      
               }
               
               throw Exception(
                   '\nError occurs while sending GET request'
                       '\nstatus     : ${e.response?.statusCode}'
                       '\nrequest url: ${request_uri.toString()}'
                       '\nquery      : ${FN.stringPrettier(qparam)}'
                       '\nheaders    : ${FN.stringPrettier(headers)}'
                       '\n${StackTrace.fromString(e.toString())}'
               );
            }
         } catch (e){
            throw Exception('Uncuahg Exception while fetching request\n${StackTrace.fromString(e.toString())}');
         }
      }else{
         return Dio.Response(statusCode: 503);
      }
   }
   
   
   @override Future<Dio.Response>
   dioPost(String pth, {Map<String, String> headers, dynamic body, String contentType, Map<String, dynamic> qparam}) async {
      if (_onHttp()){
         try {
            path = refinePath(pth);
            request_uri = Uri.http("${host}:${port}", path);
            headers ??= {};
            headers[HttpHeaders.contentTypeHeader] ??= contentType ?? ContentTypes.json;
            headers[HttpHeaders.contentEncodingHeader] ??= 'utf8';
            return await dio.post(
               request_uri.toString(),
               options: Dio.Options(headers: headers),
               queryParameters: qparam,
               data: body,
            );
         } on Dio.DioError catch (e) {
            _onFailed(e.response?.statusCode ?? 500);
            if (e.response != null) {
               return e.response;
            } else {
               throw Exception(
                   '\nError occurs while sending POST request'
                    '\nrequest url: ${request_uri.toString()}'
                    '\npost body: \n${FN.stringPrettier(body)}'
                    '\n${StackTrace.fromString(e.toString())}'
               );
            }
         } catch (e){
            throw Exception('uncaught exception while posting request\n${StackTrace.fromString(e.toString())}');
         }
      }
   }
   
   Future<Dio.Response>
   dioDelete(String pth, {Map<String, String> headers, Map<String, dynamic> body, String contentType}) async {
      if (_onHttp()){
         path = refinePath(pth);
         request_uri = Uri.http("${host}:${port}", path);
         headers ??= {};
         headers[HttpHeaders.contentTypeHeader] ??= contentType ?? ContentTypes.json;
         headers[HttpHeaders.contentEncodingHeader] ??= 'utf8';

         try {
            return await dio.delete(
                request_uri.toString(),
                options: Dio.Options(headers: headers),
                data: body
            );
         } on Dio.DioError catch (e) {
            _onFailed(e.response?.statusCode ?? 500);
            if (e.response != null) {
               return e.response;
            } else {
               throw Exception(
                   '\nError occurs while sending DELETE request'
                       '\nrequest url: ${request_uri.toString()}'
                       '\npost body: \n${FN.stringPrettier(body)}'
                       '\n${StackTrace.fromString(e.toString())}'
               );
            }
         }
      }
   }
   //todo: test
   @override void Function(int c)_onFailed      = (c)=> null;
   @override void Function(int c)_onServerError = (c) => null;
   @override void Function()     _onSuccess   = () => null;
   @override bool Function()     _onHttp      = () => true;
   @override void Function()_onNetAvailable   = () => null;
   @override void Function()_onNetUnavailable = () => null;

   @override
   void onFailed(void Function(int statuscode) cb) async {
      _onFailed = (int statuscode) async {
         print('_onFailed: $statuscode');
         cb(statuscode);
         if (statuscode >= 500){
            if (await testNetwork()){
               if (!AppState.offlineMode){
                  _onServerError(statuscode);
               }else{
                  _onNetAvailable();
               }
            }else{
               if (!AppState.offlineMode){
                  _onNetUnavailable();
               }else{
               }
            }
         }
      };
   }

   @override
   void onHttp(bool Function() cb) {
      _onHttp = (){
         final result = cb();
         if (result){
         }else{
            _onNetUnavailable();
         }
         return result;
      };
   }

   @override
   void onSuccess(void Function() cb) {
      _onSuccess = (){
         cb();
      };
   }

   @override
   void onServerError(void Function(int c) cb) {
      _onServerError = (c){
         cb(c);
      };
   }

   @override
   void onNetworkAvailable(void Function() cb) {
      _onNetAvailable = () {
         print('network available');
//         AppState.offlineMode = false;
         AppState.bloC.onOnlineMode("network available");
         cb();
      };
   }

   @override
   void onNetworkUnavailable(void Function() cb) {
      _onNetUnavailable = () {
         print('network unavailable');
//         AppState.offlineMode = true;
         AppState.bloC.onOfflineMode("network unavailable");
         cb();
         testNetwork().then((e){
            if (e){
               print('test network available');
               _onNetAvailable();
            }
         });
      };
   }
}





