import 'package:dio/dio.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';

/// events for editing options
enum EIJOptEvents {
   add,
   del,
   edit,
   browse,
   save,
   upload,
   uploadFinished,
   saveFinished,
   addFinished,
   editFinished,
   delFinished,
   undo,
   redo,
   syncConflict,
   resolvedSyncConflict,
   validationError, setState
}

abstract class IJOptEvents {
   // request
   int option_id;
   int pagenum;
   String filename;
   EIJOptEvents event;
   IJOptionModel option;
   
   // response
   String message;
   Response response;
   List<bool> confirmConflict;
}


/*

      I M A G E   J O U R N A L
      O P T I O N S     E V E N T S

*/
class DelOptEvent extends IJOptEvents {
   @override int option_id;
   @override IJOptionModel option;
   @override EIJOptEvents event = EIJOptEvents.del;
   DelOptEvent({this.option_id, this.option});
}

class EditOptEvent extends IJOptEvents {
   @override int option_id;
   @override EIJOptEvents event = EIJOptEvents.edit;
   @override IJOptionModel option;
   
   EditOptEvent({this.option_id, this.option});
}

class AddOptEvent extends IJOptEvents {
   @override EIJOptEvents event = EIJOptEvents.add;
   @override int option_id;
   @override IJOptionModel option;
   
   AddOptEvent({this.option_id, this.option});
}

class SaveOptEvent extends IJOptEvents {
   @override String filename;
   @override EIJOptEvents event = EIJOptEvents.save;
   
   SaveOptEvent();
}

class UploadOptEvent extends IJOptEvents {
   @override EIJOptEvents event = EIJOptEvents.upload;
   UploadOptEvent();
}

class UndoOptEvent extends IJOptEvents {
   @override EIJOptEvents event = EIJOptEvents.undo;
   UndoOptEvent();
}

class RedoOptEvent extends IJOptEvents {
   @override EIJOptEvents event = EIJOptEvents.redo;
   RedoOptEvent();
}

class BrowseOptEvent extends IJOptEvents {
   @override EIJOptEvents event = EIJOptEvents.browse;
   BrowseOptEvent();
}

class SetStateOptEvent extends IJOptEvents {
   @override EIJOptEvents event = EIJOptEvents.setState;
   SetStateOptEvent();
}

class ValidationErrorOptEvent extends IJOptEvents{
   @override EIJOptEvents event = EIJOptEvents.validationError;
   @override Response response;
   ValidationErrorOptEvent(this.response);
}

// ------------
// X - Finished
class XOptFinishedEvent extends IJOptEvents {
   @override String message;
   @override Response response;
   @override EIJOptEvents event;
   
   XOptFinishedEvent({this.message, this.response});
}

class EditOptFinished extends XOptFinishedEvent {
   @override EIJOptEvents event = EIJOptEvents.editFinished;
}

class AddOptFinished extends XOptFinishedEvent {
   @override EIJOptEvents event = EIJOptEvents.addFinished;
}

class DelOptFinished extends XOptFinishedEvent {
   @override EIJOptEvents event = EIJOptEvents.delFinished;
}

class SaveOptFinishedEvent extends XOptFinishedEvent {
   @override EIJOptEvents event = EIJOptEvents.saveFinished;
   @override String message;
   @override Response response;
   
   SaveOptFinishedEvent(this.message){
      AppState.state_message = message;
   }
}

class UploadOptFinishedEvent extends XOptFinishedEvent {
   @override EIJOptEvents event = EIJOptEvents.uploadFinished;
   @override String message;
   @override Response response;
   
   UploadOptFinishedEvent(this.message, this.response){
      AppState.state_message = message;
   }
}

class SyncConflictOptEvent extends XOptFinishedEvent  {
   @override EIJOptEvents event = EIJOptEvents.syncConflict;
   SyncConflictOptEvent();
}

class ResolvedSyncConflictOptEvent extends XOptFinishedEvent  {
   @override EIJOptEvents event = EIJOptEvents.resolvedSyncConflict;
   @override List<bool> confirmConflict;
   ResolvedSyncConflictOptEvent(this.confirmConflict);
}


/*

         O P T I O N S      S T A T E S

*/
class BaseIJOptState {
   static BaseIJOptState fromMap(Map<String, dynamic> map) {
      return BaseIJOptState()
         ..option = IJOptionModel.from(map);
   }
   
   static Map<String, dynamic> asMap(BaseIJOptState state) {
      final result = state.option.asMap();
      return result;
   }
   
   Response response;
   IJOptionModel option;
   List<bool> confirmConflict;
   
   int get option_id => option.id;
   
   clone({BaseIJOptState state}) {
      if (state != null) {
         if (state.option != null)
            option = state.option;
         option ??= IJOptionModel("", "");
      }
   }
   
   List<List<Map<String,dynamic>>>
   get conflictStack => DescOptState.conflictStack;

   List<List<bool>>
   get resolvedConflictStack => DescOptState.resolvedConflictStack;
}

class OptStateBrowse extends BaseIJOptState {
   OptStateBrowse() {
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateSetState extends BaseIJOptState {
   OptStateSetState() {
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateDefault extends BaseIJOptState {
   OptStateDefault() {
      option = IJOptionModel("", "");
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateAdd extends BaseIJOptState {
   OptStateAdd(IJOptionModel model) {
      option = model;
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateEdit extends BaseIJOptState {
   OptStateEdit(int option_id, IJOptionModel model) {
      option = model;
      option.id = option_id;
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateDel extends BaseIJOptState {
   OptStateDel(int option_id, IJOptionModel model) {
      option = model;
      option.id = option_id;
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateSave extends BaseIJOptState {
   OptStateSave(String file_name) {
      DescOptState.file_path = file_name;
      //DescOptState.processing = BgProc.onSave;
   }
}

class OptStateUpload extends BaseIJOptState {
   OptStateUpload() {
      //DescOptState.processing = BgProc.onUpload;
   }
}

class OptStateUndo extends BaseIJOptState {
   OptStateUndo() {
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateRedo extends BaseIJOptState {
   OptStateRedo() {
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateSaveFinisehd extends BaseIJOptState {
   OptStateSaveFinisehd(String message) {
      DescOptState.state_message = message;
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateUploadFinished extends BaseIJOptState {
   OptStateUploadFinished(String message, Response response) {
      this.response = response;
      //DescOptState.processing = BgProc.onIdle;
      DescOptState.state_message = message;
   }
}

class OptStateSyncConflict extends BaseIJOptState {
   OptStateSyncConflict(){
    //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateResolveSyncConflict extends BaseIJOptState {
   OptStateResolveSyncConflict(List<bool> confirmConflict){
      this.confirmConflict = confirmConflict;
      //DescOptState.processing = BgProc.onIdle;
   }
}

class OptStateValidationError extends BaseIJOptState{
   @override Response response;
   OptStateValidationError(this.response){
      //DescOptState.processing = BgProc.onIdle;
   }
}
