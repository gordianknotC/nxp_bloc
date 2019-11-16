import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image/image.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/di.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_bloC.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';


//final _cfg = Injection.injector.get<ConfigInf>();
//final _RESIZE_CFG = _cfg.assets.size;
final _RESIZE_CFG = 1280;

/*

                   e n u m s


*/

/// Events for ImageJournal
enum EIJEvents {
   add, del, save, upload, load, queryDevice, selectDevice, browse,
   saveFinished, uploadFinished, loadFinished, setState,
   loadImage, loadImageFinished, queryDeviceFinished,
   changed,
   newsheet
}
/// unused
enum EditorMode {
   writeJournal, editDevice, editOptions, commentJournal
}
/// for indicating states of current process
/// [onIdle] finish all loading process on ui
enum BgProc {
   onLoad,
   onSave,
   onUpload,
   onIdle,
   onPrompt,
}

enum EAnswer{
   white, black, grey, noPaint
}
class PromptAnswer {
   int  length;       // data length
   bool cancel;
   List<EAnswer> answers;
   
   PromptAnswer( {this.length = 1, this.answers, this.cancel = false}){
      if (cancel)
         answers = [];
   }
}

//note:
// state design principle
// 1) could be update by another state
// 2) could be cleared by another state


/*

      E V E N T S
      I N T E R F A C E S

*/


//todo:
abstract class IJDataConflictEvents{

}


/*

      I M A G E   J O U R N A L
      J O U R N A L     E V E N T S

*/
abstract class IJEvents {
   // journal
   Response response;
   String   message;
   Map<int, ImageModel> content;
   int selected_device;
   int pagenum; // query image journals by device id
   
   int id;
   int rec_id;
   int device_id;
   int resize;
   // image journal
   ImageModel model;
   StoreInf file;
   String file_path;
   String url_path;
   String description;
   Image image;
   EIJEvents event;
}

class IJNewSheetEvent extends IJEvents{
   @override EIJEvents event = EIJEvents.newsheet;
}

class IJChangedEvent extends IJEvents{
   @override EIJEvents event = EIJEvents.changed;
}

class IJSelectDevEvent extends IJEvents{
   @override int device_id;
   @override EIJEvents event = EIJEvents.selectDevice;
   IJSelectDevEvent(this.device_id);
}

class IJQueryDevEvent extends IJEvents{
   @override EIJEvents event = EIJEvents.queryDevice;
   @override int selected_device;
   @override int pagenum;
   IJQueryDevEvent(this.selected_device, this.pagenum);
}

class IJQueryDevFinishedEvent extends IJEvents{
   @override EIJEvents event = EIJEvents.queryDeviceFinished;
   @override Response response;
   @override String message;
   IJQueryDevFinishedEvent({this.message, this.response});
}

class IJAddEvent extends IJEvents {
   @override int id;
   @override int rec_id;
   @override String description;
   @override ImageModel model;
   @override EIJEvents event = EIJEvents.add;
   IJAddEvent({this.rec_id, this.description, this.model, this.id});
}

class IJDelEvent extends IJEvents {
   @override int rec_id;
   @override EIJEvents event = EIJEvents.del;
   IJDelEvent({this.rec_id});
}

class IJLoadImageFinishedEvent extends IJEvents {
   @override int rec_id;
   @override Image image;
   @override String message;
   @override EIJEvents event = EIJEvents.loadImageFinished;
   IJLoadImageFinishedEvent({this.rec_id, this.image, this.message});
}

class IJLoadImageEvent extends IJEvents {
   @override int rec_id;
   @override String file_path;
   @override Image image;
   @override int resize;
   @override String description;
   @override EIJEvents event = EIJEvents.loadImage;
   IJLoadImageEvent({this.rec_id, this.file_path, this.image, this.resize, this.description});
}

class IJSaveEvent extends IJEvents {
   @override String file_path;
   @override EIJEvents event = EIJEvents.save;
   IJSaveEvent({this.file_path});
}

class IJSaveFinishedEvent extends IJEvents {
   @override String message;
   @override StoreInf file;
   @override EIJEvents event = EIJEvents.saveFinished;
   IJSaveFinishedEvent({this.message, this.file});
}

class IJUploadEvent extends IJEvents {
   @override EIJEvents event = EIJEvents.upload;
   IJUploadEvent();
}

class IJUploadFinishedEvent extends IJEvents {
   @override String message;
   @override Response response;
   @override EIJEvents event = EIJEvents.uploadFinished;
   IJUploadFinishedEvent({this.message, this.response});
}

class IJLoadEvent extends IJEvents {
   @override String file_path;
   @override String url_path;
   @override EIJEvents event = EIJEvents.load;
   IJLoadEvent({this.file_path});
}

class IJLoadFinishedEvent extends IJEvents {
   @override String message;
   @override String file_path;
   @override Map<int, ImageModel> content;
   @override EIJEvents event = EIJEvents.loadFinished;
   IJLoadFinishedEvent({this.message, this.file_path, this.content});
}
class IJBrowseEvent extends IJEvents {
   @override EIJEvents event = EIJEvents.browse;
   IJBrowseEvent();
}
class IJSetStateEvent extends IJEvents {
   @override EIJEvents event = EIJEvents.setState;
   IJSetStateEvent();
}



/*
*
*
*              S T A T E
*
*
* */


class BaseIJState {
   // Image Journal
   int id;
   int rec_id;
   ImageModel model;
   
