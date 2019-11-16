import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:PatrolParser/PatrolParser.dart';
import 'package:common/common.dart' show FN, guard;
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_bloc.dart';
import 'package:nxp_bloc/mediators/models/validator_model.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:path/path.dart' as _Path;
import 'package:image/image.dart' as Img;
import 'package:image/image.dart';
import 'package:uuid/uuid.dart';
import 'package:PatrolParser/PatrolParser.dart' show PatrolRecord;
import 'package:IO/src/io.dart' show TEntity;

final _D = AppState.getLogger('img');


final uuid = Uuid();
//final _cfg = Injection.injector.get<ConfigInf>();
//final RESIZED_PATH = _cfg.assets.resized_path.replaceAll(r'/', Platform.pathSeparator);
// for matching V-2019-03-11154037.000----86573-V-2019-03-11131705.0
//final _STARTPTN = RegExp('[VH]-[0-9]{4}-[0-9]{2}-[0-9]{8}\.000');

/// Vertical/Horizontal-deviceId-patrolRecordDate-imageDate
final _STARTPTN = RegExp('[VH]-[0-9]+-[0-9]+-[0-9]+');

void filterNullInMap(Map<String, dynamic> ret) {
	ret.keys.toList().forEach((k) {
		if (ret[k] == null) ret.remove(k);
	});
}


abstract class MaintanenceInf implements SerializableModel {
	int id;
	DeviceModel device;
	PatrolSetup setup;
	List<int> tempRange;
	List<double> voltageRange;
	List<int> pressureRange;
	List<int> injectionRange;
	List<ValidationInf> validators;
}

class MaintenanceModel extends ModelValidator implements MaintanenceInf {
	@override DeviceModel device;
	@override int id;
	@override List<int> injectionRange;
	@override List<int> pressureRange;
	@override PatrolSetup setup;
	@override List<int> tempRange;
	@override List<double> voltageRange;
	@override List<ValidationInf> validators = [UniqueValiation('id', 'id')];
	
	MaintenanceModel({this.device, this.id, this.injectionRange, this.pressureRange, this.setup, this.tempRange, this.voltageRange});
	
	MaintenanceModel.create(DeviceModel dev){
		injectionRange = [0, 0];
		pressureRange = [0, 0];
		setup = PatrolSetup.Setup1;
		tempRange = [0, 0];
		voltageRange = [0, 0];
		device = dev;
	}
	
	MaintenanceModel.clone(MaintenanceModel m){
		id = m.id;
		device = m.device;
		injectionRange = List.from(m.injectionRange);
		pressureRange = List.from(m.pressureRange);
		tempRange = List.from(m.tempRange);
		voltageRange = List.from(m.voltageRange);
		setup = m.setup;
	}
	
	MaintenanceModel.from(Map<String, dynamic> map, DeviceModel dev){
		guard(() {
			id = map['id'] as int; //parseOrNull(map['id'] as String);
			device = dev;
			injectionRange = List<int>.from(map['injectionRange'] as List);
			pressureRange = List<int>.from(map['pressureRange'] as List);
			tempRange = List<int>.from(map['tempRange'] as List);
			voltageRange = List<double>.from(map['voltageRange'] as List);
			final s = map['setup'] as String;
			setup = PatrolSetup.values.firstWhere((v) => v.toString().endsWith(s));
		}, 'serializing MaintenanceModel failed, map:\n '
				'${FN.stringPrettier(map)}', error: 'SerializeError');
	}
	
	@override Map<String, dynamic> asMap({bool considerValidation = false}) {
		final result = {
			'id': id,
			'device': device.id,
			'setup': setup.toString(),
			'tempRange': tempRange,
			'voltageRange': voltageRange,
			'pressureRange': pressureRange,
			'injectionRange': injectionRange
		};
		if (considerValidation && hasValidationErrors) {
			writeValidation(result);
		}
		return result;
	}
}

abstract class DeviceInf implements SerializableModel {
	int id;
	String name;
	List<int> device_responsers;
	MaintenanceModel maintenance;
	List<ValidationInf> validators;
	DateTime created;
	DateTime modified;
}

