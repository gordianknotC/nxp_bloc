import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:common/common.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/permission.dart';
import 'package:nxp_bloc/mediators/controllers/user_state.dart';
import 'package:nxp_bloc/mediators/controllers/message_bloc.dart';
import 'package:nxp_bloc/mediators/di.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/models/model_error.dart';
import 'package:nxp_bloc/mediators/models/userauth_model.dart';
import 'package:nxp_bloc/consts/server.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:IO/src/io.codecs.dart' show Str;


final _D = AppState.getLogger("USERBLC");

// unused threee classes, Post, Validate
//todo:
// rewrite manager ....
class UserMainStateValidate<ST extends BaseUserState> extends BaseValidationService<ST> {
   UserMainStateValidate(this.manager, this.get) : super(manager, get);
   @override BaseStatesManager<ST> manager;
   @override BaseGetService<ST> get;
}


class UserMainStatePost<ST extends BaseUserState> extends BasePostService<ST> {
   @override BaseStatesManager<ST> manager;
   @override BaseValidationService<ST> validator;
   @override BaseMessageService msgbloC;
   @override String del_request_path;
   @override String post_request_path;
   @override String merge_request_path;
   
   UserMainStatePost(this.post_request_path, this.del_request_path,
                     this.merge_request_path, this.msgbloC,
                     this.validator, this.manager)
      : super(post_request_path, del_request_path, merge_request_path, msgbloC, validator, manager);
   
   @override Future<Dio.Response> onPost() {
      throw Exception('');
      if (body.length > 1)
         throw Exception('Uncaught Exception');
      final editmode = body.last['id'] != null;
      final user = UserModel()
         ..fromMap(body.last);
      
      if (UserState.isRegisteredUser){
         //return UserState.sendModification(user);
      }else{
         //return UserState.sendModification(user);
      }
   }
   
   @override Future<Dio.Response> onUploadComplete(List<Dio.Response>res, bool isDbOverriden, {List<int> ids}) async {
      throw Exception('');
//      final response = response_list.last;
//      await UserState.afterSend(response);
//      return super.onUploadComplete(res, isDbOverriden);
   }
   
   @override
   List<Map<String, dynamic>> getUploadData({List<int> ids}) {
      throw Exception('');
      final result = <Map<String, dynamic>>[];
      // fixme: sates_forUi
      manager.states_forUi.forEach((k, v) {
         if (ids == null)
            result.add(v.last.model.asMap());
         else if (ids.contains(k))
            result.add(v.last.model.asMap());
      });
      return result;
   }
}

class UserMainStateValidator<ST extends BaseUserState> extends BaseValidationService<ST> {
   UserMainStateValidator(this.manager, this.get) : super(manager, get);
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   
   @override bool validate(ST state, List<Map<String, dynamic>> source) {
      state.model.validate(source);
      return !state.model.hasValidationErrors;
   }
}


class UserMainStateGet<ST extends BaseUserState> extends BaseGetService<ST> {
   UserMainStateGet(this.get_request_path, this.manager) : super(get_request_path, manager);
   @override String get_request_path;
   @override BaseStatesManager<ST> manager;
   
   @override Future<Dio.Response> onGet({Map<String, dynamic> query, int retries = 1, bool isCached = true}) async {
      final body = initialData as List;
      if (body.first != null)
         UserState.currentUser = UserModel()
            ..fromMap(body.first as Map<String,dynamic>);
      return UserState.appEntryAuthenticating();
   }
   
   @override Dio.Response afterGet(Dio.Response res, {int retries = 1}) {
      final body = initialData as List;
      return UserState.afterAuth(res, body.first as Map<String,dynamic>, retries: retries);
   }
}

class UserMainStateStore<ST extends BaseUserState> extends BaseStoreService<ST> {
   @override BaseGetService<ST> get;
   @override BaseStatesManager<ST> manager;
   @override String unsavedpath;
   @override String localpath;
   
   UserMainStateStore(this.localpath, this.unsavedpath, this.manager, this.get)
      : super(localpath, unsavedpath, manager, get);
   
   @override
  Future<StoreInf> dump({bool unsaved = true, String path}) {
    // TODO: implement dump
      if (UserState.currentUser.username == null || UserState.currentUser.display_name == null)
         throw Exception("username and displayname could not be null");
      return super.dump(unsaved:unsaved, path: path);
  }
   @override
   List beforeDump(List<BaseUserState> states, dynamic json) {
      //note: states could be empty
      _D("beforeDump, states: ${states.map((s) => s.model.asMap())}");
      _D("currentUser: ${UserState.currentUser.asMap()}");
      _D("json: $json");
      final currentUser = UserState.currentUser.asMap();
      // dump currentUser only....
      
      final localdata = [currentUser]; //states.map((state) => state.model).toList();
      //final localdata = users.map((user) => user.asMap()).toList();
      return localdata;
   }
   
