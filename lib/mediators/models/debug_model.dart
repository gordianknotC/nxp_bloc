import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:nxp_bloc/mediators/models/validator_model.dart';




class STR {
   static List<int>
   toBytes(String source) {
      return utf8.encode(source);
   }
   static String
   utf8ToBase64(String source) {
      return utf8.fuse(base64).encode(source);
   }
   
   static String
   base64ToUtf8(String source) {
      return utf8.fuse(base64).decode(source);
   }
   
   static String compress(String source) {
      List<int> gzip_bytes, string_bytes;
      string_bytes = utf8.encode(source);
      gzip_bytes = GZipEncoder().encode(string_bytes);
      return base64.encode(gzip_bytes);
   }
   
   static String decompress(String source) {
      /* Every human readable text in Dart, which is user typed/copied text or any text
         show-up on screen, is utf8 by default. For preventing FormatException, which
         is encode/decode error, convert string from utf8 to base64 for any text needs
         to be decode into base64 bytes is necessary.*/
      List<int> gzip_bytes, string_bytes;
      try{
         gzip_bytes = base64.decode(source);
      }on FormatException{
         gzip_bytes = base64.decode(STR.utf8ToBase64(source));
      }
      string_bytes   = GZipDecoder().decodeBytes(gzip_bytes);
      return utf8.decode(string_bytes);
   }
}


abstract class Debuginf implements SerializableModel {
   Map<String, String> data;
   String log;
   String android;
   String devices;
   String descoopts;
   String tags;
   String reason;
}

class DebugModel implements Debuginf {
   @override Map<String, String> data;
   @override String descoopts;
   @override String devices;
   @override String android;
   @override String log;
   @override String tags;
   @override String reason;
   DebugModel.from({String android, String log, String devices, String descopts, String tags, String reason}){
     data = {
        'log': STR.compress(log),
        'devices': STR.compress(devices),
        'descopts': STR.compress(descopts),
        'tags': STR.compress(tags),
        'reason': reason
     };
     descopts = data['descopts'];
     devices = data['devices'];
     android = data['android'];
     tags = data['tags'];
     log = data['log'];
     this.reason = reason;
   }
   
   @override Map<String, String>
   asMap() {
      return data;
   }

  
}