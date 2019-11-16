import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as Path;
import 'package:IO/src/io.codecs.dart';



String read(String path, {bool encode = true}){
	try {
		if (!encode){
			return File(path).readAsStringSync();
		}
		return Str.decompress(File(path).readAsStringSync(), encrypt: true);;
	} catch (e, s) {
		print('[ERROR] read failed: $e\n$s');
		rethrow;
	}
}

Future write(String path, String data, {bool encode = true}){
	if (!encode){
		return File(path).writeAsString(data);
	}
	return File(path).writeAsString(
			Str.compress(data, encrypt: true)
	);
}


class AppConfig implements AppConfigInf {
	@override String clientid;
	@override String clientsecret;
	@override int history;
	@override String directory;
	
	bool dataValidation; // unused, keep it or program failed to run
	bool debugLog;       // unused
	bool ntagLog;
	bool nfcSound;
	bool darkTheme;			 // unused
	int  ver;
	int language;
	
	int cycleIO_cycleTime;
	int cycleIO_maxRetries;
	bool cycleIO_enableMock;
	int cycleIO_mockCycleTime;
	String cycleIO_mockState;
	
	AppConfig(this.directory);
	
	Map<String, dynamic> asMap() {
		return{
			'clientid': clientid,
			'clientsecret': clientsecret,
			'history': history,
			'directory': directory,
			'debugLog': debugLog,
			'ntagLog': ntagLog,
			'nfcSound': nfcSound,
			'dataValidation': dataValidation,
			'darkTheme': darkTheme,
			'ver': ver,
			'language': language ?? 0,
			'cycleIO_cycleTime': cycleIO_cycleTime,
			'cycleIO_maxRetries': cycleIO_maxRetries,
			'cycleIO_enableMock': cycleIO_enableMock,
			'cycleIO_mockCycleTime': cycleIO_mockCycleTime,
			'cycleIO_mockState': cycleIO_mockState,
		};
	}
}

class AssetsConfig implements AssetsInf {
	@override String basepath;
	@override String journal_path;
	@override String resized_path;
	@override int size;
	
	String ntagLog_path;
	String customConfig_path;
	String pickFolder_path;
	
	Map<String, dynamic> asMap() {
		return{
			'basepath'		: basepath,
			'journal_path': journal_path,
			'resized_path': resized_path,
			'size'				: size,
			'ntagLog_path': ntagLog_path,
			'customConfig_path': customConfig_path,
			'pickFolder_path': pickFolder_path,
		};
	}
}

class DatabaseConfig implements DatabaseInf {
	@override String databaseName;
	@override String host;
	@override String password;
	@override int port;
	@override String username;
	
	Map<String, dynamic> asMap() {
		return {
			'databaseName': databaseName,
			'host': host,
			'port': port,
			'username': username,
		};
	}
}

class _Config {
	Map delegate;
	Map app;
	Map assets;
	Map database;
	
	_Config({String config_path, String data, bool json = false}) {
		try {
			if (json == false) {
				delegate = loadYaml (data == null
					? File(config_path).readAsStringSync()
					: data) as Map;
				print('loaded yaml: $delegate');
			} else {
				delegate = jsonDecode (data == null
					? read(config_path)
					: data) as Map;
			}
			app = delegate['app'] as Map;
			assets = delegate['assets'] as Map;
			database = delegate['database'] as Map;
		} on FileSystemException catch (e) {
			throw Exception(StackTrace.fromString(
					"path: ${Platform.script.path}\n"
							"${e.toString()}"
			));
		}
	}
	
	void customConfigInit() {
	
	}
}

class Config implements ConfigInf {
	static BehaviorSubject<bool> configStream = BehaviorSubject<bool>();
	static StreamSink<bool> get _sink => configStream.sink;
	
	_Config cfg;
	@override AppConfigInf app;
	@override AssetsInf assets;
	@override var database;
	
	AppConfig    getConfig() => app    as AppConfig;
	AssetsConfig getAssets() => assets as AssetsConfig;
	
	Config(String default_config_path, String data, String app_dir, {bool json = false}) {
		cfg = _Config(config_path: default_config_path, data: data, json: json);
		configInit			 (cfg, app_dir);
		customConfigInit (app as AppConfig, assets as AssetsConfig);
		print("Config: ${asMap()}");
	}
	
