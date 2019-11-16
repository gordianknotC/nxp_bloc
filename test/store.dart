import 'dart:async';
import 'dart:io';

import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';

class StoreStat implements StoreStatInf{
   @override DateTime accessed;
   @override DateTime changed;
   @override int mode;
   @override DateTime modified;
   @override int size;
   StoreStat(FileStat stat){
      accessed = stat.accessed;
      changed = stat.changed;
      mode = stat.mode;
      modified = stat.modified;
      size = stat.size;
   }
}

class StoreImpl implements StoreInf{
   @override String path;
   @override String result;
   StoreImpl(this.path){
      print("init store path: ${getPath()}");
   }
   
   @override String getPath([String pth]) => pth ?? path;
   
   @override Future<bool> existsAsync() {
      return File(getPath()).exists();
   }
   
   @override bool existsSync() {
      return File(getPath()).existsSync();
   }
   
   @override StoreInf open() {
      return this;
   }
   
   @override Future<String> readAsync({bool encrypt = true}) {
      final completer = Completer<String>();
      final path = getPath();
      File(path).readAsString().then((r){
         print('read file:$path');
         print(r);
         result = r;
         completer.complete(r);
      });
      return completer.future;
   }
   
   @override String readSync({bool encrypt = true}) {
      //      return File(getPath()).readAsStringSync();
      throw Exception("method: `readSync` Not Implemented yet");
   }
   void recheck(String content){
      readAsync().then((e){
         print('recheck saved content: ${content.length}, ${e.length}');
         if(content.length != e.length){
            print('real content to be written: \n$e');
         }
      });
   }
   @override Future<StoreInf> writeAsync(String content, {bool encrypt = true}) {
      final completer = Completer<StoreInf>();
      final path = getPath();
      print('writeAsync file:$path');
      print(content);
      File(path).writeAsString(content).then((r){
         print("write: $content");
         completer.complete(this);
         recheck(content);
      });
      return completer.future;
   }
   
   @override void writeSync(String content, {String msg, bool encrypt = true}) {
      final path = getPath();
      print('[$msg] writeSync file:$path');
      print(content);
      final result = File(path).writeAsStringSync(content);
      recheck(content);
      return result;
   }
   
   @override void deleteSync(){
      return File(getPath()).deleteSync();
   }
   
   @override StoreStatInf statSync(){
      return StoreStat(File(getPath()).statSync());
   }
   
   @override Future<StoreStatInf> stat(){
      final completer = Completer<StoreStatInf>();
      File(getPath()).stat().then((result){
         completer.complete(StoreStat(result));
      });
      return completer.future;
   }
   
   @override
   Future<StoreInf> writeAsBytes(List<int> data){
      final completer = Completer<StoreInf>();
      File(getPath()).writeAsBytes(data).then((result){
         completer.complete(this);
      });
      return completer.future;
   }
   
   @override List<int> readAsBytesSync(){
      return File(getPath()).readAsBytesSync();
   }
   
   @override Future<List<int>> readAsBytes(){
      final completer = Completer<List<int>>();
      File(getPath()).readAsBytes().then(completer.complete);
      return completer.future;
   }
   
   @override
   void logNtag({String key, String data}) {
      // TODO: implement logNtag
   }
   
   @override
   List<String> readNtagLog() {
      // TODO: implement readNtagLog
      return null;
   }
   
   @override
   bool encrypt;

  @override
  Future<StoreInf> rename(String path) {
    // TODO: implement rename
   final completer = Completer<StoreInf>();
   File(getPath()).rename(path).then((f) => completer.complete(StoreImpl(f.path)));
   return completer.future;
  }
   
}













