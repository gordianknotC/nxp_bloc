import 'dart:async';
import 'dart:typed_data';

import 'package:nxp_bloc/consts/datatypes.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/models/userauth_model.dart';
import 'package:test/test.dart';

import 'store.dart';


const NFC_DECLAY = 30;
const ERROR_DELAY = 20;
const CMD_DELAY = 10;



class Writers {
   static Future Function(Uint8List record)
   nfcNormal(NFCycleState state) {
      Future writer(Uint8List record) {
         final completer = Completer<bool>();
         Future.delayed(Duration(milliseconds: NFC_DECLAY), () {
            print('\t\tnfCNormal success');
            completer.complete(true);
         });
         return completer.future;
      }
      return writer;
   }
   
   static Future Function(Uint8List record)
   nfcAbnormal(NFCycleState state) {
      Future writer(Uint8List record) {
         final completer = Completer<bool>();
         Future.delayed(Duration(milliseconds: ERROR_DELAY), () {
            print('\t\tnfCAbNormal errors');
            completer.completeError("write ntag exception...");
         });
         return completer.future;
      }
      return writer;
   }
   
   static Future Function(int command)
   cmdNormal(NFCycleState state) {
      Future writer(int command) {
         final completer = Completer<bool>();
         Future.delayed(Duration(milliseconds: CMD_DELAY), (){
            print('\t\tcmdNormal success');
            completer.complete(true);
         });
         return completer.future;
      }
      return writer;
   }
   
   static Future Function(int command)
   cmdAbnormal(NFCycleState state) {
      Future writer(int command) {
         final completer = Completer<bool>();
         Future.delayed(Duration(milliseconds: CMD_DELAY), () {
            print('\t\tcmdAbNormal errors');
            completer.completeError('write command exception...');
         });
         return completer.future;
      }
      return writer;
   }
}

class Readers {
   static Future<Ntag_I2C_Registers> Function()
   nfcNormal(NFCycleState state) {
      Future<Ntag_I2C_Registers> reader() {
         final completer = Completer<Ntag_I2C_Registers>();
         Future.delayed(Duration(milliseconds: NFC_DECLAY), () {
            state.register = Ntag_I2C_Registers.mock();
            completer.complete(state.register);
         });
         return completer.future;
      }
      return reader;
   }
   
   static Future<Ntag_I2C_Registers> Function()
   nfcAbnormal(NFCycleState state) {
      Future<Ntag_I2C_Registers> reader() {
         final completer = Completer<Ntag_I2C_Registers>();
         Future.delayed(Duration(milliseconds: ERROR_DELAY), () {
            completer.completeError('read ntag exception....');
         });
         return completer.future;
      }
      return reader;
   }
   
   static Future<int> Function()
   cmdSuccess(NFCycleState state) {
      int command;
      Future<int> reader() {
         final completer = Completer<int>();
         Future.delayed(Duration(milliseconds: CMD_DELAY), () {
            switch (state.ioState) {
               case EIO.boot:
               case EIO.shutdown:
               case EIO.uop:
               case EIO.urst:
               case EIO.initial:
               case EIO.patrol:
                  command = 0x00;
                  break;
               case EIO.read:
                  break;
              
            }
            completer.complete(command);
         });
         return completer.future;
      }
      return reader;
   }
   
   static Future<int> Function()
   cmdFailed(NFCycleState state) {
      Future<int> reader() {
         final completer = Completer<int>();
         Future.delayed(Duration(milliseconds: CMD_DELAY), () {
            completer.complete(0x22);
         });
         return completer.future;
      }
      return reader;
   }
   
   static Future<int> Function()
   cmdAbnormal(NFCycleState state) {
      Future<int> reader() {
         final completer = Completer<int>();
         Future.delayed(Duration(milliseconds: CMD_DELAY), () {
            completer.completeError('read cmd exception...');
         });
         return completer.future;
      }
      return reader;
   }
}

class BlocGen {
   static NFCIOBloC _initbloc(NFCycleState state, NFCIOBloC bloC) {
      return NFCIOBloC(
          () => Future.value(true),
         nfcWriter: Writers.nfcNormal(state),
         store: StoreImpl('./',),
         commandWriter: Writers.cmdNormal(state),
         nfcReader: Readers.nfcNormal(state),
         commandReader: Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC nfcWriteSucessBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: Writers.nfcNormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: _bloc?.commandReader ?? Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC nfcReadSuccessBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: Readers.nfcNormal(state),
         commandReader: _bloc?.commandReader ?? Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC cmdWriteSuccessBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: Writers.cmdNormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: _bloc?.commandReader ?? Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC cmdReadSuccessBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC nfcWriteFaledBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: Writers.nfcAbnormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: _bloc?.commandReader ?? Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC nfcReadFailedBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: Readers.nfcAbnormal(state),
         commandReader: _bloc?.commandReader ?? Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC cmdWriteFailedBloC(NFCycleState state, [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: Writers.cmdAbnormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: _bloc?.commandReader ?? Readers.cmdSuccess(state),
      );
   }
   
   static NFCIOBloC cmdReadFailedBloC(NFCycleState state, void onFailed(NFCycleState state), [NFCIOBloC _bloc]) {
      final commandReader = Readers.cmdFailed(state);
      final modReader = () {
         onFailed(state);
         return commandReader();
      };
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: modReader,
      );
   }
   
   static NFCIOBloC cmdReadExceptionBloC(NFCycleState state, void onFailed(NFCycleState state), [NFCIOBloC _bloc]) {
      return NFCIOBloC( () => Future.value(true),
         store: StoreImpl('./'),
         nfcWriter: _bloc?.nfcWriter ?? Writers.nfcNormal(state),
         commandWriter: _bloc?.commandWriter ?? Writers.cmdNormal(state),
         nfcReader: _bloc?.nfcReader ?? Readers.nfcNormal(state),
         commandReader: Readers.cmdAbnormal(state),
      );
   }
}

class Users {
   static UserModel createUserByPermission(Permission permission) {
      final token = AuthorizationToken.mock();
      return UserModel()
         ..token = token
         ..permission = permission;
   }
   