class PatrolRecordModel extends ModelValidator implements SerializableModel {
	static Map<String, dynamic> aliasMap = {};
	static String aliasDataPath = 'nxp.db.rawtag.aliasnames.json';
	static String getAlias(PatrolRecordModel inst) {
		return aliasMap[inst.machine_id.first.toString()] as String;
	}
	
	static Future<String> loadAliasMap() {
		if (PatrolState.manager.file('nxp.db.rawtag.aliasnames.json').existsSync()) {
			return PatrolState.manager.file('nxp.db.rawtag.aliasnames.json').readAsync().then((data) {
				final result = jsonDecode(data) as Map<String, dynamic>;
				aliasMap = result;
			});
		}
	}
	
	static Future dumpAliasMap() {
		try {
			final data = jsonEncode(aliasMap);
			return PatrolState.manager.file('nxp.db.rawtag.aliasnames.json').writeAsync(data);
		} catch (e) {
			throw Exception('dumpAliasMap failed: '
					'\n${StackTrace.fromString(e.toString())}');
		}
	}
	
	static void addAlias(int machine_id, String alias) {
		try {
			aliasMap[machine_id.toString()] = alias;
			dumpAliasMap();
		} catch (e) {
			rethrow;
		}
	}
	
	int id;
	int user_id;
	List<int> get machine_id => patrol.getDevId(); //patrol.id   ;
	DateTime get date => patrol.date;
	Uint8List get initial_id => patrol.id;
	Uint8List get device_id => patrol.type2;
	Uint8List get setup => patrol.setup;
	Uint8List get hh => patrol.hh;
	Uint8List get mm => patrol.mm;
	Uint8List get ss => patrol.ss;
	Uint8List get type1 => patrol.type1;
	Uint8List get type2 => patrol.type2;
	Uint8List get inject1 => patrol.inject1;
	Uint8List get inject2 => patrol.inject2;
	Uint8List get patrol1 => patrol.patrol1;
	Uint8List get patrol2 => patrol.patrol2;
	Uint8List get temperature => patrol.temperature;
	Uint8List get voltage => patrol.voltage;
	Uint8List get pressure1 => patrol.pressure1;
	Uint8List get pressure2 => patrol.pressure2;
	Uint8List get status1 => patrol.status1;
	Uint8List get status2 => patrol.status2;
	Uint8List get status3 => patrol.status3;
	Uint8List get status4 => patrol.status4;
	Uint8List get rest => patrol.rest;
	Uint8List get nameSection => patrol.nameSection;
	Uint8List get areaSection => patrol.areaSection;
	PatrolRecord patrol;
	
	@override List<ValidationInf> validators = [
		DateValidation('date', 'date'),
		RangeValidation('setup', 'setup', [0, 12]),
		RangeValidation('hh', 'hh', [0, 23]),
		RangeValidation('mm', 'mm', [0, 59]),
		RangeValidation('ss', 'ss', [0, 59]),
	];
	
	PatrolRecordModel(this.patrol, this.user_id);
	
	// notice: for config creation, not for ntag records
	PatrolRecordModel.empty(){
		patrol = PatrolRecord.empty();
		user_id = null;
	}
	
	// from map of PatrolRecordModel
	PatrolRecordModel.fromMap(Map<String, dynamic> body){
		try {
			final map = Map<String, dynamic>.from(body);
			if (map['id'] is List)
				map['id'] = map['id'].first;
			
			id = map['id'] as int;
			final machine_id = map['machine_id'] != null
					? List<int>.from(map['machine_id'] as List)
					: null;
			user_id = map['user_id'] as int;
			map['id'] = map['initial_id']?.first;
			map.remove("initial_id");
			patrol = PatrolRecord.fromJson(map);
		} catch (e) {
			_D.error('failed to parse PatrolRecordModel fromMap: '
					'\n$e'
					'\nbody: $body');
			rethrow;
		}
	}
	
	PatrolRecordModel.fromByteString(String text){
		if (PatrolRecord.isValidByteString(text)) {
			// already encoded, do nothing
			patrol = PatrolRecord.fromByteString(text);
			id = null;
		} else {
			throw Exception('Not a valid byte string');
		}
	}
	
