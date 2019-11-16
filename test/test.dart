import 'package:nxp_bloc/impl/config.dart';
import 'package:test/test.dart';

void main() {
   group('config test', () {
      test('base test1', () {
         final config = Config("config.yaml", "", "");
         print(config);
         print(config.assets);
         print(config.assets.size);
         
         print(config.cfg);
         print(config.cfg.assets);
         print(config.cfg.app);
         print(config.cfg.database);
         expect(config.assets.size, 768);
      });
   });
}



