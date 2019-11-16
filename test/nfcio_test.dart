import 'dart:async';

import 'package:common/common.dart';
import 'package:nxp_bloc/consts/datatypes.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:test/test.dart';

import 'nfcio_helper.dart';




NFCIOBloC BLOC;

void _setUpAll(){

}
void _tearDownAll(){

}


void main() {
   group('NFCycleIO test', (){
//      setUpAll   (_setUpAll);
//      tearDownAll(_tearDownAll);
      group('IO test for user', () {
         UserState.currentUser = Users.user;
         NFCIOBloC bloc;
         setUp((){
            bloc?.dispose?.call();
            bloc = null;
         });
         
         tearDown((){
            bloc?.dispose();
         });
         
         test('patrol success-A;', () async {
            final state = NFCyclePatrolState();
            bloc = BlocGen.nfcWriteSucessBloC(state);
            await BaseTester.successWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCyclePatrolState>()
            );
         });
         
         test('patrol success-B; Retry two times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCyclePatrolState();
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 2, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCyclePatrolState>()
            );
         });

         test('patrol success-C; Retry five times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCyclePatrolState();
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCyclePatrolState>());
         });

         // -------------------------------------
         
         test('patrol failed-A with internal exception', () async {
            final state = NFCyclePatrolState();
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state, ),
            );
            await BaseTester.failedWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCyclePatrolState>());
         });

         test('patrol failed-B; Retry 3 times with internal exception', () async {
            final state = NFCyclePatrolState();
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state,
                  BlocGen.cmdReadFailedBloC(state, linked.master, bloc)),
            );
            await BaseTester.failedWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCyclePatrolState>());
         });

         // -------------------------------------
         
         test('engineer config success-A;', () async {
            UserState.currentUser = Users.engineer;
            final state = NFCycleUopState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            await BaseTester.successWithRetry(
               bloc, retries: 0,
               state: state,
               matcher: const TypeMatcher<NFCycleUopState>(),
               writeNFC: true);
         });

         test('engineer config success-B; Retry two times and success', () async {
            UserState.currentUser = Users.engineer;
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleUopState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(
               bloc, retries: 2,
               state: state,
               onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUopState>(),
               writeNFC: true);
         });

         test('engineer config success-C; Retry five times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleUopState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(
               bloc, retries: 5, state: state,
               onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUopState>(),
               writeNFC: true);
         });

         // -------------------------------------
         
         test('engineer Config failed-A with internal exception', () async {
            final state = NFCycleUopState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state, ),
            );
            await BaseTester.failedWithRetry(
               bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleUopState>(),
               writeNFC: true,
            );
         });

         test('engineer config failed-B; Retry 3 times with internal exception', () async {
            final state = NFCycleUopState(NtagRawRecord.mock());
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state,
                  BlocGen.cmdReadFailedBloC(state, linked.master, bloc)),
            );
            await BaseTester.failedWithRetry(bloc, retries: 5, state: state,
               onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUopState>(),
               writeNFC: true,
            );
         });
      }, timeout: Timeout(Duration(seconds: 20)));
      
      group('IO test for engineer - userReset', (){
         NFCIOBloC bloc;
         setUp((){
            UserState.currentUser = Users.engineer;
            bloc?.dispose?.call();
            bloc = null;
         });
   
         tearDown((){
            bloc?.dispose();
         });

         test('UserReset success-A;', () async {
            final state = NFCycleUresetState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state);
            await BaseTester.successWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,
            );
         });

         test('userReset success-B; Retry two times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleUresetState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 2, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,
            );
         });

         test('userReset success-C; Retry five times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleUresetState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         // -------------------------------------

         test('userReset failed-A with internal exception', () async {
            final state = NFCycleUresetState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state, ),
            );
            await BaseTester.failedWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         test('userReset failed-B; Retry 3 times with internal exception', () async {
            final state = NFCycleUresetState(NtagRawRecord.mock());
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state,
                  BlocGen.cmdReadFailedBloC(state, linked.master, bloc)),
            );
            await BaseTester.failedWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         // -------------------------------------

         test('userReset success-A;', () async {
            final state = NFCycleUresetState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            await BaseTester.successWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         test('userReset success-B; Retry two times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleUresetState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 2, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         test('userReset success-C; Retry five times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleUresetState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 5, state: state,
               onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         // -------------------------------------

         test('userReset failed-A with internal exception', () async {
            final state = NFCycleUresetState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state, ),
            );
            await BaseTester.failedWithRetry(bloc, retries: 0,
               state: state,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });

         test('userReset failed-B; Retry 3 times with internal exception', () async {
            final state = NFCycleUresetState(NtagRawRecord.mock());
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state,
                  BlocGen.cmdReadFailedBloC(state, linked.master, bloc)),
            );
            await BaseTester.failedWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleUresetState>(),
               writeNFC: true,);
         });
      });
      
      group('IO test for admin', (){
         NFCIOBloC bloc;
         setUp((){
            UserState.currentUser = Users.admin;
            bloc?.dispose?.call();
            bloc = null;
         });
   
         tearDown((){
            bloc?.dispose();
         });
   
         test('AdminInitial success-A;', () async {
            final state = NFCycleInitialState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state);
            await BaseTester.successWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true
            );
         });
   
         test('AdminInitial success-B; Retry tree times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleInitialState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 3, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true
            );
         });
   
         test('AdminInitial success-C; Retry five times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleInitialState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         // -------------------------------------
   
         test('AdminInitial failed-A with internal exception', () async {
            final state = NFCycleInitialState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state, ),
            );
            await BaseTester.failedWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         test('AdminInitial failed-B; Retry 3 times with internal exception', () async {
            final state = NFCycleInitialState(NtagRawRecord.mock());
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state,
                  BlocGen.cmdReadFailedBloC(state, linked.master, bloc)),
            );
            await BaseTester.failedWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         // -------------------------------------
   
         test('AdminInitial success-A;', () async {
            final state = NFCycleInitialState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            await BaseTester.successWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         test('AdminInitial success-B; Retry two times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleInitialState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 2, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         test('AdminInitial success-C; Retry five times and success', () async {
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            // -------------------------------
            final state = NFCycleInitialState(NtagRawRecord.mock());
            assert(state.rawRecord != null);
            bloc = BlocGen.nfcWriteSucessBloC(state);
            bloc = BlocGen.cmdReadFailedBloC(state, linked.master, bloc);
            await BaseTester.successWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         // -------------------------------------
         test('AdminInitial failed-A with internal exception', () async {
            final state = NFCycleInitialState(NtagRawRecord.mock());
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state, ),
            );
            await BaseTester.failedWithRetry(bloc, retries: 0, state: state,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
   
         test('patrol failed-B; Retry 3 times with internal exception', () async {
            final state = NFCycleInitialState(NtagRawRecord.mock());
            final master = (NFCycleState state){};
            final slave = (void cb()){};
            final linked = FN.linkCoupleByCallback<NFCycleState>(master, slave);
            bloc = BlocGen.nfcWriteSucessBloC(state,
               BlocGen.nfcReadFailedBloC(state,
                  BlocGen.cmdReadFailedBloC(state, linked.master, bloc)),
            );
            await BaseTester.failedWithRetry(bloc, retries: 5, state: state, onFailed: linked.slaveSetter,
               matcher: const TypeMatcher<NFCycleInitialState>(),
               writeNFC: true);
         });
      });
      
      group('advanced admin tests', (){
         NFCIOBloC bloc;
         setUp((){
            UserState.currentUser = Users.admin;
            bloc?.dispose?.call();
            bloc = null;
         });
   
         tearDown((){
            bloc?.dispose();
         });
   
         
      });
      
      group('permission test', (){
         group('perform userReset by normal user', (){
            NFCIOBloC bloc;
            setUp((){
               UserState.currentUser = Users.user;
               bloc?.dispose?.call();
               bloc = null;
            });
   
            tearDown((){
               bloc?.dispose();
            });

            test('UserReset - permission denied;', () async {
               final state = NFCycleUresetState(NtagRawRecord.mock());
               bloc = BlocGen.nfcWriteSucessBloC(state);
               await BaseTester.permissionDenied(bloc, state: state,
                  matcher: const TypeMatcher<NFCycleUresetState>()
               );
            });
         });

         group('perform initial reset by engineer', (){
            NFCIOBloC bloc;
            setUp((){
               UserState.currentUser = Users.engineer;
               bloc?.dispose?.call();
               bloc = null;
            });
   
            tearDown((){
               bloc?.dispose();
            });
   
            test('initial nfc - permission denied;', () async {
               final state = NFCycleInitialState(NtagRawRecord.mock());
               bloc = BlocGen.nfcWriteSucessBloC(state);
               await BaseTester.permissionDenied(bloc, state: state,
                  matcher: const TypeMatcher<NFCycleInitialState>()
               );
            });
         });

         group('perform userReset reset by admin', (){
            NFCIOBloC bloc;
            setUp((){
               UserState.currentUser = Users.admin;
               bloc?.dispose?.call();
               bloc = null;
            });
   
            tearDown((){
               bloc?.dispose();
            });
   
            test('UserReset - success;', () async {
               final state = NFCycleUresetState(NtagRawRecord.mock());
               bloc = BlocGen.nfcWriteSucessBloC(state);
               await BaseTester.successWithRetry(bloc, state: state, retries: 0,
                  matcher: const TypeMatcher<NFCycleUresetState>()
               );
            });
         });
         
      }, timeout: Timeout(Duration(seconds: 320)));
   });
   
}