	@override String toString() {
		return "${patrol.getType()}-${machine_id.last}-${user_id}";
	}
	
	@override Map<String, dynamic> asMap({bool considerValidation = false}) {
		try {
			final result = patrol.toJson();
			result['machine_id'] = patrol.getDevId(); //result['id'];
			result['id'] = id;
			result['initial_id'] = patrol.id;
			result['user_id'] = user_id ?? 1;
			result['device_id'] = [(result['type2'][0] as int) + 1];
			if (considerValidation && hasValidationErrors) {
				writeValidation(result);
			}
			return result;
		} catch (e, s) {
			print('[ERROR] PatrolRecordModel.asMap failed: $e\n$s');
			rethrow;
		}
	}
	
	
}

abstract class IJOptionInf implements SerializableModel {
	int id;
	String name;
	String description;
	bool certificated;
	List<int> imagejournals;
	List<ValidationInf> validators;
	DateTime created;
	DateTime modified;
}

class DeviceModel extends ModelValidator implements DeviceInf {
	@override int id;
	@override DateTime created;
	@override DateTime modified;
	@override String name;
	@override List<int> device_responsers = [1];
	@override MaintenanceModel maintenance;
	@override List<ValidationInf> validators = [UniqueValiation('id', 'id'), UniqueValiation('name', 'name')];
	
	DeviceModel(this.name);
	
	DeviceModel.clone(DeviceModel m){
		id = m.id;
		name = m.name;
		maintenance = MaintenanceModel.clone(m.maintenance);
		device_responsers = List.from(m.device_responsers);
	}
	
	DeviceModel.create(){
		name = 'TP_';
		created = modified = DateTime.now().toUtc();
		maintenance = MaintenanceModel.create(this);
	}
	
	DeviceModel.from(Map<String, dynamic> map){
		guard(() {
			id = map['id'] as int; //parseOrNull(map['id'] as String);
			name = map['name'] as String;
			if (map['maintenance'] != null) maintenance = MaintenanceModel.from(map['maintenance'] as Map<String, dynamic>, this);
			if (map['device_responsers'] != null) device_responsers = List<int>.from(map['device_responsers'] as List);
			if (map['created'] != null) {
				created = DateTime.parse(map['created'] as String).toUtc();
			}
			if (map['modified'] != null) {
				modified = DateTime.parse(map['modified'] as String).toUtc();
			}
		}, 'serializing device failed, map:\n '
				'${FN.stringPrettier(map)}', error: 'SerializeError');
	}
	
	void update(DeviceModel m) {
		id = m.id;
		name = m.name;
		maintenance = MaintenanceModel.clone(m.maintenance);
		device_responsers = List.from(m.device_responsers);
	}
	
	Map<String, dynamic> asMap({bool considerValidation = false}) {
		final result = {
			'id': id,
			'name': name,
			'device_responsers': device_responsers,
			'maintenance': maintenance?.asMap(),
			'created': created?.toUtc()?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
			'modified': modified?.toUtc()?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
		};
		if (considerValidation && hasValidationErrors) {
			writeValidation(result);
		}
		return result;
	}
	
}

class IJOptionModel extends ModelValidator implements IJOptionInf {
	@override DateTime created;
	@override DateTime modified;
	@override int id;
	@override String name;
	@override String description;
	@override bool certificated;
	@override List<int> imagejournals;
	@override List<ValidationInf> validators = [UniqueValiation('id', 'id'), SolidUniqueValiation('name', 'name')];
	
	IJOptionModel(this.name, this.description, {this.id, this.certificated = false});
	
	IJOptionModel.clone(IJOptionModel m){
		id = m.id;
		name = m.name;
		description = m.description;
		certificated = m.certificated;
		imagejournals = m.imagejournals;
	}
	
	IJOptionModel.from(Map<String, dynamic> map){
		guard(() {
			id = map['id'] as int;
			name = map['name'] as String;
			description = map['description'] as String;
			certificated = map['certificated'] as bool;
			if (map['imageJournals'] != null) {
				imagejournals = List<int>.from(map['imageJournals'] as List);
			}
			if (map['created'] != null) {
				created = DateTime.parse(map['created'] as String).toUtc();
			}
			if (map['modified'] != null) {
				modified = DateTime.parse(map['modified'] as String).toUtc();
			}
		}, 'serializing IJOptionModel failed, map:\n '
				'${FN.stringPrettier(map)}', error: 'SerializeError');
	}
	
