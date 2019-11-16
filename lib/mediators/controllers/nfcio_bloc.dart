import 'dart:async';
import 'dart:typed_data';

import 'package:PatrolParser/PatrolParser.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:nxp_bloc/consts/datatypes.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/controllers/permission.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:rxdart/rxdart.dart';

final _D = AppState.getLogger("NIO");



class Debouncer {
	int milliseconds;
	bool active;
	Timer _timer;
	void Function() action;
	
	Debouncer({ this.milliseconds }){
		print('.... init Debouncer...');
		active = false;
	}
	
	void update([int time, void onCompleted()]){
		milliseconds = time ?? milliseconds;
		if (onCompleted == null)
			run(action: action);
		else{
			final prevAction = action;
			run(action: (){
				prevAction();
				onCompleted();
			});
		}
	}
	
	void run({void Function() action, void onError(StackTrace err)}) {
		this.action = action;
		_timer?.cancel();
		if (milliseconds != null){
			active = true;
			_timer = Timer(Duration(milliseconds: milliseconds), (){
				try{
					_timer?.cancel();
					action?.call();
					active = false;
				}catch(e){
					onError?.call(StackTrace.fromString(e.toString()));
					active = false;
					rethrow;
				}
			});
		}
	}
	
	void dispose(){
		active = false;
		_timer?.cancel()	;
	}
	void cancel(){
		active = false;
		_timer?.cancel();
	}
}

class NFCIOActions<R extends Ntag_I2C_Registers, W extends Uint8List> {
	bool properlyWritten = false;
	int Function() cycleTime = () => 200;
	int Function() maxRetries = () => 6;
	NFCIOBloC<R, W> bloc;
	StoreInf store;
	Future<R> Function() nfcReader;
	Future<int> Function() commandReader;
	Future Function(W) nfcWriter;
	Future Function(int) commandWriter;
	bool Function(NFCycleState) onCycleErrorHandler;
	Debouncer debouncer;
	final Future<bool> Function() isNtagConnected;
	NFCIOActions(this.isNtagConnected, {
		this.nfcReader, this.commandWriter, this.nfcWriter, this.maxRetries,
		this.bloc, this.store, this.commandReader, this.cycleTime, this.onCycleErrorHandler
	}){
		debouncer = Debouncer(milliseconds: cycleTime());
		onCycleErrorHandler ??= (state) => true;
	}
	
	String getTimeStamp(){
		final t  = DateTime.now();
		return ImageModel.getTime(t, "/", " ", ":");
		//return '${t.year}/${t.month}/${t.day} ${t.hour}:${t.minute}:${t.second}';
	}
	
	void cancel( ) {
		AppState.unlockUI();
		debouncer.cancel();
		_D('call NFCycleCancel');
	}
	
	void _onReadSuccess(R register, NtagRawRecord rawRecord, NFCycleState prevState, [bool afterRead = false]) {
		NFCycleState state;
		if (rawRecord.data.length >= 21) {
			if (prevState is NFCycleReadState){
				_D('nfcycle read success');
				state = NFCycleReadSuccess(prevState, rawRecord, register);
			} else {
				_D('nfcycle communication success');
				state = NFCycleSuccess(prevState, rawRecord, register);
			}
		} else {
			_D('nfcycle read error');
			state = NFCycleFailed(prevState, NFCycleError(
					EIOCycleError.internalError,
					"malformed nfc format"));
		}
		bloc.onDispatch(state);
	}
	
	
	// called on uop, urst, initial mode
	void _onWriteNFC(NFCycleState prevState, [Object err]){
		if (err != null){
			_D('${prevState.runtimeType} writeNFC error: $err');
			if (onCycleErrorHandler(prevState)){
				final error = NFCycleError(
						EIOCycleError.writeNtagError, Msg.onWriteNtagError );
				final state = NFCycleFailed(prevState, error);
				bloc.onDispatch(state);
			}else{
				// do nothing...., continue the rest of process until reaching maxretries...
				_D('${prevState.runtimeType} writeNFC missed');
				bloc.onDispatch(NFCycleWriteNtagMissed(prevState));
			}
		} else {
			_D('${prevState.runtimeType} writeNFC Success');
			final state = NFCycleWriteNtagSuccess(prevState);
			bloc.onDispatch(state);
		}
	}
	
