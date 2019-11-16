import 'package:common/common.dart';
import 'package:nxp_bloc/mediators/models/model_error.dart';
import 'package:nxp_bloc/consts/messages.dart';
import 'package:email_validator/email_validator.dart';


abstract class ValidationInf<T> {
   String model_field;
   String source_field;
   String _errormessage;
   
   String get errormessage => _errormessage;
   final bool _notNullViolation = true;
   
   void reset([String message]) {
      _errormessage = message;
   }
   
   String errorMessageGetter(T value);
   
   bool matcher(T source, T value);
   
   bool validate(T value, List<Map<String, dynamic>> source);
   
   ValidationInf(this.model_field, this.source_field);
   
}

abstract class SerializableModel {
   Map<String, dynamic> asMap();
   
   SerializableModel.from();
}


class BaseGroupValidation<T> implements ValidationInf<T> {
   @override String model_field;
   @override String source_field;
   @override String _errormessage;
   
   @override String get errormessage => _errormessage;
   @override final bool _notNullViolation = false;
   
   BaseGroupValidation(this.model_field, this.source_field);
   
   @override void reset([String message]) {
      _errormessage = message;
   }
   
   @override String errorMessageGetter(T value) {
      return Msg.onUniqueValidatioError(model_field, value);
   }
   
   // true for passing validation
   @override bool matcher(T source, T value) => source != value || source == null;
   
   // return true for passed, false for errors
   @override bool validate(T value, List<Map<String, dynamic>> source) {
      reset();
      if (value == null && _notNullViolation == true) {
         _errormessage = 'field:$model_field not null violation';
         return false;
      }
      if (source != null) {
         final hasserror = source.any((rec) => matcher(rec[source_field] as T, value) == false);
         if (hasserror) {
            _errormessage = errorMessageGetter(value);
            return false;
         }
      }
      return true;
   }
}

class BaseSingleValidation<T> extends BaseGroupValidation<T>{
  BaseSingleValidation(String model_field, String source_field) : super(model_field, source_field);
  @override bool validate(T value, List<Map<String, dynamic>> source) {
     reset();
     if (value == null && _notNullViolation == true) {
        _errormessage = 'field:$model_field not null violation';
        return false;
     }
     if (!matcher(null, value)) {
        _errormessage = errorMessageGetter(value);
        return false;
     }
     return true;
  }
}

class EmailValidation<T extends String> extends BaseSingleValidation<T> {
   static RegExp reg = RegExp('');
   @override String model_field;
   @override String source_field;
   @override final bool _notNullViolation = true;
   
   EmailValidation(this.model_field, this.source_field) :super(model_field, source_field);
   
   @override String errorMessageGetter(T value) {
      return Msg.onEmailValidationError(model_field, value);
   }
   
   @override bool matcher(T source, T value) {
      return EmailValidator.validate(value)
             && (source != value || source == null);
   }
}

class UniqueValiation<T> extends BaseGroupValidation<T> {
   @override String model_field;
   @override String source_field;
   @override final bool _notNullViolation = false;
   
   UniqueValiation(this.model_field, this.source_field) :super(model_field, source_field);
}

class SolidUniqueValiation<T> extends BaseGroupValidation<T> {
   @override String model_field;
   @override String source_field;
   @override bool _notNullViolation = true;
   
   SolidUniqueValiation(this.model_field, this.source_field) :super(model_field, source_field);
}

class LengthValidation<T extends String> extends BaseSingleValidation<T> {
   static RegExp reg = RegExp('');
   @override String model_field;
   @override String source_field;
   @override bool _notNullViolation = true;
   int left;
   int right;
   
   LengthValidation(this.model_field, this.source_field, {this.left, this.right}) :super(model_field, source_field);
   
   @override String errorMessageGetter(T value) {
      return Msg.validationLengthInRange(left, right, value.length);
      return 'expect length of $left ~ $right, got ${value.length}';
   }
   
   @override bool matcher(T source, T value) {
      if (value == null)
         return false;
      final l = value.length;
      return l > left && l < right;
   }
}

class DateValidation<T extends String> extends BaseSingleValidation<T> {
   static RegExp reg = RegExp('');
   @override String model_field;
   @override String source_field;
   @override bool _notNullViolation = true;

