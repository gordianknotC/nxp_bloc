
import 'package:nxp_bloc/consts/datatypes.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';

enum EIOCycleError{
   NFCommunicationError, internalError,
   readCommandError, writeCommandError,
   readNtagError, malformedNtagContent,
   writeNtagError
}

enum EIOCycles{
   retry, failed, success, startup, writeCommandSuccess, readCommandSuccess, log
}

enum EIO{
   patrol,
   uop, // user setup,
   urst, // user reset,
   initial, // admin reset
   read,
   boot,
   shutdown,
}


class NFCycleError{
   EIOCycleError errorType;
   String        message;
   NFCycleError(this.errorType, this.message);
}

class NFCycleState{
   Ntag_I2C_Registers register;
   NtagRawRecord rawRecord;
   NFCycleError error;
   EIOCycles cycleState;
   EIO ioState;
   int counter;
   
   NFCycleState  ({this.counter, this.cycleState = EIOCycles.startup,
                  this.ioState, this.register, this.rawRecord});
   
   void resetCycle(){
      counter = 0;
   }
   
   void update({int counter, EIOCycles cycleState, EIO ioState, NFCycleError error,
                Ntag_I2C_Registers register, NtagRawRecord rawRecord}){
      this.counter 		= counter 	?? this.counter;
      this.cycleState   = cycleState?? this.cycleState;
      this.ioState 		= ioState 	?? this.ioState;
      this.register     = register  ?? this.register;
      this.rawRecord    = rawRecord ?? this.rawRecord;
      this.error        = error     ?? this.error;
   }
}


// ---------------------------------------

class NFCycleWriteCommandMissed extends NFCycleState{
   NFCycleWriteCommandMissed(NFCycleState prev){
      update(
         cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}

class NFCycleWriteCommandSuccess extends NFCycleState{
   NFCycleWriteCommandSuccess(NFCycleState prev){
      update(
         cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}

class NFCycleWriteNtagMissed extends NFCycleState{
   NFCycleWriteNtagMissed(NFCycleState prev){
      update(
         cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}

class NFCycleWriteNtagSuccess extends NFCycleState{
   NFCycleWriteNtagSuccess(NFCycleState prev){
      update(
         cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}
// ---------------------------------------

class NFCycleDefault extends NFCycleState{
   NFCycleDefault();
}

class NFCycleSetState extends NFCycleState{
   NFCycleSetState(NFCycleState prev){
      update(
         cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}

class NFCyclePermissionDenied extends NFCycleState{
   NFCyclePermissionDenied(NFCycleState prev){
      update(
         cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}

class NFCycleLogState extends NFCycleState{
   NFCycleLogState(NFCycleState prev){
      update(
          cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : prev.rawRecord, register: prev.register,
      );
   }
}
class NFCycleReadLogState extends NFCycleState{
   NFCycleReadLogState(NFCycleState prev, NtagRawRecord rawRecord, Ntag_I2C_Registers register){
      update(
          cycleState: EIOCycles.log, ioState: prev.ioState, rawRecord : rawRecord, register: register
      );
   }
}

// ----------------------------------------
//
//                W R I T E ....
//
// -----------------------------------------

class NFCycleInitialState extends NFCycleState{
   NFCycleInitialState(NtagRawRecord record)
      : super(ioState: EIO.initial, counter: 1, rawRecord: record);
}

class NFCycleUopState extends NFCycleState{
   NFCycleUopState(NtagRawRecord record)
      : super(ioState: EIO.uop, counter: 1, rawRecord: record);
}

class NFCycleUresetState extends NFCycleState{
   NFCycleUresetState(NtagRawRecord record)
      : super(ioState: EIO.urst, counter: 1, rawRecord: record);
}

// ----------------------------------------
//
//                R E A D ....
//
// -----------------------------------------

class NFCyclePatrolState extends NFCycleState{
   NFCyclePatrolState(): super(ioState: EIO.patrol, counter: 1);
}

class NFCycleBootState extends NFCycleState{
   NFCycleBootState(): super(ioState: EIO.boot, counter: 1);
}


class NFCycleShutdownState extends NFCycleState{
   NFCycleShutdownState(): super(ioState: EIO.shutdown, counter: 1);
}

class NFCycleReadState extends NFCycleState{
   NFCycleReadState(NFCycleState prev){
      final cycleState = prev == null
         ? EIOCycles.startup
         : EIOCycles.retry;
      update(counter: (prev?.counter ?? -1) + 1, cycleState: cycleState, ioState: prev?.ioState ?? EIO.read);
   }
}


// ---------------------------------------

class NFCycleRetry extends NFCycleState{
   NFCycleRetry(NFCycleState prev){
     update(counter: prev.counter + 1, cycleState: EIOCycles.retry, ioState: prev.ioState,
        register: prev.register, rawRecord: prev.rawRecord, error: prev.error
     );
   }
}

class NFCycleInternalError extends NFCycleState{
   NFCycleInternalError(NFCycleState prev, NFCycleError error){
      update(counter: prev.counter, error: error,
          cycleState: EIOCycles.failed, ioState: prev.ioState);
   }
}

class NFCycleFailed extends NFCycleState{
   NFCycleFailed(NFCycleState prev, NFCycleError error){
      update(counter: prev.counter, error: error,
         cycleState: EIOCycles.failed, ioState: prev.ioState);
   }
}

class NFCycleSuccess extends NFCycleState{
   NFCycleSuccess(NFCycleState prev, NtagRawRecord rawRecord, Ntag_I2C_Registers register){
      update(
         counter: prev.counter, cycleState: EIOCycles.success,
         ioState: prev.ioState, rawRecord : rawRecord, register: register
      );
   }
}

class NFCycleReadSuccess extends NFCycleState{
   NFCycleReadSuccess(NFCycleState prev, NtagRawRecord rawRecord, Ntag_I2C_Registers register){
      update(
          counter: prev.counter, cycleState: EIOCycles.success,
          ioState: prev.ioState, rawRecord : rawRecord, register: register
      );
   }
}

class NFCycleCancel extends NFCycleState{
   NFCycleCancel();
}