	// called only on patrol mode
	void _onWriteCommand(NFCycleState prevState, [Object err]) {
		if (err != null) {
			if (onCycleErrorHandler(prevState)){
				_D('${prevState.runtimeType} writeCommand error: $err');
				final error = NFCycleError(
						EIOCycleError.writeCommandError, Msg.onWriteNtagCommandError());
				final state = NFCycleFailed(prevState, error);
				bloc.onDispatch(state);
			}else{
				// do nothing...., continue the rest of process until reaching maxretries...
				bloc.onDispatch(NFCycleWriteCommandMissed(prevState));
			}
		} else {
			_D('${prevState.runtimeType} writeCommand Success');
			final state = NFCycleWriteCommandSuccess(prevState);
			bloc.onDispatch(state);
		}
	}
	
	
	bool isNtagProperlyWritten(NFCycleState prevState){
		// fixme:
		// 1) add a feature to tell if it's already properly written or not
		switch(prevState.ioState){
			case EIO.boot:
			case EIO.shutdown:
			case EIO.read:
			case EIO.patrol:
				return true;
			case EIO.uop:
			case EIO.urst:
			case EIO.initial:
				if (prevState is NFCycleWriteNtagSuccess)
					return true;
				break;
		}
		return false;
	}
	
	void _onReadCommand(int command, NFCycleState prevState, [Object error]) async {
		void _retry(){
			_D('read command retry');
			if (prevState.counter < maxRetries()) {
				final state = NFCycleRetry(prevState);
				bloc.onDispatch(state);
			}else{
				final error = NFCycleError(
						EIOCycleError.NFCommunicationError,
						Msg.onNFCommunicationError());
				bloc.onDispatch(NFCycleFailed(prevState, error));
			}
		}
		final bool hasError = error != null;
		if (hasError) {
			_D('read command error');
			if (onCycleErrorHandler(prevState)){
				final error = NFCycleError(
						EIOCycleError.readCommandError, Msg.onReadNtagCommandError());
				final state = NFCycleFailed(prevState, error);
				bloc.onDispatch(state);
			}else{
				_retry();
			}
		} else {
			if (command == 0x00) {
				// fixme:
				// 1) while ntag connected
				// 2) while ntag is properly written
				final isConnected 			= await isNtagConnected();
				final isProperlyWritten = properlyWritten;
				_D('read command isConnected: $isConnected, isProperlyWritten: $isProperlyWritten, prevState: ${prevState.runtimeType}');
				if (isProperlyWritten && isConnected){
					_D('read command success');
					bloc.onDispatch(NFCycleSuccess(prevState, null, null));  // success
					if (prevState.rawRecord?.data != null) {
					} else {
						assert(prevState.ioState == EIO.patrol || prevState.ioState == EIO.shutdown || prevState.ioState == EIO.boot);
						prevState.rawRecord = NtagRawRecord.empty();
						prevState.rawRecord.data[20] = 0x01;
					}
					bloc.onDispatch(NFCycleLogState(prevState )); 					 // log for EIOMode
					bloc.onDispatch(NFCycleReadState(prevState));            // read
				}else{
					_D.debug('get valid result from read command but ntag not present detected, retry again');;
					_retry();
				}
			} else {
				_D.debug('get $command as result from read command, retry again');
				_retry();
			}
		}
	}
	
	// only applied on uop, urst, initial....
	Future writeWholeTag(NFCycleState prevState) async {
		int command;
		switch (prevState.ioState) {
			case EIO.uop:
				command = 0x02;
				break;
			case EIO.urst:
				command = 0x03;
				break;
			case EIO.initial:
				command = 0x04;
				break;
			case EIO.patrol:
			case EIO.boot:
			case EIO.shutdown:
			case EIO.read:
				throw Exception('${prevState.ioState} is not a valid enum for writeWholeTag');
				break;
		}
		final data = prevState.rawRecord.data;
		data[20] = command;
		_D('write nfc content with command bytes: $command');
		return nfcWriter(data as W);
	}
	