   DateValidation(this.model_field, this.source_field) :super(model_field, source_field);
   
   @override String errorMessageGetter(T value) {
      return 'not a valid date format';
   }
   
   @override bool matcher(T source, T value) {
      if (value == null)
         return false;
      final time = DateTime.tryParse(value);
      return time != null;
   }
}


class RangeValidation<T extends int> extends BaseSingleValidation<T> {
   static RegExp reg = RegExp('');
   @override String model_field;
   @override String source_field;
   @override bool _notNullViolation = true;
   List<int> range;
   
   RangeValidation(this.model_field, this.source_field, this.range) :super(model_field, source_field);
   
   @override String errorMessageGetter(T value) {
      return 'not a valid date format';
   }
   
   @override bool matcher(T source, T value) {
      if (value == null)
         return false;
      return value >= range[0] && value <= range[1];
   }
   
   setRange(List<int> range){
      this.range = range;
   }
}

class TypeValidation<E> extends BaseSingleValidation<E> {
   static RegExp reg = RegExp('');
   @override String model_field;
   @override String source_field;
   @override bool _notNullViolation = true;
   List<int> range;

   TypeValidation(this.model_field, this.source_field) :super(model_field, source_field);
   
   @override String errorMessageGetter(E value) {
      return 'not a valid date format';
   }
   
   @override bool matcher(E source, dynamic value) {
      if (value == null)
         return false;
      return value is E;
   }
}


//untested:
class HybridValidator<T> implements ValidationInf<T> {
   List<BaseGroupValidation<T>> validators;
   
   HybridValidator(this.validators);
   
   @override String get errormessage {
      final errors = validators.where((v) => v.errormessage != null);
      return errors.isNotEmpty
             ? errors.map((v) => v.errormessage).join('\n')
             : null;
   }
   
   @override String get model_field {
      return validators.first.model_field;
   }
   
   @override void set model_field(String _model_field) {
      validators.forEach((v) => v.model_field = _model_field);
   }
   
   @override String _errormessage;
   @override bool _notNullViolation;
   @override String source_field;
   
   @override String errorMessageGetter(T value) {
      return validators.map((v) => v.errorMessageGetter(value)).join('\n');
   }
   
   @override bool matcher(T source, T value) {
      return validators.every((v) => v.matcher(source, value) == true);
   }
   
   @override
   void reset([String message]) {
      //fixme:
      // final messages = message.split('\n');
      validators.forEach((v) => v.reset(message));
   }
   
   @override
   bool validate(T value, List<Map<String, dynamic>> source) {
      validators.forEach((v) => v.validate(value, source));
      return validators.every((v) => v.errormessage == null);
   }
   
   
   
}



class ValidateMessage {
   String field_name;
   String message;
   
   ValidateMessage([this.field_name, this.message]);
}

class ModelValidator implements SerializableModel {
   List<Map<String, dynamic>> _source;
   List<ValidationInf> validators;
   bool hasValidationErrors = false;
   
   
   Iterable<ValidateMessage> get validationErrors {
      return validators.where((v) => v.errormessage != null)
         .map((v) => ValidateMessage(v.model_field, v.errormessage));
   }
   
   void setSource(List<Map<String, dynamic>> source) {
      _source = source;
   }
   
   void validate(List<Map<String, dynamic>> source) {
      final modelmap = asMap();
      final sourcemap = _source = source;
      hasValidationErrors = false;
      validators.forEach((validator) {
         final model_value = modelmap[validator.model_field];
         if (!validator.validate(model_value, sourcemap)) {
            hasValidationErrors = true;
         }
      });
   }
   
   void writeValidation(Map<String, dynamic> data) {
      final errors = <String,dynamic>{};
      if (_source == null) {
         throw Exception('validation not initialized yet, please invoke validate first');
      }
      if (hasValidationErrors) {
         data[ResponseConst.ERR_CONTAINER] ??= errors;
         validators.forEach((v) {
            if (v.errormessage != null)
               errors[v.model_field] = v.errormessage;
         });
      }
   }
   void setValue<T>(T value, cb(T value)){
      if (value != null)
         cb(value);
   }

   @override
   Map<String, dynamic> asMap() {
      throw Exception('NotImplemented yet');
   }
   
}