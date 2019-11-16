import 'package:dio/dio.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:nxp_bloc/mediators/models/userauth_model.dart';

/// events for editing devices
enum EUserEvents {
   getauth,
   register,
   login,
   edit,managerEdit,
   lookup,
   send,
   cancel,
   getvalidation,
   sendFinished,
   setState,
   syncConflict,
   browse
}


enum EUserSendType{
   login, register, modify
}
abstract class UserEvents {
   // request
   int user_id;
   int page;
   EUserEvents event;
   UserModel model;
   AuthorizationToken usertoken;
   
   // response
   String message;
   Response response;
   String checkname;
   String chekemail;
   String checkpassword;
   EUserSendType sendtype;
}



class UserSetStateEvent extends UserEvents {
   @override EUserEvents event = EUserEvents.setState;
}

class UserLogoutEvent extends UserEvents {
   @override UserModel model;
   @override EUserEvents event = EUserEvents.login;

   UserLogoutEvent({this.model});
}

class UserLoginEvent extends UserEvents {
   @override UserModel model;
   @override EUserEvents event = EUserEvents.login;
   
   UserLoginEvent({this.model});
}

// user register
class UserRegisterEvent extends UserEvents {
   @override UserModel model;
   @override EUserEvents event = EUserEvents.register;
   
   UserRegisterEvent({this.model});
}

class UserBrowseEvent extends UserEvents {
   @override int page;
   @override EUserEvents event = EUserEvents.browse;
   UserBrowseEvent(this.page);
}

// trigger edit user
class UserManagerEdit extends UserEvents {
   @override UserModel model;
   @override EUserEvents event = EUserEvents.managerEdit;
   UserManagerEdit(this.model);
}

// trigger edit user
class UserEditEvent extends UserEvents {
   @override int user_id;
   @override UserModel model;
   @override EUserEvents event = EUserEvents.edit;
   
   UserEditEvent({this.user_id, this.model});
}

// user form validation
class UserValidateEvent extends UserEvents {
   @override int user_id;
   @override UserModel model;
   @override EUserEvents event = EUserEvents.getvalidation;
   UserValidateEvent(this.model);
}

// lookup user
class UserLookupEvent extends UserEvents {
   @override int user_id;
   @override UserModel model;
   @override EUserEvents event = EUserEvents.lookup;
   
   UserLookupEvent({this.user_id, this.model});
}

// for user authentication
class AuthUserEvent extends UserEvents {
   @override int user_id;
   @override UserModel model;
   @override EUserEvents event = EUserEvents.getauth;
   
   AuthUserEvent({ this.model});
}


/*class LoadUserEvent extends UserEvents {
   @override EUserEvents event = EUserEvents.load;
   LoadUserEvent();
}

class SaveUserEvent extends UserEvents {
   @override int user_id;
   @override UserModel model;
   @override EUserEvents event = EUserEvents.save;
   
   SaveUserEvent({this.user_id, this.model});
}*/

class UserSendEvent extends UserEvents{
   @override UserModel model;
   @override EUserEvents event = EUserEvents.send;
   @override EUserSendType sendtype;
   UserSendEvent({this.model, this.sendtype = EUserSendType.register});
}
class UserCancelEvent extends UserEvents{
   @override UserModel model;
   @override EUserEvents event = EUserEvents.cancel;

   UserCancelEvent({this.model});
}

class UserSyncConflictEvent extends UserEvents {
   @override EUserEvents event = EUserEvents.syncConflict;
   @override UserModel model; // note: model on server
   UserSyncConflictEvent(this.model);
}



// ------------
// X - Finished
class XUserFinishedEvent extends UserEvents {
   @override String message;
   @override Response response;
   @override EUserEvents event;
   
   XUserFinishedEvent({this.message, this.response});
}

/*class UserRegisterFinishedEvent extends XUserFinishedEvent {
   @override EUserEvents event = EUserEvents.registerFinished;
   @override String message;
   @override Response response;
   
   UserRegisterFinishedEvent(this.message, this.response);
}*/

class UserSendFinishedEvent extends XUserFinishedEvent {
   @override EUserEvents event = EUserEvents.sendFinished;
   @override String message;
   @override Response response;
   
   UserSendFinishedEvent(this.message, this.response);
}