	// only applied on patrol, boot, and shutdown...
	Future writeCommandBytesOnly(NFCycleState prevState) async {
		int command;
		switch (prevState.ioState) {
			case EIO.patrol:
				command = 0x01;
				break;
			case EIO.boot:
				command = 0x05;
				break;
			case EIO.shutdown:
				command = 0x06;
				break;
			case EIO.uop:
			case EIO.urst:
			case EIO.initial:
			case EIO.read:
				throw Exception('${prevState.ioState} is not a valid enum for writeCommandBytesOnly');
				break;
		}
		_D('write - command bytes: $command');
		return commandWriter(command);
	}
	
	Future writeCommandForRead(NFCycleState prevState) async {
		_D('writeCommandForRead, ${prevState.ioState}, rawRecord: ${prevState.rawRecord}');
		Future Function(NFCycleState p) nfcCommandWriter;
		
		switch (prevState.ioState) {
			case EIO.boot:
			case EIO.shutdown:
			case EIO.patrol:
				nfcCommandWriter = writeCommandBytesOnly;
				break;
			case EIO.uop:
			case EIO.urst:
			case EIO.initial:
				nfcCommandWriter = writeWholeTag;
				break;
			case EIO.read:
				throw Exception('EIO for read is not a valid enum for writeCommand');
				break;
		}
		
		// first run
		await nfcCommandWriter(prevState).then((e) {
			if (nfcCommandWriter == writeCommandBytesOnly)
				_onWriteCommand(prevState, e == true ? null : 'write command failed');
			else
				_onWriteNFC(prevState, e == true ? null : 'write nfc failed');
			// run later
			debouncer.run(
					action:(){
						_D('writeCommandForRead - read command, rawRecord: ${prevState.rawRecord}');
						commandReader().then((command) {
							_onReadCommand(command, prevState);
						}).catchError((e) {
							_D('			read command error: $e');
							_onReadCommand(null, prevState, e);
						});
					},
					onError: (e){
						_D('			read command error: $e');
						_onReadCommand(null, prevState, e);
					});
		}).catchError((e) {
			if (nfcCommandWriter == writeCommandBytesOnly) {
				_D('			write command error: $e');
				if (prevState.counter == 1)
					_onWriteCommand(prevState, e);
				else
					_onReadCommand(null, prevState, e);
			}
			else													{
				_D('			write nfc error: $e');
				if (prevState.counter == 1)
					_onWriteNFC(prevState, e);
				else
					_onReadCommand(null, prevState, e);
			}
		});
		
		
	}
	
	NFCycleState
	readSuccess(NFCycleState state) {
		AppState.unlockUI();
		bloc.onDispatch(NFCycleReadLogState(state, state.rawRecord, state.register));
		return state;
	}
	
	NFCycleState
	read(NFCycleState state) {
		AppState.lockUI();
		_D('nfcyle read content');
		// read status from nfc
		nfcReader().then((reg) {
			if (reg != null && reg.errorMessage == null) {
				final record = reg.NDEF_RAW_RECORD;
				_D("onReadEEPROM, re-read success! ${reg}");
				final register  = reg;
				final rawRecord = record;
				
				_onReadSuccess(register, rawRecord, state, true);
			} else {
				_D("onReadEEPROM with unexpected result");
				final error = NFCycleError(
						EIOCycleError.malformedNtagContent, Msg.onMalformedNtagContent());
				bloc.onDispatch(NFCycleFailed(state, error));
			}
		}).catchError((e, s) {
			_D("read nfc content failed: ${e}\n$s");
			final error = NFCycleError(
					EIOCycleError.internalError, Msg.onReadNtagError());
			bloc.onDispatch(NFCycleInternalError(state, error));
		});
		return state;
	}
	
	NFCycleInitialState
	initial(NFCycleInitialState state) {
		AppState.lockUI();
		_D('initial');
		writeCommandForRead(state);
		return state;
	}
	
	NFCycleUopState
	userConfig(NFCycleUopState state) {
		AppState.lockUI();
		_D('userConfig');
		assert(state.ioState == EIO.uop);
		writeCommandForRead(state);
		return state;
	}
	