	@override
	Map<String, dynamic> asMap({bool considerValidation = false}) {
		final result = {
			'id': id,
			'name': name,
			'description': description,
			'certificated': certificated,
			'imageJournals': imagejournals,
			'created': created?.toUtc()?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
			'modified': modified?.toUtc()?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String()
		};
		if (considerValidation && hasValidationErrors) {
			writeValidation(result);
		}
		return result;
	}
	
	bool sameTag(IJOptionModel other) {
		return name == other.name
				&& description == other.description;
	}
	
	bool theSame(IJOptionModel other) {
		return name == other.name && description == other.description && FN.orderedTheSame(imagejournals, other.imagejournals);
	}
}

abstract class ImageModelInf implements SerializableModel {
	String description;
	String path;
	String ident;
	List<int> image_size;
	Image _resized_image;
	String image_type;
	int resize;
	Map<String, dynamic> asMap();
	
	void imageInit();
}

//
// rewrite following into BLoC pattern
class ImageModel implements ImageModelInf {
	static RegExp IMAGE_PTN = _STARTPTN;
	static int RESIZE;
	static String RESIZED_PATH;
	static int getFileSizeByIdent(String ident) {
		final segs = ident.split('-');
		if (segs.length > 7)
			return int.parse(segs[7]);
		return -1;
	}
	static Uri Function(String) urlGetter;

//   int imagejournal_id;
	int rec_id;
	
	int patrolRecordId;
	String patrolRecordDate;
	
	Image _thumb_image;
	String description;
	String path;
	String _ident;
	String image_type;
	List<int> image_size;
	Image _resized_image;
	
	int resize;
	int filesize;
	int _orig_size;
	String _orig_name;
	
	bool get isEmpty => _resized_image == null || _ident == null;
	bool get isNotEmpty => !isEmpty;
	Image get resized_image => _resized_image;
	Image get thumb_image => _thumb_image;
	List<IJOptionModel> defects;
	
	
	// untested:
	String get ident{
		try {
			if (_ident != null)
				return _ident;
			if (isIdentifiedPath(path))
				return _ident = _Path.basename(path).split('.').first;
			return _ident;;
		} catch (e, s) {
			print('[ERROR] ImageModel.ident failed: $e\n$s');
			rethrow;
		}
	}
	/*
	String get ident => _ident
	*/
	
	void set ident(String v) {
		try {
//			_ident = v;
			_ident = v.split('.').first;
			final size = getFileSizeByIdent(v);
			if (size != -1) filesize = int.parse(v.split('-')[7]);
		} catch (e, s) {
			print('[ERROR] ImageModel.ident failed: $e\n$s');
			print('set ident by value: $v');
			rethrow;
		}
	}
	
	bool isIdentifiedPath(String pth){
		return _Path.basename(pth).startsWith(IMAGE_PTN);
	}
	
	String get orig_name {
		if (_orig_name != null) return _orig_name;
		if (path != null) {
			return _Path.basename(path);
		}
		return null;
	}
	
	void set resized_image(Image v) {
		if (v == null) {
			image_size = null;
			_resized_image = null;
			return;
		}
		image_size = [v.width, v.height];
		_resized_image = v;
	}
	
	void _testInitialized(String path, int resize) {
		if (path != null) RESIZED_PATH = path;
		if (resize != null) RESIZE = resize;
		if (RESIZED_PATH == null) throw Exception("Invalid usage, please initialize RESIZED_PATH first");
		if (RESIZE == null) throw Exception("Invalid usage, please initialize RESIZE first");
	}
	
	ImageModel.empty();
	
	ImageModel(this.description, this.path, this.resize, this.patrolRecordId, this.patrolRecordDate,
			{String RESIZED_PATH, int RESIZE, this.rec_id, this.defects}) {
		_testInitialized(RESIZED_PATH, resize);
	}
	
