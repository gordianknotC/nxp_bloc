
import 'dart:convert';
import 'package:dio/dio.dart' as Dio;

class ContentTypes {
   static String formX = "application/x-www-form-urlencoded; boundary=1103jqp";
   static String formM = "multipart/form-data; boundary=1103jqp";
   static String json = "application/json";
   static String form = "application/x-www-form-urlencoded";
}


class SuccessResponse {
   int statusCode = 200;
   Map<String, dynamic> body;
   
   void fromMap(Map<String, dynamic> body) {
      this.body = body;
   }
   Map<String,dynamic> asMap(){
      return{
         'statusCode': statusCode,
         'body': body,
      };
   }
}

class FailureResponse {
   int statusCode;
   String message;
   Map<String, dynamic> body;
   
   void fromMap(Map<String, dynamic> body, int statusCode, String message) {
      this.body = body;
      this.statusCode = statusCode;
      this.message = message;
   }
   Map<String,dynamic> asMap(){
      return{
         'statusCode': statusCode,
         'body': body,
         'message': message
      };
   }
}

class ConflictResponse {
   int statusCode = 409;
   Map<String, dynamic> body;
   
   void fromMap(Map<String, dynamic> body) {
      this.body = body;
   }
   Map<String,dynamic> asMap(){
      return{
         'statusCode': statusCode,
         'body': body,
      };
   }
}

class MultiResponse<T> {
   static String SUCCESS = 'success';
   static String FAILED = 'faield';
   static String CONFLICT = 'conflict';
   
   List<SuccessResponse> success = [];
   List<FailureResponse> failed = [];
   List<ConflictResponse> conflict = [];
   
   void fromMap(Map<String, dynamic> data, [int statusCode, String message]) {
      if (data[SUCCESS] != null) {
         final response = data[SUCCESS] as Map<String,dynamic>;
         final body = SuccessResponse()..fromMap(response);
         success.add(body);
      }
      if (data[FAILED] != null) {
         final response = data[SUCCESS] as Map<String,dynamic>;
         final body = FailureResponse()..fromMap(response, statusCode, message);
         failed.add(body);
      }
      if (data[CONFLICT] != null) {
         final response = data[SUCCESS] as Map<String,dynamic>;
         final body = ConflictResponse()..fromMap(response);
         conflict.add(body);
      }
   }
   
   Map<String,dynamic> asMap() {
      return {
         SUCCESS  : success.map ((s) => s.asMap()).toList(),
         FAILED   : failed.map  ((f) => f.asMap()).toList(),
         CONFLICT : conflict.map((c) => c.asMap()).toList()
      };
   }
   
   void addSuccess(Map<String, dynamic> data) {
      success.add(SuccessResponse()
         ..fromMap(data));
   }
   
   void addFailure(Map<String, dynamic> data, int statusCode, String message) {
      failed.add(FailureResponse()
         ..fromMap(data, statusCode, message));
   }
   
   void addConflict(Map<String, dynamic> data) {
      conflict.add(ConflictResponse()
         ..fromMap(data));
   }
   
   static bool isMember(Map<String,dynamic> data){
      if (data is Map<String,dynamic>){
         final S = data[SUCCESS];
         final F = data[FAILED];
         final C = data[CONFLICT];
         return (S is Map<String,dynamic> && F is Map<String,dynamic> && C is Map<String,dynamic>
                ) && (
                   F.containsKey('message') && F.containsKey('statusCode') && F.containsKey('body')
                ) && (
                   C.containsKey('body') && C.containsKey('statusCode')
                   && S.containsKey('body')
                );
      }
      return false;
   }
}



class MultipartForm {
   Map<String, String> fields = {};
   List<Dio.UploadFileInfo> files = [];
   
   MultipartForm.from({this.fields, this.files});
   
   Map<String,dynamic> asMap(){
      //fixme: prone-error, seems unused??
      final result = <String,dynamic>{};
      fields.forEach((k, v){
         final obj = v;
         result[k] = obj;
      });
      return result;
   }
}


/*class MultipartForm {
   Map<String, String> fields       = {};
   List<Dio.UploadFileInfo> files   = [];
   
   MultipartForm.from({this.fields, this.files});

   String parseField(String key, dynamic value){
      if (key == 'created' || key == 'modified'){
         return value as String;
      }else if (value is String && value.isEmpty){
         return "";
      }else{
         if (value is String){
            return value;
         }else{
            try {
               return jsonEncode(value);
            } catch (e, s) {
               print('[ERROR] IJFormDataParser.parseField failed: $e\n$s\n'
                   'value: $value');
               rethrow;
            }
         }
      }
   }
   
   Map<String,dynamic> asMap(){
      final result = <String,dynamic>{};
      fields.forEach((k, v){
         try {
            result[k] = parseField(k, v);
         } catch (e, s) {
            print('[ERROR] MultipartForm.asMap, encode json failed: $e\n$s\n'
                'k: $k, v: $v');
            rethrow;
         }
      });
      return result;
   }
}*/
