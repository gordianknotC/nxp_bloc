import 'dart:async';
import 'package:PatrolParser/PatrolParser.dart';
import "package:nxp_bloc/consts/datatypes.dart";

enum ActivityEvents {
   onReadRegisterSession,
   onRegisterSessionResponse,
   onNDEFDetected,
   onReadProductInfo,
   onProductInfoResponse,
   
   onNDEFRead,
   onNDEFReadResponse,
   onNDEFReadLost,
   onNDEFReadError,
   onNDEFReadProtected,
   onNDEFTapToRead,
   
   onNDEFWrite,
   onNDEFWriteLost,
   onNDEFWriteError,
   onNDEFWriteResponse,
   onNDEFWriteProtected,
   onNDEFWriteIncorrectContent,
   onNDEFTapToWrite,
   onDataRateUpdate,

   setState
}

class BaseNDEFEvents {
   Ntag_I2C_Registers register;
   NdefFragmentOption ndefOption;
   ProductInfo productInfo;
   ActivityEvents event;
   String rawMessageToBeWritten;
   String message;
}

class NDEFSetStateEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.setState;
}

class ReadProductInfoEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onReadProductInfo;
   ReadProductInfoEvent();
}

class ReadRegisterSessionEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onReadRegisterSession;
   ReadRegisterSessionEvent();
}

class ProductInfoResponseEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onProductInfoResponse;
   @override ProductInfo productInfo;
   
   ProductInfoResponseEvent(this.productInfo);
}

class RegisterSessionResponseEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onRegisterSessionResponse;
   @override Ntag_I2C_Registers register;
   
   RegisterSessionResponseEvent(this.register);
}

class NDEFDetectedResponseEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFDetected;
   @override String message;
   
   NDEFDetectedResponseEvent(this.message);
}

/*
*       R E A D     E V E N T S
*
*/
class NDEFReadEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onNDEFRead;
}
class NDEFReadResponseEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onNDEFReadResponse;
   @override NdefFragmentOption ndefOption;
   
   NDEFReadResponseEvent(this.ndefOption);
}
class NDEFReadLostEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFReadLost;
   @override String message;
   
   NDEFReadLostEvent(this.message);
}
class NDEFReadErrorEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFReadError;
   @override String message;
   
   NDEFReadErrorEvent(this.message);
}
class NDEFReadProtectedEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFReadProtected;
   @override String message;
   
   NDEFReadProtectedEvent(this.message);
}
class NDEFTapToReadEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFTapToRead;
   @override String message;
   
   NDEFTapToReadEvent(this.message);
}

/*
*       W R I T E     E V E N T S
*
*/
class NDEFWriteResponseEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onNDEFWriteResponse;
   @override String message;
   
   NDEFWriteResponseEvent(this.message);
}

class NDEFWriteEvent extends BaseNDEFEvents {
   @override ActivityEvents event = ActivityEvents.onNDEFWrite;
   @override String rawMessageToBeWritten;
   
   NDEFWriteEvent(this.rawMessageToBeWritten);
}

class DataRateUpdateEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onDataRateUpdate;
   @override String message;
   
   DataRateUpdateEvent(this.message);
}

class NDEFWriteLostEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFWriteLost;
   @override String message;
   
   NDEFWriteLostEvent(this.message);
}
class NDEFWriteErrorEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFWriteError;
   @override String message;
   
   NDEFWriteErrorEvent(this.message);
}
class NDEFWriteProtectedEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFWriteProtected;
   @override String message;
   
   NDEFWriteProtectedEvent(this.message);
}
class NDEFTapToWriteEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFTapToWrite;
   @override String message;
   
   NDEFTapToWriteEvent(this.message);
}
class NDEFWriteIncorrectContentEvent extends BaseNDEFEvents{
   @override ActivityEvents event = ActivityEvents.onNDEFWriteIncorrectContent;
   @override String message;
   
   NDEFWriteIncorrectContentEvent(this.message);
}








/*
*
*         S T A T E S
*
*/
class BaseNDEFState {
   static Ntag_I2C_Registers _register;
   static NdefFragmentOption _ndefOption;
   static ProductInfo _productinfo;
   static PatrolRecord _patrol;
   static String _rawMessageReadIn             = "";
   static String _encodedMessageReadIn         = "";
   static String _rawMessageToBeWrittenOut     = "";
   static String _encodedMessageToBEWrittenOut = "";
   