	ImageModel.fromResizedImage(this._resized_image, this.description, this.path, this.resize, this.patrolRecordId, this.patrolRecordDate,
			{String RESIZED_PATH, int RESIZE, this.rec_id, this.defects}){
		ident = _Path.basename(path);
		_testInitialized(RESIZED_PATH, resize);
		resized_image = _resized_image;
	}
	
	ImageModel.clone(ImageModel model){
//      imagejournal_id = model.imagejournal_id;
		rec_id = model.rec_id;
		description = model.description;
		patrolRecordId = model.patrolRecordId;
		patrolRecordDate = model.patrolRecordDate;
		path = model.path;
		_ident = model._ident;
		image_type = model.image_type;
		image_size = model.image_size;
		resized_image = model._resized_image;
		filesize = model.filesize;
		_orig_name = model._orig_name;
		_orig_size = model._orig_size;
		resize = model.resize;
		defects = model.defects; // fixme: db
	}
	
	ImageModel.fromEntity(StoreInf entity, PatrolRecord record, String date, Future then(Image img), {this.defects}){
		path = entity.path;
		assignPatrolRecord(record, date);
		loadImage().then(then);
	}
	
	ImageModel.update({this.description, Image image, String RESIZED_PATH, int RESIZE}){
		resized_image = image;
		_testInitialized(RESIZED_PATH, resize);
	}
	
	ImageModel.fromMap(Map<String, dynamic> data, then(Image image), error(e), {String RESIZED_PATH, int RESIZE, bool initialize = true}){
		try {
			RESIZE ??= ImageModel.RESIZE;
			rec_id = data['rec_id'] as int;
			description = data['description'] as String;
			ident = data['ident'] as String;
			path = data['path'] as String;
			image_type = path.split('.').last;
			
			if (data['image_size']  != null)
				image_size = List<int>.from(data['image_size'] as List);
			
			if (image_type == 'json')
				throw Exception('owiejojfoeifj');
			
			resize = (data['size'] as int) ?? RESIZE;
			
			if (data.containsKey('image_size'))
				image_size = List<int>.from(data['image_size'] as List);
			
			if (ident == null || path == null)
				throw Exception('Uncaught Exception');
			
			if (data.containsKey('defects')){
				print(data['defects']);
				defects = List.generate((data['defects'] as List).length, (i){
					try {
						return IJOptionModel.from(data['defects'][i] as Map<String, dynamic>);
					} catch (e, s) {
						print('[ERROR] invalid defects model: $e\n$s');
						rethrow;
					}
				});
			}
			
			if (initialize) {
				path = getImagePath();
				loadImage().then(then).catchError(error);
				_testInitialized(RESIZED_PATH, resize);
			};
		} catch (e, s) {
			print('[ERROR] call ImageModel.fromMap failed: $e\n$s');
			print('[ERROR] map data: $data');
			rethrow;
		}
	}
	
	String getImagePath() {
		if (isResizedPath)
			return path;
		
		if (ident == null) {
			if (path == null)
				throw Exception('Invalid image model, since path is null');
			return path;
		}
		
		if (path.contains(ident))
			return path;
		
		final result = _Path.join (RESIZED_PATH, ident + ".jpg");
		assert(ident.startsWith(IMAGE_PTN), 'file pattern miss matched!! $result, ident: $ident');
		return result;
	}
	
	void assignPatrolRecord(PatrolRecord patrol, String date) {
		patrolRecordId = patrol
				.getDevId()
				.first;
		patrolRecordDate = date;
	}
	