   @override dynamic afterLoad(String data) {
      return UserState.afterLoad(data);
   }
   
   @override
   Future<StoreInf> write({bool unsaved = true, String path, bool keepPassword = false}){
      if (UserState.currentUser.username == null || UserState.currentUser.display_name == null)
         throw Exception("username and displayname could not be null");
      
      final body = finaldata?.last;
      if (body != null && body['token'] != null){
         if (!keepPassword)
            body['password'] = null;
         return manager.file(
             path ?? (unsaved ? unsavedpath : localpath)
         ).writeAsync(jsonEncode(finaldata));
      }
      return null;
   }
}

class UserMainStateConverter<ST extends BaseUserState> extends BaseStateConverter<ST> {
   UserMainStateConverter(this.manager) : super(manager);
   @override BaseStatesManager<ST> manager;
   @override ST mapDataToState(Map<String, dynamic> data) {
      final model = UserModel()
         ..fromMap(data);
      return UserStateDefault(model) as ST;
   }
   
   @override Map<String, dynamic> mapStateToData(BaseUserState state, {bool considerValidation = false}) {
      return state.model.asMap(considerValidation: considerValidation);
   }
}

class UserMainStateMatcher<ST extends BaseUserState> extends BaseStateMatcher<ST> {
   @override bool uploadMatcher(ST state) => state is UserStateEditUpload || state is UserStateRegisterUpload;
   @override int idGetter(ST state) => state.model.id;
   @override int idSetter(ST state, int id) => state.model.id = id;
   @override void clearId(ST state) => state.model.id = null;
}

class UserMainStateManager<ST extends BaseUserState> extends BaseStatesManager<ST> {
   @override BaseStateConverter<ST> converter;
   @override BaseStateMatcher<ST> matcher;
   @override BaseStateProgress progressor;
   @override StoreInf Function(String path) file;
   @override ConfigInf config;
   void Function(Object) onInitialError;
   
   UserMainStateManager(this.config, this.file, {this.converter, this.matcher, this.progressor, this.onInitialError})
      : super(converter, matcher, progressor) {
      UserState.manager = this;
      converter = UserMainStateConverter(this);
      matcher = UserMainStateMatcher();
      progressor = BaseStateProgress();
      const localpath = 'nxp.db.offline.user.json';
      const unsavedpath = 'nxp.db.offline.user.unsaved.json';
      final get_request_path = '/${ename(ROUTE.user)}/ident/'; //fetch intialdata
      final post_request_path = '/${ename(ROUTE.user)}/register/'; // post
      final edit_request_path = '/${ename(ROUTE.user)}/edit/'; // post
      
      final msgBloC = MessageBloC();
      
      msg = BaseMessageService(msgBloC, this);
      get = BaseGetService(get_request_path, this);
      post = UserMainStatePost(
         post_request_path, null, null, msg,
         UserMainStateValidator(this, get), this
      );
      post.edit_request_path = edit_request_path;
      store = UserMainStateStore(localpath, unsavedpath, this, get);
      //remember = HistoryService(this, cfg.app.history);
      //fetchInitialData();
   }
   
   @override Future fetchInitialData() {
    final result = super.fetchInitialData();
    result.catchError(onInitialError);
    return result;
  }
   
   @override
   ST saveState(ST state, int id, {bool addToUnsaved = false, ST slave}) {
      return state;
   }
}






class UserState {
   //@fmt:off
   static final String savingId = uuid.v4();
   static final String uploadingId = uuid.v4();
   static final String loadingId = uuid.v4();
   
   static UserMainStateManager<BaseUserState> manager;// = UserMainStateManager();
   static Map<String,dynamic> formFields = {};
   static Map<int, List<BaseUserState>> get states          => manager.states_forUi;
   static Map<int, int>                 get unsaved_states  => manager.unsaved_states;
   static Completer<Dio.Response>           pendingCompleter;
   static UserBloC                      bloC;
   // -----------------------
   static UserModel     _currentUser;
   static UserModel get currentUser => _currentUser;
   static           set currentUser(UserModel user) {
      _currentUser = user;
   }
   // -----------------------
   static bool get isAuthenticated  =>
       currentUser!= null
           && (currentUser.token?.isValidToken ?? false)
           && currentUser.isAuthenticated;
   static bool get isRegisteredUser => manager.store.hasSavedLocalFile;
   /*static bool get isRegisteredUser => currentUser != null
                                    && currentUser.token != null
                                    && currentUser.id != null;*/
   
   static String get clientId {
      final config = manager.config;
      final key    = '${config.app.clientid}:${config.app.clientsecret}';
      debug('clientId: $key');
      return "Basic ${const Base64Encoder().convert(key.codeUnits)}";
   }
   
