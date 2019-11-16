import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bsdiff/bsdiff.dart';
import 'package:common/common.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/mediators/di.dart';
import 'package:nxp_bloc/mediators/models/model_error.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';


class Stack<T> {
   List<T> data;
   int length;
   
   T get last => data.last;
   
   T get first => data.first;
   
   Stack(this.length) {
      data = List<T>(length);
   }
   
   void shift(int d) {
      if (d < 0) {
         final List<T> subset = data.sublist(-d, data.length).toList();
         data = subset + List<T>.generate(-d, (d) => null);
      } else if (d > 0) {
         final List<T> subset = data.sublist(0, data.length - d).toList();
         data = List<T>.generate(d, (d) => null) + subset;
      }
   }
   
   void add(T element) {
      /*for (var i = 0; i < length - 1; ++i) {
         data[i] = data[i + 1];
      }
      data[length - 1] = element;*/
      shift(-1);
      data[length - 1] = element;
   }
   
   T operator [](int index) {
      return data[index];
   }
   
   operator []=(int index, T value) {
      data[index] = value;
   }
}



class HistoryRecord<E> {
   //@fmt:off
   Uint8List        origin;
   Stack<Uint8List> _stack;
   int flag;
   int length;
   // --------------------------------------
   Stack<Uint8List>     get stack => _stack;
   E get first => this[0];
   E get last  => this[length -1];
   E get current => this[flag];
   //@fmt:on

   HistoryRecord([this.length = 12]) {
      _stack = Stack<Uint8List>(length);
      flag = length - 1;
   }

   List<int> encode(E data) {
      return jsonEncode(data).codeUnits;
   }

   E decode(List<int> encoded_data) {
      final string = String.fromCharCodes(encoded_data);
      return jsonDecode(string) as E;
   }

   Uint8List toBinary(E data) {
      return Uint8List.fromList(encode(data));
   }

   Uint8List genPatch(E data) {
      if (data == null) return null;
      final modified = toBinary(data);
      return bsdiff(origin, modified);
   }

   E genRestore(Uint8List patch) {
      if (patch == null) return null;
      final binary = bspatch(origin, patch);
      return decode(binary);
   }

   E transformRef(List<int> data) {
      throw Exception('NotImplemented');
   }

   bool isLastPosition(int p) => p == length - 1;

   void afterAdd(int prev_flag) {
   
   }

   void addRef(List<int> data) {
      final _flag = flag;
      if (_stack.last == null && origin == null) {
         origin = Uint8List.fromList(data);
      } else {
         _stack.shift((length - 1) - flag);
         flag = length - 1;
         _stack.add(genPatch(transformRef(data)));
      }
      afterAdd(_flag);
   }

   E beforeAdd(E data) {
      return data;
   }

   void add(E data) {
      final _flag = flag;
      final _data = beforeAdd(data);
      if (_stack.last == null && origin == null) {
         origin = toBinary(_data);
      } else {
         _stack.shift((length - 1) - flag);
         flag = length - 1;
         _stack.add(genPatch(_data));
      }
      afterAdd(_flag);
   }

   E undo() {
      flag = max(flag - 1, 0);
      if (_stack.data[flag] == null){
         flag = max(flag + 1, 0);
         return null;
      }
      
      return genRestore(_stack[flag]);
   }

   E redo() {
      flag = min(flag + 1, length - 1);
      if (_stack.data[flag] == null){
         flag = min(flag - 1, length - 1);
         return null;
      }
      return genRestore(_stack[flag]);
   }

   E operator [](int index) {
      final binary = _stack[index];
      if (binary == null)
         return null;
      return genRestore(binary);
   }

   operator []=(int index, E value) {
      if (value == null)
         return;
      final binary = genPatch(value);
      _stack[index] = binary;
   }
}


class JsonHistory<E extends Map<String, dynamic>> extends HistoryRecord <E> {
   int length;
   String codec;
   JsonHistory(this.length, {this.codec = 'ascii'});
   
   @override List<int> encode(E data) {
      if (codec == 'ascii')
         return jsonEncode(data).codeUnits;
      else if (codec == 'utf8')
         return utf8.encode(jsonEncode(data));
      else
         throw Exception('unrecognized codec: $codec');
   }
   
