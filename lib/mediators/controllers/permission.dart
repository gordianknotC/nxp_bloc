import 'dart:async';
import 'dart:async';

import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijdevice_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijdevice_state.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_state.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_state.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/user_state.dart';
import 'package:nxp_bloc/mediators/models/userauth_model.dart';


StreamTransformer<A, A> getAuthTransformer<A>(BaseAuthGuard<A> authGuard){
   return StreamTransformer<A, A>.fromHandlers(
      handleData: (A event, EventSink<A> sink) {
         if (authGuard.guard(event)){
            return sink.add(event);
         }
         DevState.debug('block event: ${event.runtimeType}');
      },
      handleError: (error, stacktrace, sink) {
         DevState.manager.msg.bloC.onBugReport(stacktrace);
         sink.addError('internal error: $error');
      },
      handleDone: (sink) {
         sink.close();
      },
   );
}


class BaseAuthGuard<T> {
   static void enable(){
      _enable = true;
   }
   static void disable(){
      _enable = false;
   }
   static bool _enable = true;

   bool _guardUser(T event){
      return event is! DelPatrolEvent;
   }
   bool _guardGuest(T event){
      return event is DelPatrolEvent
             || event is PatrolUploadEvent
             || event is EditPatrolEvent
             || event is PatrolSaveEvent;
   }
   bool _guardEngineer(T event){
      return true;
   }
   bool _guardAdministrator(T event){
      return true;
   }
   bool guard(T event, {void onBlock()}){
      if (!_enable)
         return true;
      
      bool result = false;
      switch(AppState.permission){
         case Permission.administrator: result = _guardAdministrator(event); break;
         case Permission.user:          result =  _guardUser(event);break;
         case Permission.engineer:      result =  _guardEngineer(event);break;
         case Permission.guest:         result =  _guardGuest(event);break;
      }
      if (!result){
         if (AppState.authenticated)
            AppState.msg.onPermissionDenied(event.runtimeType.toString());
         else
            AppState.msg.onPermissionLogin(event.runtimeType.toString());
         onBlock?.call();
      }
      return result;
   }
}



class PatrolAuthGuard<E extends PatrolEvents> extends BaseAuthGuard<E>{
   PatrolMainStateManager manager;
   PatrolAuthGuard(this.manager);
   @override bool _guardUser(PatrolEvents event){
      return event is! DelPatrolEvent
         && event is! EditPatrolEvent;
   }
   @override bool _guardGuest(PatrolEvents event){
      return event is! DelPatrolEvent
         && event is! EditPatrolEvent
         && event is! PatrolUploadEvent;
   }
   @override bool _guardEngineer(PatrolEvents event){
      return true;
   }
   @override bool _guardAdministrator(PatrolEvents event){
      return true;
   }
}


class NFCIOAuthGuard<E extends NFCycleState> extends BaseAuthGuard<E>{
   NFCIOAuthGuard();
   bool isCommon(NFCycleState state){
      return state is NFCycleFailed
         || state is NFCycleSuccess
         || state is NFCycleReadSuccess
         || state is NFCycleRetry
         || state is NFCycleDefault
         || state is NFCycleSetState
         || state is NFCyclePermissionDenied
         || state is NFCycleCancel
         || state is NFCycleLogState
         || state is NFCycleReadLogState
         || state is NFCycleInternalError
         || state is NFCycleWriteCommandSuccess
          || state is NFCycleWriteCommandMissed
         || state is NFCycleBootState
         || state is NFCycleShutdownState;
   }
   
   bool isUser(E st){
      return st is NFCycleReadState
       || st is NFCycleUopState
          || st is NFCycleWriteNtagSuccess
          || st is NFCycleWriteNtagMissed
       || st is NFCyclePatrolState;
   }
   
   bool isEngineer(E st){
      return st is NFCycleUresetState;
   }
   
   bool isAdmin(E st){
      return st is NFCycleInitialState;
   }
   
   @override bool _guardUser(E st){
      final result = isUser(st) || isCommon(st);
      if(!result)
         print('## permisssion denied: ${st.runtimeType}');
      return result;
   }
   @override bool _guardGuest(E st){
      return isCommon(st);
   }
   @override bool _guardEngineer(E st){
      return isEngineer(st) || isUser(st) || isCommon(st);
   }
   @override bool _guardAdministrator(E st){
      return isAdmin(st) || isEngineer(st) || isUser(st) || isCommon(st);
   }
}

class DevAuthGuard<E extends IJDevEvents> extends BaseAuthGuard<E>{
   DeviceMainStateManager manager;
   DevAuthGuard(this.manager);
   @override bool _guardUser(E event){
      return event is BrowseDevEvent
         || event is DevSetStateEvent
      ;
   }
   @override bool _guardGuest(E event){
      return false;
   }
   @override bool _guardEngineer(E event){
      return true;
   }
   @override bool _guardAdministrator(E event){
      return true;
   }
}


class OptAuthGuard<E extends IJOptEvents> extends BaseAuthGuard<E>{
   DescOptMainStateManager manager;
   OptAuthGuard(this.manager);
   @override bool _guardUser(IJOptEvents event){
      return event is! DelOptEvent
         && event is! UploadOptEvent
         && event is! EditOptEvent;
   }
   @override bool _guardGuest(E event){
      return event is BrowseOptEvent || event is SetStateOptEvent;
   }
   @override bool _guardEngineer(E event){
      return true;
   }
   @override bool _guardAdministrator(E event){
      return true;
   }
}


class UserAuthGuard<E extends UserEvents> extends BaseAuthGuard<E>{
   UserMainStateManager manager;
   UserAuthGuard(this.manager);
   @override bool _guardUser(UserEvents event){
      return  event is! UserBrowseEvent;
   }
   @override bool _guardGuest(E event){
      return  event is! UserBrowseEvent;
   }
   @override bool _guardEngineer(E event){
      return  event is! UserBrowseEvent;
   }
   @override bool _guardAdministrator(E event){
      return true;
   }
}




class ImgJAuthGuard<E extends IJEvents> extends BaseAuthGuard<E>{
   ImgJAuthGuard();
   @override bool _guardUser(IJEvents event){
      return event is! IJDelEvent;
   }
   @override bool _guardGuest(IJEvents event){
      return false;
   }
   @override bool _guardEngineer(E event){
      return true;
   }
   @override bool _guardAdministrator(E event){
      return true;
   }
}