   static LoggerSketch debug = AppState.getLogger('UserBloc');
   //@fmt:on

   /*
   *
   *        m e t h o d s    w i t h o u t     c h e c k s u m
   *
   * */
   
   // triggered by ui
   
   static void stripUploadBody(Map<String,dynamic> body){
      final token = body['token'];
      if (token != null && token['refresh_token'] != null){
      }else{
         body.remove('token');
      }
   }
   static Future<Dio.Response>
   _sendJsonRequest(UserModel user, String url, Map<String,dynamic> body) async {
      stripUploadBody(body);
      final result = await Http().dioPost(url, body: body, headers: {
         HttpHeaders.authorizationHeader: clientId
      }).then((res) {
         if(manager.inferred_ids.contains(user.id)){
            manager.inferred_ids.remove(user.id);
         }
         closePendingCompleter(value: res);
         //currentUser.fromMap(body);
         return res;
      }).catchError((e) {
         closePendingCompleter();
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         throw Exception(str);

      });
      return result;
   }
   //unused:
   static Future<Dio.Response>
   _sendEncodedStringRequest(UserModel user, String url, Map<String,dynamic> body) async {
      stripUploadBody(body);
      return await Http().dioPost(url, headers: {
         HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
         HttpHeaders.authorizationHeader:clientId
      }, body: body.keys.map((k) => "$k=${Uri.encodeQueryComponent(body[k].toString())}").join("&")).then((res) {
         if(manager.inferred_ids.contains(user.id)){
            manager.inferred_ids.remove(user.id);
         }
         closePendingCompleter(value: res);
         //currentUser.fromMap(body);
         return res;
      }).catchError((e) {
         closePendingCompleter();
         final str = StackTrace.fromString(e.toString());
         debug.error(str);
         throw Exception(str);

      });
   }
   
   static Future<Dio.Response>
   _sendForm(UserModel user, String url, {bool jsonRequest = true}) async {
      user.validate([{
         'username': null,
         'display_name': null,
         'id': null,
      }]);
      final hasErrors = user.hasValidationErrors;
      final completer = Completer<Dio.Response>();
      final body      = user.asMap(considerValidation: true);
      //FN.ensureKeys(body, ["username", "display_name", "email", "permission"]);
      if (!hasErrors) {
         if(manager.inferred_ids.contains(user.id)){
            body.remove('id');
         }
         final Dio.Response result = jsonRequest
            ? await _sendJsonRequest(user, url, body)
            : await _sendEncodedStringRequest(user, url, body);
         
         completer.complete(result);
      } else {
         completer.complete(
            Dio.Response(data: body, statusCode: 409, headers: Dio.DioHttpHeaders.fromMap({
            ResponseConst.VALIDATE_ERR: 'validation error'
         })));
      }
      return completer.future;
   }

   /*
   *  1) send form data for user profile information
   *  3) userEditFinishedEvent
   *  4) close pending event completer if any
   */
   static Future<Dio.Response>
   sendModification(UserModel user) async {
      return guard(() async {
         final url = manager.post.edit_request_path;
         final body = user.asMap();
         FN.updateMembers(formFields, body, members: ['permission', 'username', 'display_name', 'password']);;

         final result = await _sendForm(user, url);
         return result;
      }, "send Modification failed", raiseOnly:  true);

   }

   /*
   *  1) send form data for user profile information
   *  3) userEditFinishedEvent
   *  4) close pending event completer if any
   */
   static Future<Dio.Response>
   sendRegistration(UserModel user) async {
      try{
         final url = manager.post.post_request_path;
         final body = user.asMap();
         FN.updateMembers(formFields, body, members: ['permission', 'username', 'display_name', 'password']);;
         
         final result = await _sendForm(user, url);
         return result;
      }catch (e){
         debug.error("send registration failed");
         throw Exception("send registration failed");
      }
   }


   static void
   cancelFormData(UserModel user) {
      closePendingCompleter();
   }

   static Future<Dio.Response>
   authByToken() async {
      manager.msg.bloC.onSendingAuth();
      final url = manager.get.get_request_path;
      return await Http().dioGet(url, headers: {
         HttpHeaders.authorizationHeader: currentUser.token.authorizationHeaderValue
      });
   }

   static Future<Dio.Response>
   refreshAuth() async {
      debug('refreshAuth');
      manager.msg.bloC.onRefreshingAuth();
      final body = {
         'grant_type': 'refresh_token',
         'refresh_token': currentUser.token.refreshToken
      };
      body['grant_type'] = 'refresh_token';
      final res = await Http().dioPost('/auth/token', headers: {
         HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
         HttpHeaders.authorizationHeader: clientId
      }, body: body.keys.map((k) => "$k=${Uri.encodeQueryComponent(body[k])}").join("&")).then((response) async {
         await afterSend(response, null);
         return response;
      }).catchError((e){
         final str = StackTrace.fromString(e.toString());
         debug.error(str.toString());
         return null;
      });
      //fixme: invalid request
      return res;
   }
   