   String get description => model.description;
   String get path => model.path;
   
   bool get changed => IJState.changed;
        set changed(bool v) => IJState.changed = v;
   
   void clone([BaseIJState state]) {
      if (state != null){
         rec_id = state.rec_id;
         id = state.id;
         model = ImageModel.clone(state.model);
      }
      final int patrolRecordId = null;
      final String patrolRecordDate = "";
      model ??= ImageModel("", null, state?.model?.resize ?? _RESIZE_CFG, patrolRecordId, patrolRecordDate);
   }
   
   Map<String, dynamic> asMap() {
      final ret = {
         'id': id,
         'rec_id': rec_id,
         'description': description,
         'image_path': path,
         'file_path': path,
      };
      filterNullInMap(ret);
      return ret;
   }
   
   void setDefault() {
      rec_id      = 0;
      //processing = BgProc.onIdle;
      //IJState.processing = BgProc.onIdle;
      
   }
}

class IJStateDefault extends BaseIJState {
   IJStateDefault() {
      setDefault();
   }
}
class IJStateNewSheet extends BaseIJState {
   IJStateNewSheet() {
      setDefault();
      //IJState.processing = BgProc.onIdle;
      IJState.changed = true;
      IJState.states = {};
      IJState.title = '';
      IJState.conclusion = '';
      IJState.summary = '';
      IJState.state_message = '';
      IJState.imagejournal_id = null;
      IJState.file_path = IJState.getJournalPath();
   }
}
class IJStateAdd extends BaseIJState {
   IJStateAdd(int rec_id, String desc, {ImageModel model, int id}) {
      if (model == null)
         clone();
      else
         this.model = model;
      
      //IJState.processing = BgProc.onIdle;
      IJState.changed    = true;
      this.rec_id = rec_id;
      this.id = id;
      this.model.description = desc;
      
   }
   @override String toString() => "IJStateAdd";
}

class IJStateSave extends BaseIJState {
   IJStateSave(String path, IJBloC bloc) {
      clone(bloc.currentState);
      IJState.state_message = Msg.onSaving;
      //IJState.processing = BgProc.onSave;
      model.path = path;
   }
}

class IJStateSaveFinished extends BaseIJState {
   IJStateSaveFinished(String message, IJBloC bloC) {
      clone(bloC.currentState);
      IJState.state_message = message;
      //IJState.processing = BgProc.onIdle;
      IJState.changed = false;
   }
}

class IJStateDel extends BaseIJState {
   IJStateDel(BaseIJState state) {
      clone(state);
      //IJState.processing = BgProc.onIdle;
      IJState.state_message = Msg.onDelConfirm;
      IJState.changed = true;
   }
}

class IJStateUpload extends BaseIJState {
   IJStateUpload (IJBloC bloC) {
      clone(bloC.currentState);
      //IJState.processing = BgProc.onUpload;
      IJState.state_message = Msg.onUpload;
   }
}

class IJStateUploadFinished extends BaseIJState {
   IJStateUploadFinished (String message, IJBloC bloC) {
      clone(bloC.currentState);
      //IJState.processing = BgProc.onIdle;
      IJState.state_message = message;
   }
}

class IJStateLoad extends BaseIJState {
   IJStateLoad(String path, IJBloC bloC) {
      clone(bloC.currentState);
      //IJState.processing = BgProc.onLoad;
      IJState.state_message = Msg.onLoadJournal;
      model.path = path;
   }
}

class IJStateLoadFinished extends BaseIJState {
   IJStateLoadFinished(String message, IJBloC bloC) {
      clone(bloC.currentState);
      //IJState.processing = BgProc.onIdle;
      IJState.state_message = message;
      IJState.changed = false;
   }
}

class IJStateLoadImage extends BaseIJState {
   IJStateLoadImage(String path, BaseIJState state, {int resize}) {
      state.model.path = path;
      state.model.resize = resize ?? state.model.resize ?? ImageModel.RESIZE;
      clone(state);
      //IJState.processing = BgProc.onLoad;
      IJState.state_message = Msg.onLoadImage;
//      model = ImageModel(description, path, resize ?? _RESIZE_CFG);
   }
}

class IJStateLoadImageFinished extends BaseIJState {
   IJStateLoadImageFinished(String message, BaseIJState state, Image image) {
      clone(state);
      IJState.state_message = message;
      //IJState.processing = BgProc.onIdle;
      IJState.changed = true;
      model.resized_image = image;
   }
}

/*
class IJStateSelectDevice extends BaseIJState{
   IJStateSelectDevice(int device_id, BaseIJState state) {
      clone(state);
      IJState.selectDevice(device_id);
      //IJState.processing = BgProc.onLoad;
   }
}
*/

class IJStateQueryDevice extends BaseIJState{
   IJStateQueryDevice(BaseIJState state) {
      clone(state);
      //IJState.processing = BgProc.onLoad;
   }
}
class IJStateQueryDeviceFinished extends BaseIJState {
   IJStateQueryDeviceFinished(String message, IJBloC bloC) {
      clone(bloC.currentState);
      IJState.state_message = message;
   }
}

class IJSetState extends BaseIJState {
   IJSetState(){
//      AppState.processing = BgProc.onLoad;
   }
}

class IJBrowseState extends BaseIJState {
   IJBrowseState(){
//      AppState.processing = BgProc.onLoad;
   }
}






