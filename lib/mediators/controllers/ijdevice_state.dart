

import 'package:dio/dio.dart';
import 'package:nxp_bloc/mediators/controllers/ijdevice_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';

/// events for editing devices
enum EIJDevEvents{
   add, merge, edit, browse, save, upload, redo, undo, uploadUnit, undoUnit, redoUnit, del,
   uploadFinished, uploadUnitFinished, saveFinished, addFinished, editFinished, mergeFinished,
   syncConflict, resolveConflict, validationError,
   setState
}


abstract class IJDevEvents{
   List<bool> confirmConflict;
   // request
   int device_id;
   int merged_id;
   int inferred_id;
   int pagenum;
   String filename;
   EIJDevEvents event;
   DeviceModel model;
   // response
   String message;
   Response response;
}


/*

      I M A G E   J O U R N A L
      D E V I C E   E V E N T S

*/
class DevSetStateEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.setState;
}
class MergeDevEvent extends IJDevEvents {
   @override int device_id;
   @override int merged_id;
   @override EIJDevEvents event = EIJDevEvents.merge;
   MergeDevEvent({this.device_id, this.merged_id});
}
class EditDevEvent extends IJDevEvents {
   @override int device_id;
   @override DeviceModel model;
   @override EIJDevEvents event = EIJDevEvents.edit;
   EditDevEvent({this.device_id, this.model});
}
class DelDevEvent extends IJDevEvents {
   @override int inferred_id;
   @override EIJDevEvents event = EIJDevEvents.del;
   DelDevEvent({this.inferred_id});
}
class AddDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.add;
   @override int device_id;
   @override DeviceModel model;
   AddDevEvent({this.device_id, this.model});
}
class SaveDevEvent extends IJDevEvents {
   @override String filename;
   @override EIJDevEvents event = EIJDevEvents.save;
   SaveDevEvent({this.filename});
}
class BrowseDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.browse;
   BrowseDevEvent();
}
class UploadDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.upload;
   UploadDevEvent();
}
class UploadUnitDevEvent extends IJDevEvents {
   @override DeviceModel model;
   @override EIJDevEvents event = EIJDevEvents.uploadUnit;
   UploadUnitDevEvent(this.model);
}
class RedoDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.redo;
   RedoDevEvent();
}
class UndoDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.undo;
   UndoDevEvent();
}
class RedoUnitDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.redoUnit;
   @override int device_id;
   RedoUnitDevEvent(this.device_id);
}
class UndoUnitDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.undoUnit;
   @override int device_id;
   UndoUnitDevEvent(this.device_id);
}
class SyncConflictDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.syncConflict;
   SyncConflictDevEvent();
}

class ResolvedSyncConflictDevEvent extends IJDevEvents {
   @override EIJDevEvents event = EIJDevEvents.resolveConflict;
   @override List<bool> confirmConflict;
   ResolvedSyncConflictDevEvent(this.confirmConflict);
}

class ValidationErrorDevEvent extends IJDevEvents{
   @override EIJDevEvents event = EIJDevEvents.validationError;
   @override Response response;
   ValidationErrorDevEvent(this.response);
}


// ------------
// X - Finished
class XDevFinishedEvent extends IJDevEvents {
   @override String message;
   @override Response response;
   @override EIJDevEvents event;
   XDevFinishedEvent({this.message, this.response});
}
/*
class EditDevFinished extends XDevFinishedEvent{
   @override EIJDevEvents event = EIJDevEvents.editFinished;
}
class AddDevFinished extends XDevFinishedEvent{
   @override EIJDevEvents event = EIJDevEvents.addFinished;
}
*/
class MergeDevFinishedEvent extends XDevFinishedEvent{
   @override EIJDevEvents event = EIJDevEvents.mergeFinished;
}
class SaveDevFinishedEvent extends XDevFinishedEvent{
   @override EIJDevEvents event = EIJDevEvents.saveFinished;
   @override String message;
   SaveDevFinishedEvent(this.message);
}
class UploadDevFinishedEvent extends XDevFinishedEvent{
   @override EIJDevEvents event = EIJDevEvents.uploadFinished;
   @override String message;
   @override Response response;
   UploadDevFinishedEvent(this.message, this.response);
}

class UploadDevUnitFinishedEvent extends XDevFinishedEvent{
   @override EIJDevEvents event = EIJDevEvents.uploadUnitFinished;
   @override String message;
   @override Response response;
   UploadDevUnitFinishedEvent(this.message, this.response);
}