   static Dio.Response _generalResponseToDioResponse(http.Response response)
      => Dio.Response(data: jsonDecode(response.body), statusCode: response.statusCode);
   
   static Future<Dio.Response>
   authByLogin(UserModel user) async {
//      final body = user.asMap();
//      FN.updateMembers(formFields, body, members: ['permission', 'username', 'password']);
      final body = {
        'username': user.username,
        'password': user.password,
        'grant_type': 'password'
      };
      manager.msg.bloC.onSendingAuth();
      //stripUploadBody(body);
      //body['grant_type'] = 'password';
      debug("auth by login: ${body}");
      debug("formFields:    ${formFields}");
      
      final res = await Http().post('/auth/token', headers: {
         "Content-Type": "application/x-www-form-urlencoded",
         "Authorization": UserState.clientId
      }, body: body.keys.map((k) => "$k=${Uri.encodeQueryComponent(body[k].toString())}").join("&"));
      //fixme: invalid request

      //untested:
      final diores = Dio.Response(data: jsonDecode(res.body), statusCode: res.statusCode);
      if (diores.statusCode == 200)
         debug("login success, ${diores.data}");
      else
         debug("login failed, ${diores.data}");
      await afterSend(diores, user);
      return diores;
   }

   static Future<Dio.Response> _authByToken() {
      // 1) try sending auth
      // 2) login or register
      return authByToken();
   }

   static Future<Dio.Response> authByRefreshToken() {
      // 1) try refreshing auth
      // 2) login or register
      return refreshAuth();
   }

   static Future<Dio.Response> _authByLogin() {
      // 1) sending form
      final completer = Completer<Dio.Response>();
      final model = currentUser;
      final event = UserLoginEvent(model: model);
      setPendingCompleter(completer);
      bloC.onLogin(UserLoginEvent(model: model));
      return completer.future;
   }

   static Future<Dio.Response> authByRegister() {
      // 1) sending form
      _D.debug("authByRegister");
      final completer = Completer<Dio.Response>();
      setPendingCompleter(completer);
      bloC.onRegister(UserRegisterEvent());
      return completer.future;
   }

   /*
   1) register   | login      |   authToken | refreshToken
   2)          set pending event completer
   3) onRegister | onLogin    | authByToken | authByRefresh
   4)      confirm ...        | close pending event completer
   
   5) sendFormData by user    |
   *   1) send form data for user profile information
   *   2) validate formdata
   *   3) userEditFinishedEvent
   *   4) close pending event completer if any
   6) cancel by user          |
   */
   static Future<Dio.Response> appEntryAuthenticating() async{
      debug('appEntryAuthenticating, isReg: $isRegisteredUser, isAuth: $isAuthenticated');
      debug('currentUser.token: ${currentUser.token?.asMap()}');
      final completer = Completer<Dio.Response>();
      if (!isRegisteredUser) {
         return await authByRegister();
      } else {
         if (isAuthenticated) {
            return await authByRefreshToken();
         } else {
            // load existing auth token before requiring auth
            await load(); // untested: add load() here is not tested yet
            if (currentUser.token != null && currentUser.token.refreshToken != null) {
               debug('auth by refreshTOken');
               return await authByRefreshToken();
            } else {
               if (currentUser.password != null){
                  debug('auth by login');
                  return await authByLogin(currentUser); // untested:
               } else {
                  raise('unexpected auth behavior, password is null');
                  return null;
               }
               debug('unexpected auth');
               await send(UserSendEvent(model: currentUser, sendtype: EUserSendType.login), completer: completer);

            }
         }
      }
      return completer.future;
   }

   static void setPendingCompleter(Completer<Dio.Response> successive) {
      closePendingCompleter(successive: successive);
   }

   static void closePendingCompleter({Dio.Response value, Completer<Dio.Response> successive}) {
      if (pendingCompleter != null) {
         if (successive != null) {
            if (value == null)
               pendingCompleter.completeError('closed by successived completer');
            else
               pendingCompleter.complete(value);
            pendingCompleter = successive;
         } else {
            if (value == null)
               pendingCompleter.completeError('forced to close completer by user');
            else
               pendingCompleter.complete(value);
            pendingCompleter = null;
         }
      } else {
         pendingCompleter = successive;
      }
   }

   
   /*
   *
   *        b l o c    a c t i o n s    w i t h     c h e c k s u m s
   *
   * */

