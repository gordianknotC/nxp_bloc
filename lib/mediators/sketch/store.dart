import 'dart:async';
import 'dart:io';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:path/path.dart' as _Path;
import 'package:IO/src/typedefs.dart';
import 'package:IO/src/io.codecs.dart' show Str;

final _D = AppState.getLogger("Store");

abstract class StoreInf{
	bool      encrypt;
	String    path;
	StoreInf  open();
	Future<StoreInf> writeAsync(String content, {bool encrypt = true});
	void             writeSync (String content, {bool encrypt = true});
	Future<StoreInf> writeAsBytes(List<int> data);
	void             deleteSync();
	Future<String>   readAsync({bool encrypt = true});
	String           readSync({bool encrypt = true});
	List<int>        readAsBytesSync();
	Future<List<int>>readAsBytes();
	Future<bool>     existsAsync();
	bool             existsSync();
	String           getPath([String pth]);
	StoreStatInf     statSync();
	Future<StoreStatInf> stat();
	Future<StoreInf> rename(String path);
	//void         logNtag    ({String key, String data});
	//List<String> readNtagLog();
	
	StoreInf(this.path);
}

abstract class StoreStatInf {
	DateTime changed;
	DateTime modified;
	DateTime accessed;
	int mode;
	int size;
}

abstract class ConfigStoreSketch<T>{
	String _configDir;
	String _appDir;
	// Set<T>      _filesOnDisk;
	// Set<String>  _filePathsOnDisk;
	String get configDir;
	String get appDir;
	Set<T> get filesOnDisk;
	Set<String> get filePathsOnDisk;
	String         getDartLogContent();
	Future<Set<T>> fetchAllLocalFiles();
	Future<Map<String,dynamic>> getLogFilesContent();
	ConfigStoreSketch();
}

class StoreStat implements StoreStatInf {
	@override DateTime accessed;
	@override DateTime changed;
	@override int mode;
	@override DateTime modified;
	@override int size;
	
	StoreStat(FileStat stat) {
		accessed = stat.accessed;
		changed = stat.changed;
		mode = stat.mode;
		modified = stat.modified;
		size = stat.size;
	}
}

enum EFileEvent {
	update,
	remove,
	add
}

class FileEvent {
	File file;
	EFileEvent event;
	
	FileEvent(this.file, this.event);
}

class StoreBase implements StoreInf {
	static bool unitTest = false;
	final StreamSink<FileEvent> Function() fileSinkGetter;
	final void Function(List<String>) fileScanner;
	final String configPath;
	StoreBase(this.path, this.configPath, this.fileSinkGetter, this.fileScanner, {this.encrypt = true}) {
		_D("init store path: ${getPath()}");
		
	}
	
	@override String path;
	@override String result;
	@override bool   encrypt;
	
	@override String getPath([String pth]) {
		try {
			if (path != null && path.startsWith('/'))
				return path;
			if (TEntity.unitTesting){
				return path;
			}else{
				return _Path.join(_Path.dirname(configPath), pth ?? path);
			}
		} catch (e, s) {
			print('[ERROR] StoreImpl.getPath failed: \n$s');
			rethrow;
		}
//		return Path.join(config.app.directory, pth ?? path);
	}
	
	@override Future<bool> existsAsync() {
		return File(getPath()).exists();
	}
	
	@override bool existsSync() {
		return File(getPath()).existsSync();
	}
	
	@override StoreInf open() {
		return this;
	}
	
	
	@override Future<String> readAsync({bool encrypt = true}) {
		final completer = Completer<String>();
		final path = getPath();
		File(path).readAsString().then((r) {
			_D('read file:$path');
			result = r;
			if (encrypt) {
				result = Str.decompress(r, encrypt: true);
			}
			_D(result);
			completer.complete(result);
		});
		return completer.future;
	}
	
	@override String readSync({bool encrypt = true}) {
//      return File(getPath()).readAsStringSync();
		throw Exception("method: `readSync` Not Implemented yet");
	}
	
	@override Future<StoreInf> rename(String path){
		final origpath = getPath();
		final file = File(origpath);
		if (file.existsSync()){
			return file.rename(path).then((_file){
				fileSinkGetter().add(FileEvent(file, EFileEvent.remove));
				fileSinkGetter().add(FileEvent(_file, EFileEvent.add));
				return StoreBase(_file.path, configPath, fileSinkGetter, fileScanner);
			});
		}else{
			return Future.value(null);
		}
	}
	
	@override Future<StoreInf> writeAsync(String content, {bool encrypt = true}) {
		final completer = Completer<StoreInf>();
		final path = getPath();
		final file = File(path);
		final exists = file.existsSync();
		String e_content;
		if (encrypt) {
			e_content = Str.compress(content, encrypt: true);
		}
		
		file.writeAsString(e_content ?? content).then((r) {
			_D("write: $content");
			completer.complete(this);
			fileSinkGetter().add(FileEvent(file, exists ? EFileEvent.update : EFileEvent.add));
			if (!unitTest)
				fileScanner([file.path]);
		});
		return completer.future;
	}
	
	@override void writeSync(String content, {bool encrypt = true}) {
		final path = getPath();
		_D(content);
		final file = File(path);
		final exists = file.existsSync();
		
		String e_content;
		if (encrypt) {
			e_content = Str.compress(content, encrypt: true);
		}
		
		final result = file.writeAsStringSync(e_content ?? content);
		fileSinkGetter().add(FileEvent(file, exists ? EFileEvent.update : EFileEvent.add));
		if (!unitTest)
			fileScanner([file.path]);
		return result;
	}
	
	@override void deleteSync() {
		final file = File(getPath());
		final exists = file.existsSync();
		_D.debug('deleteSync($exists): ${file.path}');
		if (exists) {
			fileSinkGetter().add(FileEvent(file, EFileEvent.remove));
			return file.deleteSync();
		}
	}
	
	@override StoreStatInf statSync() {
		return StoreStat(File(getPath()).statSync());
	}
	
	@override Future<StoreStatInf> stat() {
		final completer = Completer<StoreStatInf>();
		File(getPath()).stat().then((result) {
			completer.complete(StoreStat(result));
		});
		return completer.future;
	}
	
	@override
	Future<StoreInf> writeAsBytes(List<int> data) {
		final completer = Completer<StoreInf>();
		final file = File(getPath());
		final exists = file.existsSync();
		file.writeAsBytes(data).then((result) {
			completer.complete(this);
			fileSinkGetter().add(FileEvent(file, exists ? EFileEvent.update : EFileEvent.add));
			if (!unitTest)
				fileScanner([file.path]);
		});
		return completer.future;
	}
	
	@override List<int> readAsBytesSync() {
		return File(getPath()).readAsBytesSync();
	}
	
	@override Future<List<int>> readAsBytes() {
		final completer = Completer<List<int>>();
		File(getPath()).readAsBytes().then(completer.complete);
		return completer.future;
	}
}