	Future<StoreInf> dumpExtra(Map<String, dynamic> data) {
		final pth = getImagePath();
		final file = PatrolState.manager.file(pth + '.extra');
		final completer = Completer<StoreInf>();
		final content = jsonEncode(data);
		file.writeSync(content, encrypt: false);
		completer.complete(file);
		return completer.future;
	}
	
	
	Future<StoreInf> dumpImage({bool jpgEncoded = false, int thumbSize, String basePath}) {
		try {
			if (resized_image == null) return null;
			final pth = getImagePath();
			final file = PatrolState.manager.file(pth);
			final completer = Completer<StoreInf>();
			
			if (thumbSize != null) {
				final thumbpath = file.path + '.thumb';
				final thumb = PatrolState.manager.file(thumbpath);
				if (!thumb.existsSync()) {
					_D.debug('dumpImage for thumb: $thumbpath');
					_thumb_image = Img.copyResize(resized_image, width:thumbSize);
					thumb.writeAsBytes(!jpgEncoded ? encodeJpg(_thumb_image, quality: 70) : resized_image.getBytes());
				} else {
					_D.debug('skip dump for thumb, since thumb path already exists: $thumbpath');
				}
			}
			if (file.existsSync()) {
				_D.error('skip dump, since file already exists: ${file.path}');
				return Future.value(file);
			}
			_D.debug('dumpimage: $path');
			//_resizeImage(resized_image);
			file.writeAsBytes(!jpgEncoded ? encodeJpg(resized_image, quality: 70) : resized_image.getBytes()).then(completer.complete);
			
			return completer.future;
		} catch (e, s) {
			_D.error('dumpImage failed: \n$s');
			rethrow;
		}
	}
	
	bool isAValidIdentPath(String pth) {
		return pth.startsWith(_STARTPTN);
	}
	
	static bool isHorizontal(Image img) => img.width > img.height;
	
	static bool isVertical(Image img) => !isHorizontal(img);
	
	bool get isResizedPath {
		if (path == null) return false;
		if (path.contains(RESIZED_PATH)) return true;
		return false;
	}
	
	// todo:
	// detect whether loaded image is resized or not
	Future<Image> loadImage() {
		final completer = Completer<Image>();
		_D('image init0');
		imageInit().then((model) {
			_D('image init2');
			if(!completer.isCompleted)
				completer.complete(model.resized_image);
		}).catchError((_){
			throw Exception(_);
		});
		_D('image init1');
		return completer.future;
	}
	
	Future<Image> getThumb() async {
		_D('getThumb');
		if (PatrolState.manager.file(getImagePath() + ".thumb").existsSync()) {
			return Image.fromBytes(image_size[0], image_size[1], PatrolState.manager.file(getImagePath() + ".thumb").readAsBytesSync());
		}
		return Future.value(null);
	}
	
	Future<Image> genThumb({int thumbSize = 128}) async {
		if (resized_image != null) {
			return Future.value(Img.copyResize(resized_image, width:thumbSize));
		} else {
			await imageInit();
			return genThumb();
		}
	}
	
	/*void writeExtra(List<String> logs, {bool append = true}){
      _D('genExtra');
      if (PatrolState.manager.file(getImagePath()+ ".extra").existsSync()){
         final data = PatrolState.manager.file(getImagePath()+ ".extra").readSync().split('\n').toSet();
         final l = data.length;
         if (append){
            data.addAll(logs.map((m) => m.trim()));
            if (data.length > l){
               PatrolState.manager.file(getImagePath()+ ".extra").writeSync(data.join('\n'));
            }
         }else{
            PatrolState.manager.file(getImagePath()+ ".extra").writeSync(logs.join('\n'));
         }
      }else{
         PatrolState.manager.file(getImagePath()+ ".extra").writeSync(logs.join("\n"));
      }
   }*/
	
	/*Set<String> readExtra(){
      if (PatrolState.manager.file(getImagePath()+ ".extra").existsSync()){
         return PatrolState.manager.file(getImagePath()+ ".extra").readSync().split('\n').toSet();
      }else{
         return null;
      }
   }*/
	
	static Image resizeImage(Image img, int _resize) {
		if (isHorizontal(img) && img.width > _resize) return copyResize(img, width:_resize);
		if (isVertical(img) && img.height > _resize) return copyResize(img, width:_resize);
		return img;
	}
	
	Image _resizeImage(Image img, [int _resize]) {
		try {
			assert(img != null, 'image cannot be null');
			assert((_resize ?? resize) != null, 'resize cannot be null');
			
			if (isHorizontal(img) && img.width > (_resize ?? resize))
				return resized_image = copyResize(img, width:_resize ?? resize);
			
			if (isVertical(img) && img.height > resize)
				return resized_image = copyResize(img, width:_resize ?? resize);
			
			return img;;
		} catch (e, s) {
			print('[ERROR] ImageModel._resizeImage failed: $e\n$s');
			rethrow;
		}
	}
	