   /*
         1) send auth stream
         2) ui recieve auth stream
         3) ui auth loading
         4) ---
              - (register   |  login    | auth ) stream
                 onRegister    onLogin    onAuth
      
      */
   // authenticate by "preloaded tokens / current user"
   static Future<BaseUserState>
   auth(AuthUserEvent event) async {
      debug('auth :: user auth');
      await appEntryAuthenticating();
      final user = currentUser ?? event.model;
      final result = genState(event, UserStateAuthenticated(user, user.token), true);
      return result;
   }
   
   static Future dumpAuthToDisk(Map<String, dynamic> body, {bool unsavedPath = false, bool keepPassword = true, Map<String, dynamic> rawBody}) async {
      currentUser = UserModel()
         ..fromMap(body);
      if (rawBody != null){
         if (keepPassword){
            final password = Str.encrypt(rawBody['password'] as String, rawBody['username'] as String);
            body['validationPassword'] = password;
         }
      }
      debug('dumpAuthToDisk: $body');
      manager.store.finaldata = [body];
      await (manager.store as UserMainStateStore).write(unsaved: unsavedPath, keepPassword: keepPassword);
   }
   
   static Dio.Response afterAuth(Dio.Response result, Map<String, dynamic> rawmodel, {int retries = 1}){
      final body = result.data as Map<String, dynamic>;
      _D.debug('afterAuth: ${body}');
      switch (result.statusCode) {
         case 200:
            // write to disk
            dumpAuthToDisk(body, unsavedPath: false, rawBody: rawmodel, keepPassword: true);
            break;
         case 401:
            if (isRegisteredUser) {
               // try refresh token later on...
               bloC.onAuth(AuthUserEvent());
            } else {
               // invoke register later on...
               bloC.onRegister(UserRegisterEvent());
            }
            break;
         default:
            MsgEvents event = MSG_EVENT_MAPPING[result.statusCode](null, uploadingId);
            manager.msg.bloC.dispatch(event);
            break;
      }
      return result;
   }
   static BaseUserState _loginOrReg(UserEvents event, [BaseUserState state, Completer<Dio.Response> completer]) {
      final isTriggeredByUser = completer == null;
      final user_id = event.user_id ?? manager.inferId(null);
      final model = event.model ?? currentUser;
      model.id ??= user_id;
      if (!isTriggeredByUser)
         closePendingCompleter(successive: completer);
      return state;
   }

   /*
   *  1) generate login state int event streaming, for invoking login form
   *  2) close pending event completer if any
   */
   static BaseUserState
   register(UserRegisterEvent event, [Completer<Dio.Response> completer]) {
      formFields = event.model?.asMap() ?? {};
      final user = bloC.currentState.model;
      final state = UserStateRegister(user);
      user.id = manager.inferId(null);
      return _loginOrReg(event, state, completer);
   }
   
   /*
   *  1) generate login state int event streaming, for invoking login form
   *  2) close pending event completer if any
   */
   static BaseUserState
   login(UserLoginEvent event, [Completer<Dio.Response> completer]) {
      formFields = event.model?.asMap() ?? {};
      final user = bloC.currentState.model;
      final state = UserStateLogin(user);
      return _loginOrReg(event, state, completer);
   }

   /*
   *  delete all user info
   */
   static void clearToken(){
      currentUser.token?.accessToken = null;
      currentUser.token?.refreshToken = null;
   }
   
   static void clearAuth(){
      if (manager.hasSavedLocalFile)
         manager.file(manager.store.localpath).deleteSync();
      currentUser.token?.accessToken = null;
      currentUser.token?.refreshToken = null;
      currentUser.password = null;
      currentUser.username = null;
      currentUser.display_name = null;
   }
   /*
   *  delete token on client, remember client id which means it's
   *  a registered user once ever.
   */
   static void logout({String password}){
//      currentUser.id = manager.inferId(null);
      currentUser.token?.accessToken = null;
      currentUser.token?.refreshToken = null;
      currentUser.password = null;
      
      if (password != null){
         final dumpData = currentUser.asMap();
         final cached = (manager.store.cache as List)?.first as Map<String,dynamic>;
         _D.debug('logout keep password, cache: $cached, dumpData: $dumpData');
         cached['password'] = password;
         dumpAuthToDisk(dumpData, unsavedPath: false, keepPassword: true, rawBody: cached);
      }else{
         final dumpData = currentUser.asMap();
         debug("logout: ${dumpData}");
//      manager.file(manager.store.localpath).deleteSync();
         dumpAuthToDisk(dumpData, unsavedPath: false, keepPassword: false);
      }
      
   }

