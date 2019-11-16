import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/di.dart';


enum ETextMsgType {
   info,
   warning,
   error
}

enum EMsgEvents {
   appError,
   networkConnection,
   serverError,
   conflict,
   illegalRequest,
}
enum EMsgType {
   // deprecate
   notifyInfo,
   notifyWarning,
   notifyError,
   // not implemented
   confirmDialog,
   warningDialog,
   diffDialog,
   form,
   progress,
   // -------------------
   // working
   empty,
   close,
   online,
   offline,
   warning,
   trying,
   seeking,
   saving,
   loading,
   saved,
   saveFailed,
   loaded,
   loadFailed,
   stack,
}

typedef TMsgGetter = MsgEvents Function(String msg, String id);

final Map<int, EMsgType> MSG_TYPE_MAPPING = {
   400: EMsgType.confirmDialog, // bad request
   401: EMsgType.notifyError, // Unauthorzied
   403: EMsgType.notifyError, // forbidden
   404: EMsgType.notifyError, // resource not found
   408: EMsgType.notifyError,
   409: EMsgType.diffDialog, // conflict
   415: EMsgType.confirmDialog, // unsupported media type
   429: EMsgType.notifyError, //
   4000: EMsgType.notifyError, // uncaught 4xx code
   // ----------------------
   500: EMsgType.notifyError,
   501: EMsgType.warningDialog, // not implementded
   503: EMsgType.notifyError, // server not available
   504: EMsgType.notifyError, //
   511: EMsgType.warningDialog, //
   5000: EMsgType.notifyError, // uncaught 5xx code
};
final Map<int, TMsgGetter> MSG_EVENT_MAPPING = {
   2000: (String msg, String id) => MsgGeneralClientSucccessEvent(msg, id),
   // ------------------------------
   3000: (String msg, String id) => MsgGeneralRedirectEvent(msg, id),
   // ------------------------------
   400: (String msg, String id) => MsgBadRequestEvent(id),
   401: (String msg, String id) => MsgUnAuthorsizedEvent(id),
   403: (String msg, String id) => MsgForbiddenEvent(id),
   404: (String msg, String id) => MsgResourceNotFoundEvent(id),
   408: (String msg, String id) => MsgRequestTimeout(id),
   409: (String msg, String id) => MsgConflictEvent(id),
   415: (String msg, String id) => MsgUnsupportedMediaTypeEvent(id),
   429: (String msg, String id) => MsgTooManyRequestsEvent(id),
   4000: (String msg, String id) => MsgGeneralClientErrorEvent(msg, id),
   // ------------------------------
   500: (String msg, String id) => MsgInternalServerError(id),
   501: (String msg, String id) => MsgNotImplementedEvent(id),
   503: (String msg, String id) => MsgServiceNotAvailableEVent(id),
   511: (String msg, String id) => MsgNetworkAuthRequiredEvent(msg, id),
   5000: (String msg, String id) => MsgGeneralServerErrorEvent(msg, id),
};

/*

                  E V E N T S


*/

abstract class MsgEvents {
   Map<String, dynamic> diffA;
   Map<String, dynamic> diffB;
   String id;
   String message;
   Map<String, dynamic> extra;
   int duration;
   int progress;
   int statusCode;
   int cycleTime;
   int maxRetries;
   EMsgEvents event;
   EMsgType msg_type;
   
   void clone(MsgEvents event) {
      if (event == null)
         return;
      diffA = event.diffA;
      diffB = event.diffB;
      id = event.id;
      message = event.message;
      extra = event.extra;
      duration = event.duration;
      progress = event.progress;
      statusCode = event.statusCode;
      cycleTime = event.cycleTime;
      maxRetries = event.maxRetries;
      this.event = event.event;
      this.msg_type = event.msg_type;
   }
   
   MsgEvents({this.id, this.message, this.extra, this.duration, this.progress, this.statusCode, this.event, EMsgType msg_type}) {
      this.msg_type = msg_type;
   }
}