/*

         D E V I C E      S T A T E S


   int device_id;
   int merged_id;
   int pagenum;
   String filename;
   EIJDevEvents event;
   DeviceModel device;
   
   String message;
   Response response;


                                          */
class BaseIJDevState{
   //@fmt:off
   static BaseIJDevState fromMap (Map<String,dynamic> map){
      return BaseIJDevState()
         ..drop_model = DeviceModel.from(map['drop_model'] as Map<String,dynamic>)
         ..model      = DeviceModel.from(map['model']      as Map<String,dynamic>);
   }
   //@fmt:on
   static Map<String, Map<String,dynamic>>
   asMap(BaseIJDevState state, [BaseIJDevState drop_state]){
      final result = <String, Map<String,dynamic>>{};
      result['model'] = state.model.asMap();
      result['drop_model'] = drop_state?.model?.asMap();
      return result;
   }
   List<bool> confirmConflict;
   Response  response;
   DeviceModel model;
   DeviceModel drop_model;
   int get id => model?.id;
   int get merge_id => drop_model?.id;

   List<List<Map<String,dynamic>>>
   get conflictStack => DevState.conflictStack;

   List<List<bool>>
   get resolvedConflictStack => DevState.resolvedConflictStack;
   
   BaseIJDevState clone(BaseIJDevState state){
      if (state != null){
         if (state.model != null)
            model = state.model;
         model ??= DeviceModel("");
      }
   }
}
class DevStateReceive extends BaseIJDevState{
   @override DeviceModel model;
   DevStateReceive(this.model){
//      DevState.processing = BgProc.onIdle;
   }
}
class DevStateBrowse extends BaseIJDevState{
   DevStateBrowse(){
//      DevState.processing = BgProc.onIdle;
   }
}
class DevStateDefault extends BaseIJDevState{
   DevStateDefault(){
      model = DeviceModel("");
//      DevState.processing = BgProc.onIdle;
   }
}
class DevStateAdd extends BaseIJDevState{
   DevStateAdd(DeviceModel model) {
      this.model  = model;
//      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateEdit extends BaseIJDevState{
   DevStateEdit(int device_id, DeviceModel model){
      this.model     = model;
      model.id       = device_id;
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateDel extends BaseIJDevState{
   DevStateDel(DeviceModel model){
      this.model = model;
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateMerge extends BaseIJDevState{
   DevStateMerge(DeviceModel model, DeviceModel drop_model){
      //fixme:
      this.model = model;
      final drop_state = DevState.states.containsKey(drop_model.id)
            ? DevState.states[drop_model.id].last
            : DevStateDefault()
               ..model = drop_model;
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateSave extends BaseIJDevState{
   DevStateSave(String file_name){
      DevState.file_path = file_name;
      //DevState.processing = BgProc.onSave;
   }
}
class DevStateUpload extends BaseIJDevState{
   DevStateUpload(){
      //DevState.processing = BgProc.onUpload;
   }
}
class DevStateUnitUpload extends BaseIJDevState{
   DevStateUnitUpload(){
      //DevState.processing = BgProc.onUpload;
   }
}
class DevStateSaveFinisehd extends BaseIJDevState{
   DevStateSaveFinisehd(String message){
      DevState.state_message = message;
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateUploadFinished extends BaseIJDevState{
   DevStateUploadFinished(String message, Response response){
      this.response = response;
      //DevState.processing = BgProc.onIdle;
      DevState.state_message = message;
   }
}
class DevStateUndo extends BaseIJDevState{
   DevStateUndo(){
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateRedo extends BaseIJDevState{
   DevStateRedo(){
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateUndoUnit extends BaseIJDevState{
   @override DeviceModel model;
   DevStateUndoUnit(this.model){
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateRedoUnit extends BaseIJDevState{
   @override DeviceModel model;
   DevStateRedoUnit(this.model){
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateSyncConflict extends BaseIJDevState {
   DevStateSyncConflict(){
      //DevState.processing = BgProc.onIdle;
   }
}

class DevStateResolveSyncConflict extends BaseIJDevState {
   DevStateResolveSyncConflict(List<bool> confirmConflict){
      this.confirmConflict = confirmConflict;
      //DevState.processing = BgProc.onIdle;
   }
}

class DevStateValidationError extends BaseIJDevState{
   @override Response response;
   DevStateValidationError(this.response){
      //DevState.processing = BgProc.onIdle;
   }
}
class DevStateSetState extends BaseIJDevState{
}

