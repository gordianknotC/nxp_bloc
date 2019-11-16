
import 'package:nxp_bloc/mediators/models/validator_model.dart';

enum Permission {
   engineer,
   user,
   administrator,
   guest
}


class AuthorizationToken {
   AuthorizationToken.fromMap(Map<String, dynamic> map) {
      accessToken = map["access_token"] as String;
      refreshToken = map["refresh_token"] as String;
      
      if (map.containsKey("expires_in")) {
         expiresAt = DateTime.now().toUtc()
            .add(Duration(seconds: map["expires_in"] as int));
      } else if (map.containsKey("expiresAt")) {
         expiresAt = DateTime.parse(map["expiresAt"] as String);
      }
   }
   AuthorizationToken.mock(){
      accessToken = "fake access token";
      refreshToken = "fake refresh token";
      expiresAt = DateTime.now().toUtc()
         .add(Duration(seconds: 6000));
   }
   
   String tokenType;
   String accessToken;
   String refreshToken;
   DateTime expiresAt;
   
   String get authorizationHeaderValue => "Bearer $accessToken";

   bool get isValidToken =>
       accessToken != null && refreshToken != null && !isExpired;

   bool get isExpired =>
      expiresAt.difference(DateTime.now().toUtc()).inSeconds < 0
         || accessToken == null || refreshToken == null;

   Map<String, dynamic> asMap() =>
      {
         "access_token": accessToken,
         "refresh_token": refreshToken,
         "expiresAt": expiresAt.toIso8601String()
      };
}

abstract class UserInf  implements SerializableModel{
   int id;
   String username;
   String display_name;
   String password;
   String avatarPath;
   Permission permission;
   AuthorizationToken token;
   bool get isAuthenticated;
   List<ValidationInf> validators;
}

class UserModel extends ModelValidator implements UserInf {
   UserModel();
   @override String avatarPath;
   @override int id;
   @override String username;
   @override String password;
   @override String display_name;
   @override Permission permission;
   @override AuthorizationToken token;
   @override bool get isAuthenticated => token != null && !token.isExpired;
   @override List<ValidationInf> validators = [
      UniqueValiation('id', 'id'),
      SolidUniqueValiation('display_name', 'display_name'),
      HybridValidator<String>([
         EmailValidation('username', 'username'),
         UniqueValiation('username', 'username'),
      ]),
      LengthValidation('password', 'password', left:8, right:21)
   ];


   @override Map<String, dynamic>
   asMap({bool considerValidation = false}) {
      final result = {
         "id": id,
         "username": username,
         'password': password,
         "display_name": display_name,
         "token": token?.asMap(),
         "permission": permission.toString(),
         "avatarPath": avatarPath,
      };
      if (considerValidation && hasValidationErrors){
         writeValidation(result);
      }
      return result;
   }

   void fromMap(Map<String, dynamic> map) {
      setValue<int>(
         map['id'] as int, (v) => id = v
      );
      setValue<String>(
          map['username'] as String, (v) => username = v
      );
      setValue<String>(
          map['display_name'] as String, (v) => display_name = v
      );
      setValue<String>(
          map['avatarPath'] as String, (v) => avatarPath = v
      );
      setValue<String>(
         map['password'] as String, (v) => password = v
      );
      setValue<Map<String,dynamic>>(
         map['token'] as Map<String,dynamic>, (v) => token = AuthorizationToken.fromMap(v)
      );
      setValue(
         map['permission'], (v) => permission = v is String
           ? Permission.values.firstWhere((u) => u.toString().endsWith(map['permission'] as String))
           : v is Permission
             ? v as Permission
             : v is int
               ? Permission.values.firstWhere((u) => u.index == map['permission'] as int)
               : (){throw Exception('');}()
      );
   
   
   }
}