   /*
   *  generate edit state into event streaming, for invoking a
   *  user profile form
   */
   /// edit user profile of current authorized user
   static Future<BaseUserState>
   edit(UserEditEvent event) async {
      //todo:
      /*formFields = event.model?.asMap() ?? {};
      final state = UserStateEdit(event.model);
      final result = genState(event, state, true);
      return result;*/
   }

   static BaseUserState browse(UserBrowseEvent event) {

   }

   /// edit user profile of other's
   static BaseUserState managerEdit(UserManagerEdit event) {

   }


   ///view profile of other user's
   static Future<BaseUserState>
   lookup(UserLookupEvent event) async {
      /*final result = genState(event, UserStateLookup(event.user_id, event.model), true);
      return result;*/
   }

   static BaseUserState
   validate(UserValidateEvent event) {
      final result = genState(event, UserStateValidate(event.model), true);
      return result;
   }
   
   static void onSyncConflict(){
      throw Exception('Uncaught Exception');
   }

   static BaseUserState syncConflict(UserSyncConflictEvent event){
      final result = genState(event, UserStateSyncConflict(event.model));
      // send back user model on server
      // todo: show diff compare with currentUser
      return result;
   }
   /*
   *  Called while receiving validation errors from server, after
   *  receiving response of previously send form data. Generally
   *  data had been validated before sending.
   */
   static void onValidationError(Dio.Response res) {
      final body = res.data as Map<String,dynamic>;
      if(body.containsKey(ResponseConst.VALIDATE_ERR)){
         final user = UserModel()
            ..fromMap(currentUser.asMap());
         user.validators.forEach((v){
            if(body[v.model_field] != null)
               v.reset(body[v.model_field] as String);
         });
         bloC.onValidate(UserValidateEvent(user));
      } else {
         // bloC.onSyncConflict(UserStateSyncConflictError());
         if(res.headers.value('servertime') != null){
            final user = UserModel()
               ..fromMap(body);
            bloC.onSyncConflict(UserSyncConflictEvent(user));
         }
      }
   }
   
   static List<Map<String,dynamic>>
   inferValidationSampleByResponseIds(UserModel model, Map<String,dynamic> body){
      final username        = model.username;
      final display_name    = model.display_name;
      final isCurrentUsername = body['username'] as int == model.id;
      final isCurrentNickname = body['display_name'] as int == model.id;
      final usernameNotFound = body['username'] == null ;
      final nicknameNotFound = body['display_name'] == null;
      var result     = <Map<String,dynamic>>[];
      
      if (isCurrentUsername){
      }else{
         if(!usernameNotFound)
            result.add({'username': username});
      }
      if (isCurrentNickname){
      }else{
         if (!nicknameNotFound)
            result.add({'display_name': display_name});
      }
      return result;
   }
   /*
   *     called from ui for user form data validation
   *     return a data map, mapping to existing user id
   *
   * */
   static Future<Map<String,dynamic>> validateUserForm(UserModel model) async {
      final username = model.username;
      final display_name = model.display_name;
      const url = '/user/validate/';
      final res = await Http().dioGet(url, qparam: {
         'username': username,
         'display_name': display_name
      });
      final completer = Completer<Map<String,dynamic>>();
      final emptyResult = <String,dynamic>{};

      if (res.statusCode != 404 && res.statusCode != 200 && res.statusCode != 409) {
         manager.msg.bloC.onInferNetworkError(res.statusCode, uploadingId, null);
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
         debug('validate erros: ${validated}');
         FN.updateMembers(result, validated,
            members:['username', 'display_name']);
         
         completer.complete(result);

      } else if (res.statusCode == 409) {
         // note: since no data sync check on server, so it can't be 409
         debug.error('statusCode 409 Uncaught exception');
         throw Exception('statusCode 409 Uncaught exception');
      }

      return completer.future;
   }

   
   static Future<Dio.Response> afterSend(Dio.Response res, UserModel rawUserModel) async {
      String message;
      int code = res.statusCode;
      switch (code) {
         case 200:
         // write to disk
            final body = res.data as Map<String, dynamic>;
            message = Msg.OK;
            //currentUser.id = body['id'] as int;
            
            if (body.containsKey('access_token'))
               currentUser.token = AuthorizationToken.fromMap(body);
            
            if (body.containsKey('access_token') || body.containsKey('refresh_token')){
               final token = <String,dynamic>{};
               body['token'] = token;
               FN.updateMembers(token, body,
                  members:['access_token', 'token_type', 'expires_in', 'refresh_token'],
                  removeFromSource: true);
            }
//            currentUser.fromMap(body);
            debug("send success, body: $body");
            formFields.addAll(body);
            currentUser.fromMap(formFields);
            formFields = {};
            final user = currentUser.asMap();
            await dumpAuthToDisk(user, unsavedPath: false, rawBody: rawUserModel.asMap(), keepPassword: true);
            manager.msg.bloC.onSendingAuthSuccess();
            closePendingCompleter(value: res);
            break;
         case 400:
            final body = res.data as Map<String, dynamic>;
            if (body.containsKey('error') && body['error'] == 'invalid_grant'){
               manager.msg.bloC.onSendingAuthFailed();
               closePendingCompleter(value: res);
            }
            message = Msg.ERROR;
            break;
         case 401:
            if (isRegisteredUser) {
               manager.msg.bloC.onEditProfileFailed();
            } else {
               manager.msg.bloC.onRegisterFailed();
            }
            message = Msg.RETRY;
            break;
         case 409:
            manager.msg.bloC.onValidationFailed();
            message = Msg.CONFLICT;
            onValidationError(res);
            break;
         default:
            MsgEvents event = MSG_EVENT_MAPPING[res.statusCode](null, uploadingId);
            manager.msg.bloC.dispatch(event);
            throw Exception(res.data.toString());
            break;
      }
      bloC.onSendFinished(UserSendFinishedEvent(message, res));
      return res;
   }