   static UserModel get user => createUserByPermission(Permission.user);
   
   static UserModel get engineer => createUserByPermission(Permission.engineer);
   
   static UserModel get admin => createUserByPermission(Permission.administrator);
}

class Matchers{
   static List<Matcher> commandSuccess(Matcher matcher){
      return [
         allOf([
            const TypeMatcher<NFCycleDefault>(),
         ]),
         allOf([
            matcher,
         ]),
         allOf([
            const TypeMatcher<NFCycleWriteCommandSuccess>(), // 1
         ]),
      ];
   }
   static List<Matcher> commandSuccessB(Matcher matcher){
      return [
         allOf([
            const TypeMatcher<NFCycleDefault>(),
         ]),
         allOf([
            matcher,
         ]),
         allOf([
            const TypeMatcher<NFCycleWriteNtagSuccess>(), // 1
         ]),
      ];
   }
   static List<Matcher> readFailed(){
      return [
         allOf([
            const TypeMatcher<NFCycleSuccess>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleLogState>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleReadState>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleInternalError>(),
         ])
      ];
   }

   static List<Matcher> readSuccess(){
      return [
         allOf([
            const TypeMatcher<NFCycleSuccess>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleLogState>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleReadState>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleReadSuccess>(),
         ]),
         allOf([
            const TypeMatcher<NFCycleReadLogState>(),
         ])
      ];
   }
   static List<Matcher> retries(int retries){
      return retries == 0
             ? []
             : List<List<Matcher>>.generate(retries, (i) => [
         allOf([
            const TypeMatcher<NFCycleRetry>(), // 1
         ]),
         allOf([
            const TypeMatcher<NFCycleWriteCommandSuccess>(),
         ]),
      ]).fold([], (all, i){
         return all + i;
      });
   }

   static List<Matcher> retriesB(int retries){
      return retries == 0
             ? []
             : List<List<Matcher>>.generate(retries, (i) => [
         allOf([
            const TypeMatcher<NFCycleRetry>(), // 1
         ]),
         allOf([
            const TypeMatcher<NFCycleWriteNtagSuccess>(),
         ]),
      ]).fold([], (all, i){
         return all + i;
      });
   }
}

class BaseTester {
   static Future wait([int duration = 40]){
      return Future.delayed(Duration(milliseconds: duration));
   }
   
   static Future permissionDenied(NFCIOBloC bloc, { NFCycleState state, TypeMatcher matcher}) async {
      final order = [
         allOf([
            const TypeMatcher<NFCycleDefault>(),
         ]),
         /*allOf([
         
            matcher,
         ]),*/
         allOf([
            const TypeMatcher<NFCyclePermissionDenied>(),
         ]),
      ];
      
      bloc.onDispatch(state);
      await expectLater(bloc.state, emitsInOrder(order));
      await wait(30);
   }
   
   static Future failedWithRetry(NFCIOBloC bloc, {int retries = 0, void onFailed(void cb()), NFCycleState state, TypeMatcher matcher, bool writeNFC =false}) async {
      int counter = 0;
      onFailed?.call(() {
         counter ++;
         if (counter == retries) {
            final _bloc = BlocGen.cmdReadSuccessBloC(state, bloc);
            bloc.actions.commandReader = _bloc.commandReader;
         }
      });

      List<Matcher> order;
      if (!writeNFC){
         order = [
            ...Matchers.commandSuccess(matcher),
            ...Matchers.retries(retries),
            ...Matchers.readFailed(),
         ];
      }else{
         order = [
               ...Matchers.commandSuccessB(matcher),
               ...Matchers.retriesB(retries),
               ...Matchers.readFailed(),
            ];
      }
      bloc.onDispatch(state);
      await expectLater(bloc.state, emitsInOrder(order));
      await wait();
   }

 
   
  
   static Future successWithRetry(NFCIOBloC bloc, {int retries = 0, void onFailed(void cb()), NFCycleState state, TypeMatcher matcher, bool writeNFC = false}) async {
      int counter = 0;
      onFailed?.call(() {
         counter ++;
         if (counter == retries) {
            print('counter == retries: $retries');
            final _bloc = BlocGen.cmdReadSuccessBloC(state, bloc);
            bloc.actions.commandReader = _bloc.commandReader;
         }
      });
      List<Matcher> order;
      if (!writeNFC){
         order = [
            ...Matchers.commandSuccess(matcher),
            ...Matchers.retries(retries),
            ...Matchers.readSuccess(),
         ];
      }else{
         order = [
            ...Matchers.commandSuccessB(matcher),
            ...Matchers.retriesB(retries),
            ...Matchers.readSuccess(),
         ];
      }
      
      
      bloc.onDispatch(state);
      await expectLater(bloc.state, emitsInOrder(order));
      await wait();
   }
}

class UserTester {
}

class EngineerTester {
}

class AdminTester {
}

