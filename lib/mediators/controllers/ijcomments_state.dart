import 'package:http/http.dart';


/// events for adding tag on journal comment system
enum EIJCmtTags{
   solved, pending, problem, emergency, notag, custom
}
enum EIJCmtCustomTag{
   add, edit, del
}
/// Events for adding comments on journal comment system
enum EIJCmtEvents{
   del, edit, add, reply, addTag, removeTag, addCustomTag,
   editFinished, addFinished, delFinished, replyFinished,
   addTagFinished, removeTagFinished, addCustomTagFinished,
   nextpage, prevpage
}
enum EIJCmtSorts{
   date, user, device,
}
enum EIJCmtFilters{
   solved, pending, problem, emergency, notag, custom
}

//ello
//world
abstract class IJTemp{

}

abstract class IJCmtEvents{
   // request
   int journal_id;
   int record_id;
   int comment_id;
   int customtag_id;
   int pagenum;
   String comment;
   EIJCmtEvents event;
   EIJCmtTags tagEvt;
   EIJCmtSorts sortEvt;
   EIJCmtFilters filterEvt;
   IJCmtCustomTagEvents customTagEvt;
   // response
   String message;
   Response response;
//
}
abstract class IJCmtCustomTagEvents{
   int customtag_id;
   int customtag_name;
   int customtag_icon;
   EIJCmtCustomTag event;
}


/*

      I M A G E   J O U R N A L
      C O M M E N T S   E V E N T S

*/
class IJCmtSortEvent extends IJCmtEvents{
   @override EIJCmtSorts sortEvt;
   IJCmtSortEvent({this.sortEvt});
}
class IJCmtFilterEvent extends IJCmtEvents{
   @override EIJCmtFilters filterEvt;
   IJCmtFilterEvent({this.filterEvt});
}
class IJCmtAddCustomTagEvent extends IJCmtEvents{
   @override IJCmtCustomTagEvents customTagEvt;
   @override EIJCmtEvents event = EIJCmtEvents.addCustomTag;
   IJCmtAddCustomTagEvent({this.customTagEvt});
}
class IJCmtAddTagEvent extends IJCmtEvents {
   @override int journal_id;
   @override int record_id;
   @override int customtag_id;
   @override EIJCmtEvents event = EIJCmtEvents.addTag;
   @override EIJCmtTags tag;
   IJCmtAddTagEvent({this.journal_id, this.record_id, this.tag, this.customtag_id});
}
class IJCmtRemoveTagEvent extends IJCmtEvents {
   @override int journal_id;
   @override int record_id;
   @override EIJCmtEvents event = EIJCmtEvents.removeTag;
   @override EIJCmtTags tag = EIJCmtTags.notag;
   IJCmtRemoveTagEvent({this.journal_id, this.record_id});
}
class IJCmtNextEvent extends IJCmtEvents {
   @override int pagenum;
   @override EIJCmtEvents event = EIJCmtEvents.nextpage;
   IJCmtNextEvent({this.pagenum});
}
class IJCmtPrevEvent extends IJCmtEvents {
   @override int pagenum;
   @override EIJCmtEvents event = EIJCmtEvents.prevpage;
   IJCmtPrevEvent({this.pagenum});
}
class IJCmtReplyEvent extends IJCmtEvents{
   @override int journal_id;
   @override int record_id;
   @override int comment_id;
   @override String comment;
   @override EIJCmtEvents event = EIJCmtEvents.reply;
   IJCmtReplyEvent({this.journal_id, this.record_id, this.comment, this.comment_id});
}
class IJCmtAddEvent extends IJCmtEvents {
   @override int journal_id;
   @override int record_id;
   @override String comment;
   @override EIJCmtEvents event = EIJCmtEvents.add;
   IJCmtAddEvent({this.journal_id, this.record_id, this.comment});
}
class IJCmtEditEvent extends IJCmtEvents {
   @override int journal_id;
   @override int record_id;
   @override int comment_id;
   @override String comment;
   @override EIJCmtEvents event = EIJCmtEvents.edit;
   IJCmtEditEvent({this.journal_id, this.record_id, this.comment_id, this.comment});
}
class IJCmtDelEvent extends IJCmtEvents {
   @override int journal_id;
   @override int record_id;
   @override int comment_id;
   @override EIJCmtEvents event = EIJCmtEvents.del;
   IJCmtDelEvent({this.journal_id, this.record_id, this.comment_id});
}
// ----------------------
//     X - finished
class IJCmtXFinishedEvent extends IJCmtEvents{
   @override String message;
   @override Response response;
   @override EIJCmtEvents event;
   IJCmtXFinishedEvent({this.message, this.response});
}
class IJCmtDelFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.delFinished;
}
class IJCmtAddFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.addFinished;
}
class IJCmtEditFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.editFinished;
}
class IJCmtReplyFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.replyFinished;
}
class IJCmtAddTagFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.addTagFinished;
}
class IJCmtremoveTagFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.removeTagFinished;
}
class IJCmtAddCustomTagFinishedEvent extends IJCmtXFinishedEvent{
   @override EIJCmtEvents event = EIJCmtEvents.addCustomTagFinished;
}

/*

         C O M M E N T    S Y S    S T A T E S

*/
class BaseIJCmtState{

}