   static Future<BaseUserState>
   send(UserSendEvent event, {Completer<Dio.Response> completer}) async {
      final result = genState(event, UserStateSend(event.model, event.model.token), true);
      final user = result.model;
      Dio.Response response;
      manager.msg.bloC.onSendingAuth();
      if (event.sendtype == EUserSendType.register){
         user.id = null;
         response = await sendRegistration(user).then((r) => afterSend(r, user)).catchError((e) {
            bloC.onSendFinished(UserSendFinishedEvent(Msg.ERROR, null));
            manager.msg.bloC.onUncuahgClientError(e.toString());
            if (completer != null)
               completer.complete(null);
         });
      } else if (event.sendtype == EUserSendType.modify){
         response = await sendModification(user).then((r) => afterSend(r, user)).catchError((e) {
            bloC.onSendFinished(UserSendFinishedEvent(Msg.ERROR, null));
            manager.msg.bloC.onUncuahgClientError(e.toString());
            if (completer != null)
               completer.complete(null);
         });
      } else if (event.sendtype == EUserSendType.login){
//         user.id = null;
         response = await authByLogin(user).then((r) => afterSend(r, user)).catchError((e){
            bloC.onSendFinished(UserSendFinishedEvent(Msg.ERROR, null));
            manager.msg.bloC.onUncuahgClientError(e.toString());
            if (completer != null)
               completer.complete(null);
         });
      }
      if (completer != null)
         completer.complete(response);
      return result;
   }

   static BaseUserState
   cancel(UserCancelEvent event) {
      final result = genState(event, UserStateCancel(event.model, event.model.token), true);
      closePendingCompleter();
      return result;
   }

   static BaseUserState
   sendFinished(UserSendFinishedEvent event) {
      final result = genState(event, UserStateSendFinished(event.message, event.response), true);
      final msg    = event.message;
      // do something other than sending message, since
      // message has been send during after send;
      if (msg == Msg.OK || msg == Msg.SUCCESS) {
         onSendSuccess();
      } else if (msg == Msg.CONFLICT) {
         onSendConflict();
      } else if (msg == Msg.ERROR) {
         onSendError();
      } else if (msg == Msg.FAILED) {
         onSendFailed();
      } else {
         final str = 'sendFinished: uncaught message: $msg';
         debug.error(str);
         throw Exception(str);
      }
      // redundant...
      closePendingCompleter();
      assert(result != null);
      return result;
   }

   static onSendSuccess() {
   }

   static onSendFailed() {
   }

   static onSendError() {
   }

   static onSendConflict() {
      // show conflict
   }

   static Future<StoreInf> save() {
      return manager.store.dump();
   }

   static dynamic afterLoad(String data){
      debug('afterLoad: $data');
      if (data == null || data.isEmpty) {
         if (!isRegisteredUser) {
            // any bloc event send before defaultState has created would be canceled
            // since bloc stream not initialized yet
            bloC.onRegister(UserRegisterEvent());
         } else {
            // notice: unexpect behavior
            // unblock this while system are stable
            // throw Exception('Uncaught Exception');
         }
      } else {
         final result = jsonDecode(data) as List;
         final user = result.last as Map<String, dynamic>;
         UserState.currentUser = UserModel()..fromMap(user);
         debug('update token afterLoad: $data, isAuthed: ${UserState.isAuthenticated}');
         return result;
      }
   }
   static Future<List<Map<String, dynamic>>>
   load({bool unsaved = false, bool loadFileOnly = false}) async {
      final path = unsaved
         ? manager.store.unsavedpath
         : manager.store.localpath;
      final exists =  manager.file(path).existsSync();
      if (!loadFileOnly && exists){
         final list = await manager.store.load(path:path) as List;
         final data = list?.isNotEmpty ?? false
             ? List<Map<String,dynamic>>.from(list)
             : null;
         _D.debug('load presaved auth data: $data');
         if (data == null)
            return null;
         return data;
      }
      if (exists){
         final raw = await manager.file(path).readAsync();
         final list = jsonDecode(raw) as List;
         final data =list?.isNotEmpty ?? false
             ? List<Map<String,dynamic>>.from(list)
             : null;
         if (data == null)
            return null;
         return data;
      }
      return null;
   }

