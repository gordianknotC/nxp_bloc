

import 'dart:async';
import 'dart:io';
import 'package:common/common.dart';
import 'package:http/http.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:common/src/common.log.dart' show LoggerSketch;
import 'package:nxp_bloc/mediators/sketch/store.dart';



abstract class AppConfigInf{
   int history;
   String clientid;
   String clientsecret;
   String directory;
   AppConfigInf(this.directory);
}

abstract class DatabaseInf{
   String host;
   int port;
   String databaseName;
   String username;
   String password;
}

abstract class AssetsInf {
   String resized_path;
   String basepath;
   String journal_path;
   int size;
}

abstract class ConfigInf<P extends AppConfigInf, D, A extends AssetsInf> {
   P app;
   A assets;
   D database;
}


typedef TLogWriter = void Function(Object o, bool newline);

typedef TShowToast = void Function({
String msg, int toastLength, int gravity, int timeInSecForIos,
int normalBgColor, int errBgColor, int textColor, double fontSize, bool error
});


abstract class NxpInjector {
   Injector _injector;
   ConfigInf configImpl;
   LoggerSketch logImpl;
   TShowToast toastImpl;
   TLogWriter logWriterImpl;
   StoreInf    store;

}

abstract class CacheSketch{
   DateTime time;
   Dio.Response value;
   bool get outdated;
   void     set(Dio.Response v);
   Dio.Response get();
}

abstract class QCacheSketch{
   Map<String, CacheSketch> cache = {};
   Dio.Response get(String key);
   void     set(String key, Dio.Response vaue);
   void     clearKeysContains(String key);
}

abstract class HttpSketch{
   Map<String, String> query;
   Uri request_uri;
   String get base_url;

   void Function(int statuscode) _onFailed  = (code) => null;
   void Function()               _onSuccess = () => null;
   void Function()          _onNetAvailable = () => null;
   void Function()        _onNetUnavailable = () => null;
   bool Function()               _onHttp    = () => true;

   HttpSketch({String host, int port});

   void onFailed(void cb(int statuscode)){
      _onFailed = cb;
   }

   void onSuccess(void cb()){
      _onSuccess = cb;
   }

   void onHttp(bool cb()){
      _onHttp = cb;
   }

   void onNetworkAvailable(void cb()){
      _onNetAvailable = cb;
   }

   void onNetworkUnavailable(void cb()){
      _onNetUnavailable = cb;
   }


   Future<bool> testNetwork();

   Future<Response> get(String pth, {
      Map<String, String> headers, Map<String, dynamic> qparam, String contentType});

   Future<Response> post(String pth, {
      Map<String, String> headers, dynamic body, String contentType});

   Future<Dio.Response> dioMultiPost(String pth, {
      Map<String, String> headers,     Map<String, dynamic> data,
      onReceive(int send, int total),  TwoDBytes binary_data,
      int progressSteps = 75,          String contentType,     onSend(int send, int total)});

   Future<Dio.Response> dioGet(String pth, {
      Map<String, String> headers, Map<String, dynamic> qparam,
      String contentType, bool isCached = false});

   Future<Dio.Response> dioPost(String pth, {
      Map<String, String> headers, dynamic body, String contentType});

}