   static String decode(String msg) {
      //fixme:
      return msg ?? "";
   }
   static String encode(String msg) {
      //fixme:
      return msg ?? "";
   }
   
   Ntag_I2C_Registers get register   => _register;
   NdefFragmentOption get ndefOption => _ndefOption;
   ProductInfo        get product    => _productinfo;
   PatrolRecord       get patrol     => _patrol;
   String get rawMessageReadIn         => _rawMessageReadIn;
   String get encodedMessageReadIn     => _encodedMessageReadIn;
   String get rawMessageToBeWrittenOut => _rawMessageToBeWrittenOut;
   String get encodedMessageToBEWrittenOut=> _encodedMessageToBEWrittenOut;

   void set rawMessageReadIn        (String v)    => _rawMessageReadIn = v;
   void set encodedMessageReadIn    (String v)    => _encodedMessageReadIn = v;
   void set rawMessageToBeWrittenOut(String v)    => _rawMessageToBeWrittenOut = v;
   void set encodedMessageToBEWrittenOut(String v)=> _encodedMessageToBEWrittenOut = v;
   void set patrol                (PatrolRecord v)=> _patrol = v;

   String message;
   String getRegister(){
      return _register == null
             ? ""
             : _register.info();
   }
}

class NDEFStateDefault extends BaseNDEFState{

}

class ReadProductInfoState extends BaseNDEFState {}

class RegisterSessionState extends BaseNDEFState {}

class ProductInfoResponseState extends BaseNDEFState{
   ProductInfoResponseState(ProductInfo product){
      BaseNDEFState._productinfo = product;
   }
}
class RegisterSessionResponseState extends BaseNDEFState {
   RegisterSessionResponseState(Ntag_I2C_Registers register) {
      BaseNDEFState._register = register;
   }
}
class NDEFDetectedState extends BaseNDEFState{
   @override String message;
   NDEFDetectedState(this.message);
}

/*
*        R E A D     S T A T E S
*
*/
class ReadNDEFState extends BaseNDEFState {
   ReadNDEFState();
}

class ReadNDEFStateResponse extends BaseNDEFState {
   @override String message;
   
   ReadNDEFStateResponse(NdefFragmentOption ndefOption, this.message) {
      if (message == 'ok' || message == null) {
         BaseNDEFState._ndefOption = ndefOption;
         if (ndefOption.ndefContentBytes?.isNotEmpty ?? false){
            rawMessageReadIn = PatrolRecord.memBytesToByteString(ndefOption.ndefContentBytes);
         }else{
            rawMessageReadIn = ndefOption.ndefText ?? "";
         }
      }
   }
}

class ReadNDEFLostState extends BaseNDEFState{
   @override String message;
   ReadNDEFLostState(this.message);
}

class ReadNDEFErrorState extends BaseNDEFState{
   @override String message;
   ReadNDEFErrorState(this.message);
}

class ReadNDEFProtectedState extends BaseNDEFState{
   @override String message;
   ReadNDEFProtectedState(this.message);
}

class NDEFTapToReadState extends BaseNDEFState{
   @override String message;
   NDEFTapToReadState(this.message);
}


/*
*        W R I T E     S T A T E S
*
*/
class WriteNdefState extends BaseNDEFState {
   @override String rawMessageToBeWrittenOut;
   WriteNdefState(this.rawMessageToBeWrittenOut);
}

class WriteNDEFStateResponse extends BaseNDEFState {
   @override String message;
   WriteNDEFStateResponse(NdefFragmentOption ndefOption, this.message) {
      if (message == 'ok' || message == null)
         BaseNDEFState._ndefOption = ndefOption;
   }
}

class NdefDataRateUpdateState extends BaseNDEFState{
   @override String message;
   NdefDataRateUpdateState(this.message);
}

class WriteNDEFLostState extends BaseNDEFState{
   @override String message;
   WriteNDEFLostState(this.message);
}

class WriteNDEFErrorState extends BaseNDEFState{
   @override String message;
   WriteNDEFErrorState(this.message);
}

class WriteNDEFProtectedState extends BaseNDEFState{
   @override String message;
   WriteNDEFProtectedState(this.message);
}

class NDEFTapToWriteState extends BaseNDEFState{
   @override String message;
   NDEFTapToWriteState(this.message);
}

class WriteNDEFIncorrectState extends BaseNDEFState{
   @override String message;
   WriteNDEFIncorrectState(this.message);
}

class NDEFStateSetState extends BaseNDEFState {
}