   @override E decode(List<int> encoded_data) {
      if (codec == 'ascii'){
         final string = String.fromCharCodes(encoded_data);
         return jsonDecode(string) as E;
   
      }else if (codec == 'utf8'){
         final data = utf8.decode(encoded_data);
         return jsonDecode(data) as E;
      }else{
         throw Exception('unrecognized codec: $codec');
      }
   }
}


class HistoryRegistry{
   Map<String, HistoryRecord> registry = {};
   int length;
   HistoryRegistry(this.length);
   
   void resetHistory(){
      registry = {};
   }
   void registerHistory<T extends HistoryRecord>(T type, String key){
      if (!registry.containsKey(key)){
         if (type.stack.length != length){
            throw Exception('history length missmatch, expect a history of length of $length');
         }
         registry[key] = type;
      }else
         raise('registry key:$key already registered in HistoryRegistry');
   }
   HistoryRecord guard(String key){
      final his = registry[key];
      if (his == null)
         throw Exception('Please register registry key: $key first before adding history');
      return his;
   }
   void add(data, String key){
      final his = guard(key);
      his?.add(data);
   }
   dynamic undo(String key){
      final his = guard(key);
      return his?.undo();
   }
   dynamic redo(String key){
      final his = guard(key);
      return his?.redo();
   }
   dynamic getCurrent(String key){
      final his = guard(key);
      return his.current;
   }
   dynamic getByFlag(String key, int flag){
      final his = guard(key);
      return his[flag];
   }
   
   
}

class RefHistory<E extends List<List<int>>> extends HistoryRecord <E> {
   int length;
   
   RefHistory(this.length);
   
   @override
   Uint8List genPatch(E data) {
      return super.genPatch(data);
   }
   
   @override
   E genRestore(Uint8List patch) {
      return super.genRestore(patch);
   }
   
   @override E transformRef(List<int> data) {
      throw Exception('NotImplemented');
   }
   
   @override List<int> encode(E data) {
      return jsonEncode(data).codeUnits;
   }
   
   @override E decode(List<int> encoded_data) {
      final string = String.fromCharCodes(encoded_data);
      return
         List<List<int>>.from(
            (jsonDecode(string) as List)
               .map<List<int>>((r) => List<int>.from(r as List))
         ) as E;
   }
}


class AccRefHistory<E extends List<List<int>>> extends RefHistory<E> {
   int length;
   
   AccRefHistory(this.length) : super(length);
   
   @override E beforeAdd(E data) {
      if (_stack.last == null && origin == null) {
         return data;
      } else {
         final List<List<int>> current_acc = this[flag] ?? decode(origin);
         final tobe_add = data;
         final List<List<int>> result = [];
         result.addAll(current_acc);
         for (var i = 0; i < tobe_add.length; ++i) {
            var trec = tobe_add[i];
            if (!current_acc.any((rec) => rec[0] == trec[0] && rec[1] == trec[1]))
               result.add(trec);
         }
         return result as E;
      }
   }
}



class BaseMainStateManager<ST> {
   static Map<String, dynamic> synctime;
   
   BgProc _processing;
   String state_message;
   String ident;
   Timer loadingTimer;
   int bytesloaded = -1;
   int bytestotal = -1;
   int pagenumber;
   int current_id;
   int current_subid;
   
   String localpath;
   String unsavedpath;
   String get_request_path;
   String post_request_path;
   String del_request_path;
   String merge_request_path;
   
   Set<int> inferred_ids = Set.from([]);
   
   Map<int, List<ST>> states; // cleared after 1) uploading 2) history eliminated
   Map<int, List<ST>> states_forUi; // cleared after 1) uploading 2) history changed
   Map<int, int> unsaved_states; // cleared after 1) uploading 2) history changed
   List<ST> del_states;
   List<List<ST>> merge_states;
   
   JsonHistory history;
   RefHistory stateHistory;
   RefHistory inferredHistory;
   AccRefHistory accumulatedStateHistory;
   MessageBloC msgbloC;
   
   StreamSubscription<MsgEvents> subscription;
   
   void Function(ST state) clearId;
   int Function(ST state) idGetter;
   void Function(ST state, int id) idSetter;
   
   dynamic _initialData;
   