class MsgGDefaultEvent extends MsgEvents {
   MsgGDefaultEvent([Map<String, dynamic> extra]) :super(statusCode: 0, extra: extra);
}
/*

         g e n e r a l    e v e n t s
         

*/
class MsgGeneralClientSucccessEvent extends MsgEvents {
   MsgGeneralClientSucccessEvent(String msg, String id) :super(statusCode: 2000, message: Msg.GeneralSendSuccess, id: id) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgGeneralRedirectEvent extends MsgEvents {
   MsgGeneralRedirectEvent(String msg, String id) :super(id: id, message: Msg.GeneralRedirection, statusCode: 3000) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgGeneralServerErrorEvent extends MsgEvents {
   MsgGeneralServerErrorEvent(String msg, String id) : super(id: id, message: Msg.GeneralServerError, statusCode: 5000) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgGeneralClientErrorEvent extends MsgEvents {
   MsgGeneralClientErrorEvent(String msg, String id) : super(id: id, message: Msg.GeneralClientError, statusCode: 4000) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}
/*

         s e v e r     e v e n t s
         

*/
class MsgNetworkAuthRequiredEvent extends MsgEvents {
   MsgNetworkAuthRequiredEvent(String msg, String id) : super(id: id, statusCode: 511, message: Msg.NetworkAuthRequired) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgServiceNotAvailableEVent extends MsgEvents {
   MsgServiceNotAvailableEVent(String id) :super(id: id, message: Msg.ServiceNotAvailable, statusCode: 503) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgNotImplementedEvent extends MsgEvents {
   MsgNotImplementedEvent(String id) :super(id: id, message: Msg.NotImplemented, statusCode: 501) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgInternalServerError extends MsgEvents {
   MsgInternalServerError(String id) :super(id: id, message: Msg.InteralServerError, statusCode: 500) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

/*

         c l i e n t    e v e n t s
         

*/
class MsgRequestTimeout extends MsgEvents {
   MsgRequestTimeout(String id) :super(id: id, message: Msg.RequestTimeout, statusCode: 408) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgTooManyRequestsEvent extends MsgEvents {
   MsgTooManyRequestsEvent(String id) :super(id: id, message: Msg.TooManyRequests, statusCode: 429) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgUnsupportedMediaTypeEvent extends MsgEvents {
   MsgUnsupportedMediaTypeEvent(String id) :super(id: id, message: Msg.MediaTypeUnsupported, statusCode: 415) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgConflictEvent extends MsgEvents {
   MsgConflictEvent(String id) :super(id: id, message: Msg.ConflictConfirmation, statusCode: 409) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgResourceNotFoundEvent extends MsgEvents {
   MsgResourceNotFoundEvent(String id) :super(id: id, message: Msg.ResourceNotFound, statusCode: 401) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgUnAuthorsizedEvent extends MsgEvents {
   MsgUnAuthorsizedEvent(String id) :super(id: id, message: Msg.UnAuthorized, statusCode: 401) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgBadRequestEvent extends MsgEvents {
   MsgBadRequestEvent(String id) :super(id: id, message: Msg.BadRequest, statusCode: 400) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgForbiddenEvent extends MsgEvents {
   MsgForbiddenEvent(String id) :super(id: id, message: Msg.PermissionDenied, statusCode: 403) {
      msg_type = MSG_TYPE_MAPPING[statusCode];
   }
}

class MsgNotRegisteredYet extends MsgEvents {
   MsgNotRegisteredYet(String id) :super(id: id, message: Msg.NotRegisteredYet, msg_type: EMsgType.form);
}

class MsgLoginFirst extends MsgEvents {
   MsgLoginFirst(String id) :super(id: id, message: Msg.LoginFirst, msg_type: EMsgType.form);
}


class MsgSendingAuth extends MsgEvents {
   MsgSendingAuth(String id) :super(id: id, message: Msg.SendingAuth, msg_type: EMsgType.loading);
}

class MsgOnSendingAuthSuccess extends MsgEvents {
   MsgOnSendingAuthSuccess(String id) :super(id: id, message: Msg.SendingAuthSuccess, msg_type: EMsgType.notifyInfo);
}


class MsgRefreshingAuth extends MsgEvents {
   MsgRefreshingAuth(String id) :super(id: id, message: Msg.RefreshingAuth, msg_type: EMsgType.notifyInfo);
   
}


class MsgRetryAuthEvent extends MsgEvents {
   MsgRetryAuthEvent(int retries, int max) :super(msg_type: EMsgType.notifyInfo) {
      message = Msg.onAuthRetry(retries, max);
   }
}

class MsgOfflineMode extends MsgEvents {
   MsgOfflineMode() :super(message: Msg.onOfflineMode, msg_type: EMsgType.offline);
}

class MsgOnlineMode extends MsgEvents {
   MsgOnlineMode() :super(message: Msg.onOfflineMode, msg_type: EMsgType.offline);
}

class MsgOnEditProfileFailed extends MsgEvents {
   MsgOnEditProfileFailed() :super(message: Msg.editProfileFailed, msg_type: EMsgType.notifyError);
}

class MsgOnRegisterFailed extends MsgEvents {
   MsgOnRegisterFailed() :super(message: Msg.registerFailed, msg_type: EMsgType.notifyError);
}

class MsgOnUploadValidatoinFailed extends MsgEvents {
   MsgOnUploadValidatoinFailed() :super(message: Msg.onUploadFormValidationError, msg_type: EMsgType.notifyError);
}

class MsgSendingAuthFinished extends MsgEvents {
   MsgSendingAuthFinished([String code = ""]) :super(message: Msg.authorizeFailed(code), msg_type: EMsgType.notifyError);
}

class MsgUncaughtClientError extends MsgEvents {
   MsgUncaughtClientError(String msg) :super(message: Msg.onUncaughtError(msg), msg_type: EMsgType.notifyError);
}

class MsgSendMailError extends MsgEvents {
   MsgSendMailError(String msg) :super(message: Msg.onMessage(msg), msg_type: EMsgType.notifyError);
}

class MsgMessage extends MsgEvents {
   MsgMessage(String msg) :super(message: Msg.onMessage(msg), msg_type: EMsgType.notifyInfo);
}

class MsgWarning extends MsgEvents {
   MsgWarning(String msg) :super(message: Msg.onMessage(msg), msg_type: EMsgType.notifyError);
}


/*


         F I L E     E V E N T S
         state messengers

*/
class MsgOnDelFile extends MsgEvents {
   MsgOnDelFile() :super(message: Msg.onDel, msg_type: EMsgType.saving);
}

class MsgOnDelFileNotFound extends MsgEvents {
   MsgOnDelFileNotFound() :super(message: Msg.onDelNotFound, msg_type: EMsgType.saveFailed);
}

class MsgOnDelFileFailed extends MsgEvents {
   MsgOnDelFileFailed() :super(message: Msg.onDelFailed, msg_type: EMsgType.saveFailed);
}

class MsgOnDelFileSuccess extends MsgEvents {
   MsgOnDelFileSuccess() :super(message: Msg.onDelSucceed, msg_type: EMsgType.saved);
}



class MsgFileOnSave extends MsgEvents {
   MsgFileOnSave(String id) :super(id: id, message: Msg.onSaving, msg_type: EMsgType.saving);
}

class MsgFileSaveSuccessEvent extends MsgEvents {
   MsgFileSaveSuccessEvent(String id) :super(id: id, message: Msg.onSaveSuccess, msg_type: EMsgType.saved);
}

class MsgFileSavingNotFoundEvent extends MsgEvents {
   MsgFileSavingNotFoundEvent(String id) :super(id: id, message: Msg.onSavingNotFound, msg_type: EMsgType.saveFailed);
}

class MsgFileSavingFailedEvent extends MsgEvents {
   MsgFileSavingFailedEvent(String id) :super(id: id, message: Msg.onSavingFailed, msg_type: EMsgType.saveFailed);
}

class MsgFileUploadingEvent extends MsgEvents {
   MsgFileUploadingEvent(String id) :super(id: id, message: Msg.onFileUploading, msg_type: EMsgType.loading);
}

class MsgFileUploadingSuccessEvent extends MsgEvents {
   MsgFileUploadingSuccessEvent(String id, [Map<String, dynamic> extra])
      :super(id: id, message: Msg.onFileUploading, msg_type: EMsgType.loading);
}

class MsgFileUploadingFailedEvent extends MsgEvents {
   MsgFileUploadingFailedEvent(String message, String id, [Map<String, dynamic> extra])
      :super(id: id, extra: extra, message: Msg.onFileUploadingFailed(message), msg_type: EMsgType.loadFailed);
}

class MsgFileLoading extends MsgEvents {
   MsgFileLoading(String id) : super(id: id, message: Msg.onFileLoading(), msg_type: EMsgType.loading);
}

class MsgFileLoadSuccessEvent extends MsgEvents {
   MsgFileLoadSuccessEvent(String id) :super(id: id, message: Msg.onFileLoadingSuccess(), msg_type: EMsgType.loaded);
}

class MsgFileLoadFailedEvent extends MsgEvents {
   MsgFileLoadFailedEvent(String id)
      :super(id: id, message: Msg.onFileLoadingFailed(), msg_type: EMsgType.loadFailed);
}



class MsgInquiryNonUndoableRequest extends MsgEvents {
   MsgInquiryNonUndoableRequest([Map<String, dynamic> extra])
      :super(extra: extra, msg_type: EMsgType.confirmDialog, message: Msg.onInquiryNonUndoableRequest);
}

class MsgNonUndoableResponseOKEvent extends MsgEvents {
   @override EMsgType msg_type;
   
   MsgNonUndoableResponseOKEvent() {
      msg_type = EMsgType.notifyInfo;
   }
}

class MsgNonUndoableResponseCancelEvent extends MsgEvents {
   @override EMsgType msg_type;
   
   MsgNonUndoableResponseCancelEvent() {
      msg_type = EMsgType.notifyInfo;
   }
}

class MsgInquiryUploadingEvent extends MsgEvents {
   MsgInquiryUploadingEvent([Map<String, dynamic> extra]) :super(
      extra: extra, message: Msg.onInquiryUploadingRequest, msg_type: EMsgType.confirmDialog);
}

class MsgInquiryUploadResponseOKEvent extends MsgEvents {
   MsgInquiryUploadResponseOKEvent() :super(msg_type: EMsgType.confirmDialog);
}

class MsgInquiryUploadResponseCancelEvent extends MsgEvents {
   MsgInquiryUploadResponseCancelEvent() :super(msg_type: EMsgType.confirmDialog);
}

class MsgUrlCannotLaunchEvent extends MsgEvents {
   MsgUrlCannotLaunchEvent(String link) :super(message: Msg.onUrlCannotLaunch(link), msg_type: EMsgType.notifyInfo);
}



class MsgOnSendingAuthFailed extends MsgEvents {
   MsgOnSendingAuthFailed(String message) :super(message: Msg.authorizeFailed(message), msg_type: EMsgType.notifyError);
}

class MsgOnPermissionDenied extends MsgEvents {
   MsgOnPermissionDenied(String name) :super(message: Msg.permissionDenied(name), msg_type: EMsgType.notifyError);
}

class MsgOnPermissionLogin extends MsgEvents {
   MsgOnPermissionLogin(String name) :super(message: Msg.permissionLogin(name), msg_type: EMsgType.notifyError);
}

class MsgOnBugReport extends MsgEvents {
   MsgOnBugReport(StackTrace stacktrace) :super(message: Msg.onBugReport(stacktrace));
}

class MsgOnCreatingJournal extends MsgEvents {
   MsgOnCreatingJournal() :super(message: Msg.onCreatingJournal);
}



class MsgFileLoadParsingFailed extends MsgEvents {
   MsgFileLoadParsingFailed(String id) :super(id: id, msg_type: EMsgType.notifyError, message: Msg.onFileParsingFailed());
}

class MsgFileNotFound extends MsgEvents {
   MsgFileNotFound() :super(msg_type: EMsgType.notifyError, message: Msg.onFileNotFound());
}


/*

                F I N I S H E D     E V E N T S


*/



/*

                S T A T E S


*/

class MessageState {
   static MessageBloC bloC;
   
   static MsgEvents Function(MsgEvents event) eventCatcher = (MsgEvents event) {
      return event;
   };
   
}


class MessageBloC extends Bloc<MsgEvents, MsgEvents> {
   static String get jsonPath => 'nxp.db.offline.device.json';
   static MessageBloC instance;
   MsgEvents last_event;
   
   MessageBloC.empty();
   
   factory MessageBloC(){
      if (instance != null)
         return instance;
      return instance = MessageBloC.empty();
   }
   
   @override MsgEvents
   get initialState {
      MessageState.bloC = this;
      return MsgGDefaultEvent();
   }
   
   @override
   Stream<MsgEvents> mapEventToState(MsgEvents event) async* {
      if (event == last_event)
         yield null;
      last_event = event;
      AppState.state_message = event.message;
      yield MessageState.eventCatcher(event);
   }
   
   void onUrlCannotLaunch(String link) {
      dispatch(MsgUrlCannotLaunchEvent(link));
   }
   
   void onFileLoading(String id) {
      dispatch(MsgFileLoading(id));
   }
   
   void onFileLoadingSuccess(String id) {
      dispatch(MsgFileLoadSuccessEvent(id));
   }
   
   void onFileLoadingFailed(String id) {
      dispatch(MsgFileLoadFailedEvent(id));
   }
   
   void onGenernalClientSuccess(String id) {
      dispatch(MsgGeneralClientSucccessEvent(null, id));
   }
   
   void onGeneralRedirect(String id) {
      dispatch(MsgGeneralRedirectEvent(null, id));
   }
   
   void onGeneralServerError(String id) {
      dispatch(MsgGeneralServerErrorEvent(null, id));
   }
   
   void onGeneralClientError(String id) {
      dispatch(MsgGeneralClientErrorEvent(null, id));
   }
   
   void onFileLoadingParsingFailed(String id) {
      dispatch(MsgFileLoadParsingFailed(id));
   }
   
   void onFileNotFound() {
      dispatch(MsgFileNotFound());
   }
   
   
   /*
   
         c l i e n t    e v e n t s
         
   */
   void onTooManyRequest(String id) {
      dispatch(MsgTooManyRequestsEvent(id));
   }
   
   void onBadRequest(String id) {
      dispatch(MsgBadRequestEvent(id));
   }
   
   void onUnauthorized(String id) {
      dispatch(MsgUnAuthorsizedEvent(id));
   }
   
   void onForbidden(String id) {
      dispatch(MsgForbiddenEvent(id));
   }
   
   void onNotFound(String id) {
      dispatch(MsgResourceNotFoundEvent(id));
   }
   
   void onRequestTimeout(String id) {
      dispatch(MsgRequestTimeout(id));
   }
   
   void onConfict(String id) {
      dispatch(MsgConflictEvent(id));
   }
   
   void onMediaUnsupported(String id) {
      dispatch(MsgUnsupportedMediaTypeEvent(id));
   }
   
   void onUncuahgClientError(String message) {
      dispatch(MsgUncaughtClientError(message));
   }
   
   void onSendMailError(String message) {
      dispatch(MsgSendMailError(message));
   }
   
   void onMessage(String message) {
      dispatch(MsgMessage(message));
   }
   
   void onWarning(String message) {
      dispatch(MsgWarning(message));
   }
   
   /*
   
         s e v e r    e v e n t s
         
   */
   void onServerInternalError(String id) {
      dispatch(MsgBadRequestEvent(id));
   }
   
   void onServerNotImplemented(String id) {
      dispatch(MsgBadRequestEvent(id));
   }
   
   void onServerServiceUnavailable(String id) {
      dispatch(MsgBadRequestEvent(id));
   }
   
   void onWifiAuthenticationRequired(String id) {
      dispatch(MsgBadRequestEvent(id));
   }
   
   void onUncaughtServerError(String id) {
      dispatch(MsgBadRequestEvent(id));
   }
   
   
   
   void onInferNetworkError(int statusCode, String uploadid, String message) {
      if (statusCode >= 400 && statusCode < 500) {
         dispatch((MSG_EVENT_MAPPING[statusCode] ?? MSG_EVENT_MAPPING[4000])(message, uploadid));
      } else if (statusCode >= 500) {
         dispatch((MSG_EVENT_MAPPING[statusCode] ?? MSG_EVENT_MAPPING[5000])(message, uploadid));
      } else if (statusCode >= 300 && statusCode < 400) {
         dispatch((MSG_EVENT_MAPPING[statusCode] ?? MSG_EVENT_MAPPING[3000])(message, uploadid));
      } else if (statusCode >= 200 && statusCode < 300) {
         dispatch((MSG_EVENT_MAPPING[statusCode] ?? MSG_EVENT_MAPPING[2000])(message, uploadid));
      }
   }
   
   /*
   
         f i l e    e v e n t s
         
   */
   void onFileSaving(String id) {
      dispatch(MsgFileOnSave(id));
   }
   
   void onFileSuccessfullySaved(String id) {
      dispatch(MsgFileSaveSuccessEvent(id));
   }
   
   void onFileSavingFailed(String id) {
      dispatch(MsgFileSavingFailedEvent(id));
   }
   
   void onFileUploading(String id) {
      dispatch(MsgFileUploadingEvent(id));
   }
   
   void onFileUploadingFailed(String message, String id) {
      dispatch(MsgFileUploadingFailedEvent(message, id));
   }
   
   void onFileUploadingSuccess(String id) {
      dispatch(MsgFileUploadingSuccessEvent(id));
   }
   
   void onUserInquiryNonUndoableRequest() {
      dispatch(MsgInquiryNonUndoableRequest());
   }
   
   void onUserInquiryUploadRequest() {
      dispatch(MsgInquiryUploadingEvent());
   }
   
   void onRetryAuth(int retries, int max) {
      dispatch(MsgRetryAuthEvent(retries, max));
   }
   
   /*
   *
   *        n e t w o r k     e v e n t s
   *
   * */
   void onNetworkAvailable() {
   
   }
   
   void onNetworkUnavailable() {
   
   }
   
   void onOfflineMode() {
   
   }
   
   void onOnlineMode() {
   
   }
   
   /*
   *
   *
   */
   void onRegister([String id = "register"]) {
      dispatch(MsgNotRegisteredYet(id));
   }
   
   void onLogin([String id = "login first"]) {
      dispatch(MsgLoginFirst("login first"));
   }
   
   void onSendingAuth([String id = "send auth"]) {
      dispatch(MsgSendingAuth(id));
   }
   
   void onRefreshingAuth([String id = "refresh auth"]) {
      dispatch(MsgRefreshingAuth(id));
   }
   
   void onSendingAuthFinished() {
      dispatch(MsgSendingAuthFinished());
   }
   
   void onEditProfileFailed() {
      dispatch(MsgOnEditProfileFailed());
   }
   
   void onRegisterFailed() {
      dispatch(MsgOnRegisterFailed());
   }
   
   void onValidationFailed() {
      dispatch(MsgOnUploadValidatoinFailed());
   }
   
   void onSendingAuthSuccess([String id = "send auth success"]) {
      dispatch(MsgOnSendingAuthSuccess(id));
   }
   
   void onSendingAuthFailed([String extra = 'invalid_grant']) {
      dispatch(MsgOnSendingAuthFailed(extra));
   }
   
   void onPermissionDenied(String name) {
      dispatch(MsgOnPermissionDenied(name));
   }
   
   void onPermissionLogin(String name) {
      dispatch(MsgOnPermissionLogin(name));
   }
   
   void onBugReport(StackTrace stacktrace) {
      dispatch(MsgOnBugReport(stacktrace));
   }
   
   void onCreatingFile() {
      dispatch(MsgOnCreatingJournal());
   }
   
   void onDispatch(MsgEvents event) {
      dispatch(event);
   }
   
   void onFileSavingNotFound(String savingId) {
      dispatch(MsgFileSavingNotFoundEvent(savingId));
   }
}