	String getStringFromImageContent(Uint8List content) {
			int getNext(Uint8List _content, int _idx, [int acc = 0]){
				final l = _content.length;
				final idx = min(l - 1, _idx + acc);
				final index = content.indexWhere((i) => i != 255, idx);
				return index == -1 ? content.last : content[index];
			}
      final size = content.length;
      final ret = <int>[];
      final recs = 10;
      for (var i = 1; i < recs; ++i) {
         final n = (size * i / (recs - 1)).round() - 1;
         final c = getNext(content, n);
         ret.add(c);
      }
      return base64Encode(ret).replaceAll(RegExp('[/,+=]+'), '');
   }
	
	
	static List<int> encodeToJPG(Image _thumb_image){
		return encodeJpg(_thumb_image, quality: 70);
	}
	
	static Image decodeRawImg(List<int> rawimage){
		return decodeImage(rawimage);
	}
	static Image decodeImg(List<int> rawimage, int size, [List<int> image_size]) {
		Image ret = image_size == null
				? resizeImage(decodeImage(rawimage), size)
				: Image.fromBytes(image_size[0], image_size[1], rawimage);
		return ret;
	}
	
	void setImageSize(int size) {
	
	}
	
	Image _decodeImage(List<int> rawimage) {
		if (image_size == null){
			final decoded = decodeImage(rawimage);
			if (decoded != null)
				return _resizeImage(decoded);
			return decodeImg(rawimage, ImageModel.RESIZE);
		}else{
			return Image.fromBytes(image_size[0], image_size[1], rawimage);
		}
	}
	
	static String getTime([DateTime time, String ds = "/", String sec = " ", String ts = ":"]) {
		final t = time ?? DateTime.now();
		final month = ('0' + t.month.toString()).substring(t.month.toString().length - 1);
		final day = ('0' + t.day.toString()).substring(t.day.toString().length - 1);
		final hour = ('0' + t.hour.toString()).substring(t.hour.toString().length - 1);
		final result = '${t.year}$ds${month}$ds${day}$sec${hour}$ts${t.minute}$ts${t.second}';
		return result;
	}
	
	String generateIdentNameByIdent(String identified, int id) {
		final segments = identified.split('-');
		final o = segments[0];
		final rest = segments.sublist(2, segments.length).join('-');
		return '$o-${id}-$rest';
	}
	
	String generateIdentName(String orientation, DateTime date, int id, String recordDate, [String identified]) {
		final o = orientation;
		// final d = '${date.year}${date.month}${date.day}${date.hour}${date.minute}${date.second}';
		final d = identified != null
			?	identified.split('-')[3].split('.').first
			: getTime(date, "", "", "");
		final _date = recordDate.replaceAll(RegExp('[\/]'), '');
		final s = resized_image == null
				? ""
				: "-" + getStringFromImageContent(resized_image.getBytes());
		return '$o-${id}-${_date}-${d}$s';
	}
	
	String getIdentName(Image resized_image, StoreStatInf stat) {
		final o = isHorizontal(resized_image) ? "H" : "V";
		final filedate = stat.modified;
//      final d = '${date.year}${date.month}${date.day}${date.hour}${date.minute}${date.second}';
		final d = getTime(filedate, "", "", "");
//      final fd = d; //.replaceAll('-', '').split('.').first;
//      final n = tags["EXIF OwnerName"] ?? "";
//      final g = tags["GPS Position"] ?? "";
		final s = resized_image == null
			? ""
			: "-" + getStringFromImageContent(resized_image.getBytes());
//      _D('d: $d, fd: $fd');
		String result = '$o-${patrolRecordId}-${patrolRecordDate}-${d}$s';
		return result;
	}
	
