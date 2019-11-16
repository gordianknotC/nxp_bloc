import 'dart:convert';
import 'dart:async';


import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:common/common.dart' show ELevel, FN, LEVELS, Logger, TwoDBytes, guard, LoggerSketch;
import 'package:nxp_bloc/mediators/sketch/store.dart';

const JsonCodec json = JsonCodec();


Map<String, dynamic> requestGuard(Map<String, dynamic> cb()) {
   return guard<Map<String, dynamic>>
      (cb, "ParseError", raiseOnly: false, error: "RequestParseError");
}
void postGuard(void cb()) {
   guard(cb, "ArgumentError", raiseOnly: false, error: 'PostArgError');
}

enum EPlatform {
   web, flutter, server
}

//fixme:
// Injection should be platform dependant, which means each platform should
// hold a dependency injector with different implementation . In other
// words, Injection here should provides a programming sketch to user for
// telling what should be contained in injector;


class Injection implements NxpInjector{
   @override ConfigInf<AppConfigInf, dynamic, AssetsInf> configImpl;
   @override LoggerSketch logImpl;
   @override TLogWriter logWriterImpl;
   @override TShowToast toastImpl;
   @override StoreInf store;
   
   static bool initialized = false;
   static Injector _injector;
   static Injector get injector {
      return _injector;
   }
   
   static T get<T>() =>
      _injector.get<T>();
   
   static Future initialize({ ConfigInf config, TShowToast toast, TLogWriter writer, LoggerSketch log}) async {
      if (initialized)
         return;
      final injection = Injection()
         ..logImpl       = log
         ..logWriterImpl = writer
         ..toastImpl     = toast
         ..configImpl    = config;
      _injector = Injector.getInjector();
      
      _injector.map<Injection>   ((i) => injection,            isSingleton:  true);
      _injector.map<ConfigInf>   ((i) => injection.configImpl, isSingleton: true);
      _injector.map<TShowToast>  ((i) => injection.toastImpl,  isSingleton: true);
      _injector.map<TLogWriter>  ((i) => injection.logWriterImpl, isSingleton: true);
      _injector.map<LoggerSketch>((i) => injection.logImpl,    isSingleton: true);
      _injector.map<StoreInf>    ((i) => injection.store,      isSingleton: true);
      initialized = true;
   }

}



