	NFCycleUresetState
	userReset(NFCycleUresetState state) {
		AppState.lockUI();
		_D('userReset');
		writeCommandForRead(state);
		return state;
	}
	
	NFCyclePatrolState
	patrol(NFCyclePatrolState state) {
		AppState.lockUI();
		_D('patrol');
		writeCommandForRead(state);
		return state;
	}
	
	NFCycleBootState
	boot(NFCycleBootState state) {
		AppState.lockUI();
		_D('boot');
		writeCommandForRead(state);
		return state;
	}
	
	NFCycleShutdownState
	shutdown(NFCycleShutdownState state) {
		AppState.lockUI();
		_D('shutdown');
		writeCommandForRead(state);
		return state;
	}
	
	// ---------------------------
	
	NFCycleRetry retry(NFCycleRetry state) {
		_D('retry, counter: ${state.counter}');
		switch (state.ioState) {
			case EIO.patrol:
			case EIO.boot:
			case EIO.shutdown:
			case EIO.uop:
			case EIO.urst:
			case EIO.initial:
				writeCommandForRead(state);
				break;
			case EIO.read:
				throw Exception('EIO for read is not a valid enum for retying process');
				break;
		}
		return state;
	}
	
	NFCycleFailed failed(NFCycleFailed state) {
		AppState.unlockUI();
		return state;
	}
	
	NFCycleSuccess success(NFCycleSuccess state) {
		AppState.unlockUI();
		
		return state;
	}
}