/*class UserValidateFinishedEvent extends XUserFinishedEvent {
   @override EUserEvents event = EUserEvents.sendFinished;
   @override String message;
   @override Response response;
   
   UserValidateFinishedEvent(this.message, this.response);
}*/
/*
class UserAuthFinishedEvent extends XUserFinishedEvent {
   @override EUserEvents event = EUserEvents.authFinished;
   @override String message;
   @override Response response;
   
   UserAuthFinishedEvent(this.message, this.response);
   
}*/



class BaseUserState {
   //@fmt:off
   static BaseUserState
   fromMap (Map<String,dynamic> map){
      final model = UserModel()..fromMap(map['model'] as Map<String,dynamic>);
      return BaseUserState()
         ..model     = model
         ..usertoken = AuthorizationToken.fromMap(map['usertoken'] as Map<String,dynamic>);
   }
   //@fmt:on
   static Map<String, Map<String, dynamic>>
   asMap(BaseUserState state) {
      final result = <String, Map<String, dynamic>>{};
      result['model'] = state.model.asMap();
      result['usertoken'] = state.usertoken.asMap();
      return result;
   }

   AuthorizationToken usertoken;
   UserModel model;
   DateTime servertime;
   DateTime clientime;
   Response response;
   int      page;

   int get id => model.id;

   BaseUserState clone(BaseUserState state) {
      model = state.model;
      usertoken = state.usertoken;
   }
   
   bool get hasSyncConflict {
      return servertime != null;
   }
}

class UserStateAuthenticated extends BaseUserState {
   UserStateAuthenticated(UserModel user, AuthorizationToken tok) {
      model = user;
      usertoken = tok;
      model.token = tok;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateUnauthenticated extends BaseUserState {
   UserStateUnauthenticated(UserModel user) {
      model = user;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateDefault extends UserStateUnauthenticated {
   UserStateDefault(UserModel user) :super(user);
}

class UserStateBrowse extends BaseUserState {
   UserStateBrowse() {
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateRegister extends BaseUserState {
   UserStateRegister(UserModel user) {
      model = user;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateValidate extends BaseUserState {
   UserStateValidate(UserModel user) {
      model               = user;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateLogin extends BaseUserState {
   UserStateLogin(UserModel user) {
      model = user;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateLogout extends BaseUserState {
   UserStateLogout(UserModel user) {
      model = user;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateEdit extends BaseUserState {
   UserStateEdit(UserModel user) {
      model = user;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateEditUpload extends BaseUserState {
   UserStateEditUpload(UserModel user, AuthorizationToken tok) {
      model = user;
      usertoken = tok;
      //AppState.processing = BgProc.onUpload;
   }
}

class UserStateRegisterUpload extends BaseUserState {
   UserStateRegisterUpload(UserModel user, AuthorizationToken tok) {
      model = user;
      usertoken = tok;
      //AppState.processing = BgProc.onUpload;
   }
}

class UserStateLoad extends BaseUserState {
   UserStateLoad() {
      //AppState.processing = BgProc.onLoad;
   }
}

class UserStateSave extends BaseUserState {
   UserStateSave(UserModel user, AuthorizationToken tok) {
      model = user;
      usertoken = tok;
      //AppState.processing = BgProc.onSave;
   }
}

class UserStateRegisterFinished extends BaseUserState {
   UserStateRegisterFinished(String message, Response response) {
      this.response = response;
      AppState.state_message = message;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateLoginFinished extends BaseUserState {
   UserStateLoginFinished(String message, Response response) {
      this.response = response;
      AppState.state_message = message;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateSendFinished extends BaseUserState {
   UserStateSendFinished(String message, Response response) {
      this.response = response;
      AppState.state_message = message;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateSend extends BaseUserState {
   UserStateSend(UserModel user, AuthorizationToken tok) {
      model = user;
      usertoken = tok;
      //AppState.processing = BgProc.onUpload;
   }
}
class UserStateCancel extends BaseUserState {
   UserStateCancel(UserModel user, AuthorizationToken tok) {
      model = user;
      usertoken = tok;
      //AppState.processing = BgProc.onIdle;
   }
}

class UserStateValidateionError extends BaseUserState{
   UserStateValidateionError(UserModel user){
      model = user;
   }
}

class UserStateSyncConflict extends BaseUserState{
   UserStateSyncConflict(UserModel user){
      model = user;
   }
}

class UserStateSetState extends BaseUserState{
}



class UserBrowseState extends BaseUserState {
   @override int page;
   UserBrowseState(this.page);
}

// trigger edit user
class UserManagerEditState extends BaseUserState {
   @override UserModel model;
   UserManagerEditState(this.model);
}