	Future<ImageModel> remoteImageInit([bool autoSave = true]){
		// transform into local path and detect to see if already exists
		// load image from remote url
		// -------------------------------------------------------------
		final transformed_path = getImagePath().replaceFirst('/images', 'assets/resized');
		if (PatrolState.manager.file(TEntity(entity: File(transformed_path)).path).existsSync()){
			path = TEntity(entity: File(transformed_path)).path;
			return imageInit();
		}else{
			try {
				final completer = Completer<ImageModel>();
				final _downloadData = <int>[];
				final url = getImagePath();
				final fileSave = PatrolState.manager.file(path);
				HttpClient client = HttpClient();
				client.getUrl(urlGetter(ident)).then((HttpClientRequest request) {
					return request.close();
				}).then((HttpClientResponse response) {
					response.listen(_downloadData.addAll, onDone: () {
						if (autoSave)
							fileSave.writeAsBytes(_downloadData);
						resized_image = ImageModel.decodeRawImg(_downloadData);
						filesize = fileSave.statSync().size;
						image_type = fileSave.path.split('.').last;
						completer.complete(this);
					}, onError: (e){
						throw Exception(e);
					});
				});
				return completer.future;;
			} catch (e, s) {
				print('[ERROR] ImageModel.remoteImageInit failed: $e\n$s');
				rethrow;
			}
		}
		
	}
	
	Future<ImageModel> imageInit() async {
		try {
			if (ident != null) {
				if (image_size != null) {
					if (getImagePath().startsWith('/images')) // untested:
						return remoteImageInit();
					
					_D.info('resize image to: $image_size');
					resized_image ??= Image.fromBytes(image_size[0], image_size[1],
						PatrolState.manager.file(TEntity(entity: File(getImagePath())).path).readAsBytesSync());
				}
				if (resized_image != null)
					return Future.value(this);
				//throw Exception('Uncaught exception');
			}
			_D('path: $path');
			_D('getpath: ${getImagePath()}');
			_D('image_size: $image_size');
			_D('resize: $resize');
			
			final file = PatrolState.manager.file(TEntity(entity: File(getImagePath())).path);
			final stat = file.statSync();
			filesize = stat.size;
			_D('filesize: $filesize');
			_D('filepath: ${file.getPath()}');
			
			assert(file.existsSync(), "file: ${file?.path} not exists");
			return await file.readAsBytes().then((image_data) async {
				_D('read image data success!');
				_D('read exif tag success');
				try {
					_D('image decoded');
					try {
						resized_image = _decodeImage(image_data);
					} catch (e, s) {
						print('[ERROR] ImageModel.imageInit decode image failed, image_data: $image_data');
						rethrow;
					}
					image_type = orig_name.split('.').last;
					if (image_type == 'json')
						throw Exception('owiejojfoeifj');
					_orig_size = image_data.length;
					if (isAValidIdentPath(orig_name)) {
						_D('not valid path: $orig_name');
						ident = orig_name;
						return this;
					}
					ident = getIdentName(resized_image, stat);
					_D('ident: $ident');
					return this;
				} catch (e) {
					throw Exception('Errors occurs while resizing and decoding image: $path \n${StackTrace.fromString(e.toString())}');
				}
			});
		} catch (e, s) {
			print(('init failed: $e\n$s'));
			rethrow;
		}
	}
	
	Map<String, dynamic> asMap({bool convertImage = false }) {
		final ret = {
//         'id': imagejournal_id,
			'rec_id': rec_id,
			//following props present for ImageRecord
			'ident': ident ?? _Path.basename(path),
			'path': path,
			'image_type': image_type,
			'description': description,
			'image_size': image_size,
			'resized_image': convertImage ? resized_image?.getBytes() : resized_image,
			'thumb_image': convertImage ? thumb_image?.getBytes() : thumb_image,
			//following props represent for filename field of FormData
			'filename': orig_name,
			'defects': defects?.map
					?.call((d) => d.asMap())
					?.toList
					?.call() ?? [],
			// fixme: db
		};
		filterNullInMap(ret);
		return ret;
	}
	
	Map<String, dynamic> asMapForUpload({bool convertImage = false}) {
		final ret = {
//         'id': imagejournal_id,
			'rec_id': rec_id,
			//following props present for ImageRecord
			'ident': ident,
			'path': path,
			'image_type': image_type,
			'description': description,
			'image_size': image_size,
			//following props present for FormData
			'filename': orig_name,
			'defects': defects?.map
					?.call((d) => d.asMap())
					?.toList
					?.call() ?? [],
			// fixme: db
			
		};
		filterNullInMap(ret);
		return ret;
	}

}