/// notice: singleton
class NFCIOBloC<R extends Ntag_I2C_Registers, W extends Uint8List>
		extends Bloc<NFCycleState, NFCycleState> {
	static bool disableGuard = false;
	static NFCIOBloC instance;
	
	StreamTransformer<NFCycleState, NFCycleState> authTransformer;
	NFCIOAuthGuard<NFCycleState> authGuard;
	NFCycleState lastState;
	NFCIOActions actions;
	Future<R> Function() nfcReader;
	Future Function(W) nfcWriter;
	Future Function(int) commandWriter;
	Future<int> Function() commandReader;
	bool Function(NFCycleState) onCycleErrorHandler;
	StoreInf store;
	
	NFCIOBloC(Future<bool> Function() isNtagConnected, {
		@required this.nfcReader, @required this.nfcWriter, @required this.commandReader,
		@required this.commandWriter, @required this.store, int maxRetries() , int cycleTime() ,
		this.onCycleErrorHandler,
	}) {
		maxRetries ??= () => 6;
		cycleTime ??= () => 200;
		authGuard = NFCIOAuthGuard();
		actions = NFCIOActions<R, W>(
			isNtagConnected,
			onCycleErrorHandler: onCycleErrorHandler,
			nfcReader: nfcReader,
			commandReader: commandReader,
			commandWriter: commandWriter,
			nfcWriter: nfcWriter,
			store: store,
			maxRetries: maxRetries,
			cycleTime: cycleTime,
		);
		actions.bloc = this;
		instance = this;
	}
	
	factory NFCIOBloC.singleton(Future<bool> Function() isNtagConnected, {
		@required Future<R> Function() nfcReader,			  @required Future Function(W) nfcWriter,
		@required Future<int> Function() commandReader, @required Future Function(int) commandWriter,
		@required StoreInf store, int maxRetries() , int cycleTime(),  bool Function(NFCycleState) onCycleErrorHandler,
	}){
		if (instance == null){
			maxRetries ??= () => 6;
			cycleTime ??= () => 200;
			return instance = NFCIOBloC( isNtagConnected,
					nfcReader: nfcReader, nfcWriter: nfcWriter, commandReader: commandReader, onCycleErrorHandler: onCycleErrorHandler,
					commandWriter: commandWriter, store: store, maxRetries: maxRetries, cycleTime: cycleTime
			) as NFCIOBloC<R, W>;
		}
		
		return instance as NFCIOBloC<R, W>;
	}
	
	@override
	NFCycleState get initialState {
		return NFCycleDefault();
	}
	
	@override void onError(Object error, StackTrace stacktrace) {
		final str = "onError: $error\n${stacktrace.toString()}";
		throw Exception(str);
	}
	
	@override
	Stream<NFCycleState> transform(Stream<NFCycleState> events,
			Stream<NFCycleState> Function(NFCycleState event) next) {
		try {
			if (disableGuard)
				return super.transform(events, next);
			return super.transform((events as Observable<NFCycleState>)
					.where((e) =>
					authGuard.guard(e, onBlock: () {
						final state = NFCyclePermissionDenied(lastState);
						onDispatch(state);
					})), next
			);
		} catch (e) {
			throw Exception(
					'transform failed: \n${StackTrace.fromString(e.toString())}');
		}
	}
	
	bool isBusy() {
		bool result;
		if (AppState.IOMode == EIO.patrol || AppState.IOMode == EIO.shutdown || AppState.IOMode == EIO.boot)
			result = currentState is NFCycleInitialState
					|| currentState is NFCycleUopState
					|| currentState is NFCycleUresetState
					|| currentState is NFCyclePatrolState
					|| currentState is NFCycleBootState
					|| currentState is NFCycleShutdownState
					|| currentState is NFCycleReadState
					|| currentState is NFCycleRetry
					|| currentState is NFCycleWriteCommandSuccess
					|| currentState is NFCycleWriteCommandMissed;
		else
			result = currentState is NFCycleInitialState
					|| currentState is NFCycleUopState
					|| currentState is NFCycleUresetState
					|| currentState is NFCyclePatrolState
					|| currentState is NFCycleBootState
					|| currentState is NFCycleShutdownState
					|| currentState is NFCycleReadState
					|| currentState is NFCycleRetry
					|| currentState is NFCycleWriteCommandSuccess
					|| currentState is NFCycleWriteCommandMissed
					|| currentState is NFCycleWriteNtagMissed;
		
		_D('isBusy: $result, ${currentState.runtimeType}');
		return result;
	}
	
	@override
	Stream<NFCycleState> mapEventToState(NFCycleState st) async* {
		// TODO: implement mapEventToState
		NFCycleState result = st;
		lastState = currentState;
		switch (st.runtimeType) {
			case NFCycleInitialState:
				actions.properlyWritten = false;
				result = actions.initial(st as NFCycleInitialState);
				break;
			case NFCycleUopState:
				actions.properlyWritten = false;
				result = actions.userConfig(st as NFCycleUopState);
				break;
			case NFCycleUresetState:
				actions.properlyWritten = false;
				result = actions.userReset(st as NFCycleUresetState);
				break;
			case NFCycleBootState:
				actions.properlyWritten = true;
				result = actions.boot(st as NFCycleBootState);
				break;
			case NFCycleShutdownState:
				actions.properlyWritten = true;
				result = actions.shutdown(st as NFCycleShutdownState);
				break;
			case NFCyclePatrolState:
				actions.properlyWritten = true;
				result = actions.patrol(st as NFCyclePatrolState);
				break;
			case NFCycleReadState:
				actions.properlyWritten = true;
				result = actions.read(st as NFCycleReadState);
				break;
			case NFCycleRetry:
				result = actions.retry(st as NFCycleRetry);
				break;
			case NFCycleFailed:
				result = actions.failed(st as NFCycleFailed);
				break;
			case NFCycleSuccess:
				result = actions.success(st as NFCycleSuccess);
				break;
			case NFCycleCancel:
				actions.properlyWritten = false;
				actions.cancel( );
				break;
			case NFCycleWriteNtagSuccess:
				actions.properlyWritten = true;
				break;
			case NFCycleSetState:
			case NFCycleDefault:
			case NFCycleInternalError:
			case NFCycleWriteCommandSuccess:
			case NFCycleWriteCommandMissed:
			case NFCycleLogState:
			case NFCycleReadLogState:
			case NFCycleWriteNtagMissed:
			case NFCyclePermissionDenied:
				break;
			case NFCycleReadSuccess:
				result = actions.readSuccess(st as NFCycleReadSuccess);
				break;
			default:
				throw Exception('Uncaught state: ${st.runtimeType}');
		}
		_D('yield: ${result.runtimeType}');
		yield result;
	}
	
	void onDispatch(NFCycleState state) {
		_D('dispatch: ${state.runtimeType}');
		dispatch(state);
	}
}