   dynamic get initialData => _initialData;
   
   int get progress => max(min((100 * bytesloaded / bytestotal).floor(), 100), 0);
   
   BgProc get processing => _processing;
   
   void set processing(BgProc v) {
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
   
   /*
   
         E X T E R N A L     I M P L E M E N T S
   
   */
   
   void afterDump() {
   
   }
   
   Map<String, dynamic> mapStateToData(ST state, {bool considerValidation = false}) {
      throw Exception('NotImplemented yet');
   }
   
   /// called while loading json into staes
   ST mapDataToState(Map<String, dynamic> data) {
      throw Exception('NotImplemented yet');
   }
   
   /// called before uploading, for preparing uploading data
   List<Map<String, dynamic>> getUploadData() {
      throw Exception('NotImplemented yet');
   }
   
   dynamic updateInitialData() {
      throw Exception('updateInitialData not implemented yet');
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
   
   bool get hasUnsavedFile => File(unsavedpath).existsSync();
   
   void loadLastUnsavedStates() {
      if (hasUnsavedFile) {
         final unsaved = List<Map<String, dynamic>>.from(
            jsonDecode(File(unsavedpath).readAsStringSync()) as List);
         inferred_ids = Set.from(unsaved.last['inferred_ids'] as List);
         final unsaved_states = unsaved.take(unsaved.length - 1).toList();
         _renewUiStatesByMap(unsaved_states);
         _recordStatesByUiStates();
      }
   }
   
   void _recordStatesByUiStates() {
      for (var k in states_forUi.keys) {
         final v = states_forUi[k].last;
         states[k] ??= [];
         states[k].add(v);
      }
   }
   
   void _renewUiStatesByMap(List<Map<String, dynamic>> data) {
      states_forUi = {};
      for (var i = 0; i < data.length; ++i) {
         final rec = data[i];
         final state = mapDataToState(rec);
         final state_id = idGetter(state);
         states_forUi[state_id] = [state];
      }
   }
   
   /*
   
   
         F I L E    S A V I N G
   
   
   */
   
   Future<void> dumpToDisk() async {
      final states_tobe_dump = unsavedRefsToStates();
      final finaldata = beforeDump(states_tobe_dump, initialData);
      finaldata.add({
         'inferred_ids': inferred_ids.toList()
      });
      return File(unsavedpath).writeAsString(jsonEncode(finaldata)).then((file) {
         afterDump();
      });
   }
   
   List beforeDump(List<ST> states, dynamic json) {
      throw Exception('NotImplemented yet');
   }
   
   
   /*
   
   
            U P L O A D  - P O S T
   
   
   */
   
   
   bool hasOverridingIds(List<Map<String, dynamic>> data) {
      return data.any((rec) {
         final isNewUpload = inferred_ids.contains(rec['id']);
         return !isNewUpload;
      });
   }
   
   //untested:
   Future<Dio.Response> _delRequest() {
      final del_body = del_states.map(mapStateToData).toList();
      del_states = [];
      return Http().dioPost(del_request_path, body: del_body);
   }
   
   //untested:
   Future<Dio.Response> _mergeRequest() {
      final params = <String, dynamic>{
         'merged_data': <String, dynamic>{}
      };
      for (var i = 0; i < merge_states.length; ++i) {
         final list_states = merge_states[i];
         params['merged_data'][i.toString()] = [
            mapStateToData(list_states[0]),
            mapStateToData(list_states[1])
         ];
      }
      merge_states = [];
      return Http().dioPost(merge_request_path, body: params);
   }
   
   //untested:
   Future<Dio.Response> _uploadRequest(List<Map<String, dynamic>> body, bool isDbOverriden) async {
      Future<Dio.Response> del_request, merge_request, post_request;
      Future<List<Dio.Response>> final_request;
      if (del_states.isNotEmpty)
         del_request = _delRequest();
      if (merge_states.isNotEmpty)
         merge_request = _mergeRequest();
      
      post_request = Http().dioPost(post_request_path, body: body);
      
      if (del_request == null && merge_request == null) {
         final_request = Future.wait([post_request]);
      } else if (del_request == null) {
         final_request = Future.wait([merge_request, post_request]);
      } else if (merge_request == null) {
         final_request = Future.wait([del_request, post_request]);
      } else {
         final_request = Future.wait([del_request, merge_request, post_request]);
      }
      
      //fixme:
      return await final_request.then((List<Dio.Response> response) {
         /*final result = MultiResponse();
         response.forEach((r){
            if (r.statusCode < 300 && r.statusCode >= 200){
               (r.data as List).forEach((_rec){
                  final rec = _rec as Map<String,dynamic>;
                  
               });
            } else if (r.statusCode == 409){
            
            } else {
            
            }
         });*/
         onUploadSuccess(response.last, isDbOverriden);
         return response.last;
      });
   }
   
   void onUploadConflict() {
   
   }
   
   void onUploadFailed() {
   
   }
   
   void onUploadSuccess(Dio.Response response, bool isDbOverriden) {
      inferred_ids = Set.from([]);
      unsaved_states = {};
      
      ///
      /// clear all histories after
      ///      1) deleting operation on server
      ///      2) overriding operation on server
      ///   no matter which records on server are involved in current history.
      ///   this can be fixed in the future todo:
      ///
      _renewUiStatesByMap(
         List<Map<String, dynamic>>.from(response.data as List)
      );
      _recordStatesByUiStates();
      //todo: clear history while isDbOverriden
      /*stateHistory.flag = 0;
      _saveAndClearPrevHistory();*/
      _saveAndClearPrevHistory();
      _appendUiStatesIntoIntialData();
   }
   
   bool checkValidation() {
      var hasErrors = false;
      try {
         final data = List<Map<String, dynamic>>.from(initialData as List);
         states_forUi.forEach((k, v) {
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
   
   bool isValidationResponse(Dio.Response res) {
      final data = List<Map<String,dynamic>>.from(res.data as List);
      return data.any((rec) => rec.containsKey(ResponseConst.ERR_CONTAINER))
             && res.statusCode == 409;
   }

   Dio.Response genValidationResponse() {
      final body = <Map<String, dynamic>>[];
      states_forUi.forEach((k, v) {
         body.add(mapStateToData(v.last, considerValidation: true));
      });
      return Dio.Response(statusCode: 409, data: body);
   }
   
   Future<Dio.Response> uploadToServer({bool safety = false}) async {
      if (checkValidation()) {
         clearInferredIdsInStates();
         updateInitialData();
         final body = getUploadData();
         final isDbOverriden = hasOverridingIds(body);
         // todo:
         // 1) implementing history reset while isDbOverriden
         if (!safety) {
            return await _uploadRequest(body, isDbOverriden);
         } else {
            if (isDbOverriden) {
               // found overriding operation on server - reset history
               msgbloC.onUserInquiryUploadRequest();
               return await receiveUserInqueryUploadOperation(() {
                  return _uploadRequest(body, isDbOverriden);
               });
            } else {
               return await _uploadRequest(body, isDbOverriden);
            }
         }
      } else {
         return genValidationResponse();
      }
   }
   
   void _appendUiStatesIntoIntialData() {
      final data = List<Map<String, dynamic>>.from(_initialData as List);
      states_forUi.forEach((id, list) {
         if (!data.any((rec) => (rec['id'] as int) == id)) {
            data.add(mapStateToData(list.last));
         }
      });
      _initialData = data;
   }
   
   Future<dynamic> renewInitialData() async {
      _initialData = null;
      return await fetchInitialData();
   }
   
   /*
   
   
         L O A D  -  G E T   F R O M   U R L
         L O A D  -  F R O M D I S K
   
   
   */
   dynamic getInitailData() {
      return initialData;
   }
   
   dynamic fetchInitialDataFromDisk() {
      if(localpath == null)
         return null;
      if (!File(localpath).existsSync()) return null;
      final string = File(localpath).readAsStringSync();
      return jsonDecode(string);
   }
   
   Future<Dio.Response> fetchInitialDataFromDB({Map<String, dynamic> query}) async {
      if(get_request_path == null)
         return null;
      return await Http().dioGet(get_request_path, isCached: true, qparam: query);
   }
   
   /// try fetch initial data from disk
   ///   - if not found, fetch from database and save it to disk
   ///   - if found, prefetch initial data from disk then:
   ///      - fetch initial data from database
   Future<dynamic> fetchInitialData() async {
      Dio.Response response;
      dynamic body;
      if (initialData != null) return initialData;
      body = await fetchInitialDataFromDisk();
      
      return guard(() async {
         if (body == null) {
            response = await fetchInitialDataFromDB();
         } else {
            _initialData = body;
            response = await fetchInitialDataFromDB();
         }
         
         if (response.statusCode != 200) {
            msgbloC.onInferNetworkError(response.statusCode, null, null);
            return null;
         } else {
            File(localpath).writeAsStringSync(jsonEncode(response.data));
            return _initialData = response.data;
         }
      },
         'Errors occurs while fetching initialData',
         error: 'FetchInitialError',
         raiseOnly: false);
   }
   
   /*
   
         
            H I S T O R Y
   
   
   */
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
   
   /// clear states and states_forUi
   void clearStatesByFlag(int flag) {
      if (stateHistory.isLastPosition(flag))
         return;
      final available_states = accumulatedStateHistory[flag];
      final unavailable_subids = <int, List<int>>{};
      states.forEach((int k, List<ST> v) {
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
      });
      
      unavailable_subids.forEach((int k, List<int>ids) {
         ids.forEach((id) {
            states[k][id] = null;
         });
         if (states[k].every((state) => state == null)) {
            states.remove(k);
         } else {
            states[k] = states[k].where((state) => state != null).toList();
         }
      });
   }
   
   void _saveAndClearPrevHistory() {
      final statesSnapshot = <List<int>>[];
      final inferredSnapshot = <List<int>>[];
      beforeSaveStateHistory();
      if (stateHistory.flag == stateHistory.length - 1) {
         for (var key in states_forUi.keys) {
            final subkey = states[key].indexOf(states_forUi[key].last);
            statesSnapshot.add([key, subkey]);
         }
         inferredSnapshot.add(inferred_ids.toList());
         
         inferredHistory.add(inferredSnapshot);
         stateHistory.add(statesSnapshot);
         accumulatedStateHistory.add(statesSnapshot);
         fetchInitialData().then(saveJsonHistory);
         clearStatesByFlag(stateHistory.flag);
      } else {
         clearStatesByFlag(stateHistory.flag);
         for (var key in states_forUi.keys) {
            var subkey = states.containsKey(key)
                         ? states[key].indexOf(states_forUi[key].last)
                         : -1;
            if (subkey != -1) {
               statesSnapshot.add([key, subkey]);
            } else {
               states[key] ??= states_forUi[key];
               states[key][states[key].length - 1] = states_forUi[key].last;
               subkey = states[key].indexOf(states_forUi[key].last);
               statesSnapshot.add([key, subkey]);
            }
         }
         inferredSnapshot.add(inferred_ids.toList());
         
         inferredHistory.add(inferredSnapshot);
         stateHistory.add(statesSnapshot);
         accumulatedStateHistory.add(statesSnapshot);
         fetchInitialData().then(saveJsonHistory);
      }
   }
   
   ST saveHistory({bool undoable = true}) {
      if (undoable == false) {
         msgbloC.onUserInquiryNonUndoableRequest();
         receiveUserInqueryUndoableOperation();
      } else {
         _saveAndClearPrevHistory();
      }
   }
   
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
            stateHistory.flag = 0;
            _saveAndClearPrevHistory();
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
            stateHistory.flag = 0;
            _saveAndClearPrevHistory();
            return;
         }
      );
   }
   
   Future<E> _receiveUserInqueryOnece<E>({List<Type> matchedEvents, Type onDoEvent, Future<E> onDo()}) {
      final completer = Completer<E>();
      subscription = msgbloC.state.listen((event) {
         if (matchedEvents.any((event_type) => event.runtimeType == event_type)) {
            subscription?.cancel();
            if (event.runtimeType == onDoEvent) {
               completer.complete(onDo());
            }
         }
      });
      return completer.future;
   }
   
   
   
   Iterable<ST> refsToValue(List<List<int>> refs) {
      return refs.map((ref) {
         final id = ref[0];
         final subid = ref[1];
         final state = states[id][subid];
         if (inferred_ids.contains(id)) {
            idSetter(state, id);
         }
         return state;
      });
   }
   
   List<ST> _refUndo() {
      final refs = stateHistory.undo();
      return refsToValue(refs).toList();
   }
   
   List<ST> _refRedo() {
      final refs = stateHistory.redo();
      return refsToValue(refs).toList();
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
      inferred_ids = Set.from(inferredHistory
         .undo()
         .first);
      final json = _jsonUndo();
      final states = _refUndo();
      accumulatedStateHistory.undo();
      _renewUiStatesByMap(states.map(mapStateToData).toList());
      _recordStatesByUiStates();
      return json;
   }
   
   Map<String, dynamic> redo() {
      inferred_ids = Set.from(inferredHistory
         .redo()
         .first);
      final json = _jsonRedo();
      final states = _refRedo();
      accumulatedStateHistory.redo();
      _renewUiStatesByMap(states.map(mapStateToData).toList());
      _recordStatesByUiStates();
      return json;
   }
   
   
   ST beforeSaveState(ST state) {
   
   }
   
   /*
   
         I D    I N F E R R A N C E
   
   */
   void clearInferredIdsInStates() {
      inferred_ids.forEach((id) {
         states[id].forEach(clearId);
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
   // NOTE: following code are redundant, since unsaved_states are
   //       added within State initialization.
   
   bool unsavedMatcher(ST state) => throw Exception('NotImplemented yet');
   
   void addUnsavedState(int id, int subid) {
      unsaved_states[id] = subid;
   }
   
   bool _delStateOnLoadedState(ST del_state) {
      final del_id = idGetter(del_state);
      if (states_forUi.containsKey(del_id)) {
         inferred_ids.remove(del_id);
         states_forUi.remove(del_id);
      } else {
         throw Exception('Uncaught Exception, cannot found deleted state on ui side');
      }
      del_states.add(del_state);
      return true;
   }
   
   bool _delStateOnServer(ST del_state) {
      final data = List<Map<String, dynamic>>.from(initialData as List);
      final matched = data.firstWhere(
            (d) => d['id'] == idGetter(del_state), orElse: () => null);
      if (matched != null) {
         del_states.add(mapDataToState(matched));
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
      final master_id = idGetter(master_state);
      final slave_id = idGetter(slave_state);
      if (states_forUi.containsKey(slave_id)) {
         inferred_ids.remove(slave_id);
         states_forUi.remove(slave_id);
         assert(master_state != null);
         assert(slave_state != null);
         merge_states.add([master_state, slave_state]);
      } else {
         throw Exception('Uncaught Exception, cannot found merged state on ui side');
      }
   }
   
   bool undoMatcher(ST state) =>
      throw Exception('NotImplemented yet');
   
   bool redoMatcher(ST state) =>
      throw Exception('NotImplemented yet');
   
   bool mergeMatcher(ST state) => false;
   
   bool delMatcher(ST state) => false;
   
   bool uploadMatcher(ST state) =>
      throw Exception('NotImplemented yet');
   
   bool validate(ST state, List<Map<String, dynamic>> source) =>
      throw Exception('NotImplemented yet');
   
   ST saveState(ST state, int id, {bool addToUnsaved = false, ST slave}) {
      if (id == null) {
         if (undoMatcher(state)) {
            undo();
         } else if (redoMatcher(state)) {
            redo();
         } else if (uploadMatcher(state)) {
            //saveHistory();
         }
         return state;
      }
      if (delMatcher(state)) {
         delState(state);
      } else if (mergeMatcher(state) || slave != null) {
         mergeState(state, slave);
      } else if (id != null) {
         states[id] ??= [];
         states[id].add(state);
         states_forUi[id] = [state];
         if (addToUnsaved)
            addUnsavedState(id, states[id].length - 1);
         // states_forUi = states;
      }
      saveHistory();
      return state;
   }
   
   BaseMainStateManager({this.localpath, this.get_request_path, this.msgbloC, this.clearId, this.idGetter}) {
      final _cfg = Injection.injector.get<ConfigInf>();
      final h = _cfg.app.history;
      states = {};
      states_forUi = {};
      unsaved_states = {};
      del_states = [];
      merge_states = [];
      history = JsonHistory(h);
      stateHistory = RefHistory(h);
      inferredHistory = RefHistory(h);
      accumulatedStateHistory = AccRefHistory(h);
   }
}





