   static BaseUserState genState(UserEvents event, BaseUserState state, [bool addToUnsaved = false]) {
      final user_id = event.user_id ?? manager.inferId(null);
      final model = event.model ?? currentUser;
      model.id ??= user_id;
      state.model = model;
      return state;
   }


   
}



class UserBloC extends Bloc<UserEvents, BaseUserState> {
   static String get jsonPath => 'nxp.db.offline.device.json';
   BaseUserState last_state;
   UserBloC(UserMainStateManager manager){
      UserState.manager = manager;
      UserState.bloC = this;
   }
   
   @override BaseUserState
   get initialState {
      UserState.bloC = this;
      //UserState.manager = UserMainStateManager();
      UserState.currentUser ??= UserModel()
         ..id = UserState.manager.inferId(null)
         ..username = 'guest@hello.world'
         ..display_name = 'guest'
         ..permission = Permission.guest;
      return UserStateDefault(UserState.currentUser);
   }
   
   @override void onError(Object error, StackTrace stacktrace) {
      final str = "error obj: $error\n${stacktrace.toString()}";
      UserState.debug.error(str);
      throw Exception(str);
   }

   @override
   Stream<BaseUserState> mapEventToState(UserEvents event) async* {
      _D.debug('recieve: ${event.runtimeType}');
      if (currentState == last_state){
         _D.debug('block bloc $currentState');
         yield null;
      }
      last_state = currentState;
      BaseUserState new_state;
      switch (event.event) {
         case EUserEvents.syncConflict:
            new_state = UserState.syncConflict(event as UserSyncConflictEvent);
            break;
         case EUserEvents.register:
            new_state = UserState.register(event as UserRegisterEvent);
            break;
         case EUserEvents.lookup:
            new_state = await UserState.lookup(event as UserLookupEvent);
            break;
         case EUserEvents.edit:
            new_state = await UserState.edit(event as UserEditEvent);
            break;
         case EUserEvents.managerEdit:
            new_state = UserState.managerEdit(event as UserManagerEdit);
            break;
         case EUserEvents.getauth:
            new_state = await UserState.auth(event as AuthUserEvent);
            break;
         case EUserEvents.getvalidation:
            new_state = UserState.validate(event as UserValidateEvent);
            break;
         case EUserEvents.sendFinished:
            new_state = UserState.sendFinished(event as UserSendFinishedEvent);
            break;
         case EUserEvents.send:
            new_state = await UserState.send(event as UserSendEvent);
            break;
         case EUserEvents.cancel:
            new_state = UserState.cancel(event as UserCancelEvent);
            break;
         case EUserEvents.login:
            new_state = UserState.login(event as UserLoginEvent);
            break;
         case EUserEvents.browse:
            new_state = UserState.browse(event as UserBrowseEvent);
            break;
         case EUserEvents.setState:
            new_state = UserStateSetState();
            break;
         default:
            throw Exception('Uncuahgt exception');
      }
      UserState.debug('yield state: ${new_state}, ${new_state != null}');
      assert(new_state != null);
      yield new_state;
   }
   
   void onRegister(UserRegisterEvent event) {
      dispatch(event);
   }
   
   void onLogin(UserLoginEvent event) {
      dispatch(event);
   }
   
   void onUserEdit(UserEditEvent event) {
      dispatch(event);
   }

   void onUserManagerEdit(UserManagerEdit event) {
      dispatch(event);
   }

   void onBrowse(int page) {
      final event = UserBrowseEvent(page);
      dispatch(event);
   }
   
   void onValidate(UserValidateEvent event) {
      dispatch(event);
   }
   
   void onAuth(AuthUserEvent event) {
      dispatch(event);
   }
   
   void onSend(UserSendEvent event) {
      dispatch(event);
   }
   
   void onCancel(UserCancelEvent event) {
      dispatch(event);
   }
   
   void onSendFinished(UserSendFinishedEvent event) {
      dispatch(event);
   }
   
   /*void onUserValidateFinishedEvent(UserValidateFinishedEvent event) {
      dispatch(event);
   }*/
   
   void onSyncConflict(UserSyncConflictEvent event){
      dispatch(event);
   }

  void onSetState() {
      _D.debug('onSetState');
     dispatch(UserSetStateEvent());
  }
}