	void configInit(_Config cfg, String app_dir){
		app = AppConfig(app_dir)
			..clientid = cfg.app['clientid'] as String
			..clientsecret = cfg.app['clientsecret'] as String
			..history = cfg.app['history'] as int
			..debugLog = cfg.app['debugLog'] as bool ?? true
			..ntagLog = cfg.app['ntagLog'] as bool ?? true
			..darkTheme = cfg.app['darkTheme'] as bool ?? false
			..nfcSound = cfg.app['nfcSound'] as bool ?? false
			..ver      = cfg.app['ver'] as int
			..dataValidation = cfg.app['dataValidation'] as bool ?? false
			..language = cfg.app['language'] as int ?? 0
			..cycleIO_cycleTime = cfg.app['cycleIO_cycleTime'] as int ?? 3000
			..cycleIO_maxRetries = cfg.app['cycleIO_maxRetries'] as int ?? 5
			..cycleIO_mockCycleTime = cfg.app['cycleIO_mockCycleTime'] as int ?? 2
			..cycleIO_mockState = cfg.app['cycleIO_mockState'] as String ?? 'null'
			..cycleIO_enableMock = cfg.app['cycleIO_enableMock'] as bool ?? true;
		
		assets = AssetsConfig()
			..size = cfg.assets['size'] as int
			..basepath = cfg.assets['basepath'] as String
			..journal_path = cfg.assets['journal_path'] as String
			..resized_path = cfg.assets['resized_path'] as String
			..customConfig_path = cfg.assets['customConfig_path'] as String
			..pickFolder_path   = cfg.assets['pickFolder_path'] as String
			..ntagLog_path = cfg.assets['ntagLog_path'] as String;
		
		database = DatabaseConfig()
			..databaseName = cfg.database['databaseName'] as String
			..host = cfg.database['host'] as String
			..password = cfg.database['password'] as String
			..port = cfg.database['port'] as int
			..username = cfg.database['username'] as String;
		
		/*print(
			 	'host     : ${database.host}\n'
				'port     : ${database.port}\n'
				'logpath  : ${cfg.assets['ntagLog_path']}\n'
				'jPath    : ${cfg.assets['journal_path']}\n'
				'basepath : ${assets.basepath}\n'
				'resized  : ${assets.resized_path}\n'
		);*/
	}
	
	void customConfigInit(AppConfig app, AssetsConfig assets) {
		if (assets.customConfig_path?.isEmpty ?? true) {
			if (assets.customConfig_path != null)
				assets.ntagLog_path = "logs";
			else
				assets.ntagLog_path = "logs";
			assets.customConfig_path = Path.join(app.directory, "config.json");
			updateCustomConfigToDisk();
		}else{
//			final path = Path.join(app.directory, getAssets().customConfig_path);
//			print('load presaved custom configs: $path');
//			final data = File(path).readAsStringSync();
//			cfg = _Config(config_path: path, data: data, json: true);
			cfg = readCustomConfig();
			configInit(cfg, app.directory);
		}
	}
	
	_Config readDefaultConfig(){
		try {
			final config_path = Path.join(app.directory, "config.json");
			final data = read(config_path);
			return _Config(config_path: config_path, data: data, json: true);;
		} catch (e, s) {
			print('[ERROR] Config.readDefaultConfig failed: $e\n$s');
			rethrow;
		}
	}
	
	_Config readCustomConfig(){
		try {
			final path = Path.join(app.directory, getAssets().customConfig_path);
			print('load presaved custom configs: $path');
			final data = read(path);
			return _Config(config_path: path, data: data, json: true);
			;
		} catch (e, s) {
			print('[ERROR] Config.readCustomConfig failed: $e\n$s');
			rethrow;
		}
	}
	
 
	
	void updateDefaultConfig(){
		try {
			final config_path = Path.join(app.directory, "config.json");
			if (config_path != getAssets().customConfig_path){
//			final data = jsonDecode(File(config_path).readAsStringSync());
				final cfg = readDefaultConfig();
				final data = cfg.delegate;
				data['assets']['customConfig_path'] = getAssets().customConfig_path;
				write(config_path, jsonEncode(data));
			}
		} catch (e, s) {
			print('[ERROR] Config.updateDefaultConfig failed: $e\n$s');
			rethrow;
		}
	}
	
	void updateCustomConfigToDisk() {
		final path = Path.join(app.directory, getAssets().customConfig_path);
		write(path, toJsonString()).then((f){
			_sink.add(true);
			final loaded = read(path);
			print('saved raw data: $loaded');
			print('parsed json   : ${jsonDecode(loaded)}');
			final config = _Config(config_path: app.directory, data: loaded);
			print('parsed config : ${config.delegate}');
			assert(getConfig().directory == config.app['directory']);
			
		});
	}
	
	String toJsonString(){
		return jsonEncode(asMap());
	}
	
	Map<String,dynamic> asMap(){
		return {
			'app': (app as AppConfig).asMap(),
			'assets': (assets as AssetsConfig).asMap(),
			'database': (database as DatabaseConfig).asMap()
		};
	}
	
	
}