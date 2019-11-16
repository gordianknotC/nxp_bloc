import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:PatrolParser/PatrolParser.dart';
import 'package:common/common.dart';

import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:IO/src/typedefs.dart' show TEntity;
import 'package:nxp_bloc/mediators/models/ntaglogger.dart';

import 'package:image/image.dart' as _Image;
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:path/path.dart' as _Path;
import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';

final _D = AppState.getLogger("TModels");

typedef TVoid=void Function();
typedef TDiscard=Future<bool> Function();
typedef TTakeshot=Future<StoreInf> Function();
typedef TSelectNtag=Future Function();
typedef TPickupFailed=void Function(TPickupError);

const String _THUMB_SUFFIX = '.thumb';
const String _EXTRA_SUFFIX = '.extra';

class TPickupError{
	EPickupFailed type;
	Map<String,dynamic> message;
	TPickupError(this.type, this.message);
}

enum EPickupFailed{
	duplicated, internalError
}

enum EShotSaved{
	saved, unsaved, noPatrolAssigned
}

enum EPatrolAttachment{
	attached, renewed, unattached
}

enum EShotPage{
	takingShot, browsingShot
}

class _ExtPort{
	const _ExtPort();
}

const Object external = _ExtPort();

String getImagePath(int order, String nameGetter()){
	try {
		final _order = order == 0 ? "" : ".$order";
		final dir 	 = ImageModel.RESIZED_PATH;
		return _Path.join(dir, nameGetter() + '.jpg' + _order);
	} catch (e, s) {
		print('[ERROR] TakeShotBlock._getImagePath failed: \n$s');
		rethrow;
	}
}

String getImageIdent([String _patrolRecordDate, _Image.Image _imageData, PatrolRecord _patrolRecord, StoreInf _image, bool identified = false]) {
	if (_patrolRecordDate == null  || _patrolRecord == null  || _imageData == null){
		return identified ? _Path.basename(_image.path) : null;
	}
	
	try {
		final orientation = (_imageData?.exif?.orientation == 0 || _image.path.split('-').first == 'H') ? 'H' : 'V';
		final id   				= _patrolRecord.getDevId().first;
		final imageIdent 	= ImageModel.empty().generateIdentName(
				orientation,
				_image?.statSync?.call()?.modified ?? DateTime.now(),
				id,
				_patrolRecordDate,
				identified ? _image.path : null
		);
		return imageIdent;
	} catch (e) {
		_D.error('patrolRecordDate: $_patrolRecordDate');
		_D.error('imageData: $_imageData');
		_D.error('getImageName failed: \n${StackTrace.fromString(e.toString())}');
		rethrow;
	}
}

/*
*
* 			F I L E    T Y P E S
*
*
* */
abstract class CategorizeRecognizableSketch{
	TCateTitle categoryTitle;
	bool get isCategory => categoryTitle != null;
}


class TCateTitle{
	String key;
	String val;
	TCateTitle(this.key, this.val);
	String getValue(){
		return this.val;
	}
	String getKey(){
		return this.key;
	}
	
	String toString(){
		return  'TCateTitle<$key, $val>';
	}
	@override
	bool operator ==(Object other) =>
			identical(this, other) ||
					(other is TCateTitle &&
							runtimeType == other.runtimeType &&
							key == other.key &&
							val == other.val
					);
	
	@override
	int get hashCode => key.hashCode ^ val.hashCode;
}


class TNtagLogRecord implements CategorizeRecognizableSketch{
	@override TCateTitle categoryTitle;
	@override bool get isCategory => categoryTitle != null;
	String rawLog;
	DateTime date;
	String payload;
	String dateString;
	String timeString;
	String extraLog;
	int 	 bookmark;
	int    logLineno;
	int    recordId;
	EIO 	 mode;
	
	
	PatrolRecordModel model;
	TNtagLogRecord.empty();
	
	TNtagLogRecord.category(String k, String v){
		categoryTitle = TCateTitle(k, v);
	}
	
	TNtagLogRecord.fromPatrol(PatrolRecord record, this.bookmark, this.recordId){
		model = PatrolRecordModel(record, UserState.currentUser.id);
		final date = model.date;
		final _date = NtagLogger.getTime(date);
		rawLog = "$_date read ${model.patrol.toString()}";
		extraLog = bookmark.toString();
		_init(rawLog, extraLog, logLineno:0, recordId: recordId, categoryTitle: null);
	}
	
	TNtagLogRecord.fromModel(this.model, this.bookmark, this.recordId){
		final date = model.date;
		final _date = NtagLogger.getTime(date);
		rawLog = "$_date read ${model.patrol.toString()}";
		extraLog = bookmark.toString();
		_init(rawLog, extraLog, logLineno:0, recordId: recordId, categoryTitle: null);
	}
	
	TNtagLogRecord(String log, this.extraLog, {this.logLineno, this.recordId, this.categoryTitle}){
		_init(log, extraLog, logLineno:logLineno, recordId: recordId, categoryTitle: categoryTitle);
	}
	
	bool get isEmpty{
		return rawLog == null;
	}
	
	bool isTheSame(other){
		if (other is TNtagLogRecord){
			return payload == other.payload
					&& dateString == other.dateString
					&& timeString == other.timeString;
		}
		return false;
	}
	
	void _init(String log, String extraLog, {int logLineno, int recordId, TCateTitle categoryTitle}){
		try {
			rawLog = log.trim();
			final segments = rawLog.split(' ');
			dateString     = segments[0];
			timeString     = segments[1];
			final key  = segments[2];
			final bytes= segments[3];
			payload    = segments.last;
			mode       = EIO.values.firstWhere((e) => e.toString().split('.').last == key);
			
			final dateSegments = dateString.split('/');
			final timeSegments = timeString.split(':');
			
			date = DateTime(
				int.parse(dateSegments.first),
				int.parse(dateSegments[1]),
				int.parse(dateSegments[2]),
				int.parse(timeSegments[0]),
				int.parse(timeSegments[1]),
				int.parse(timeSegments[2]),
			);
			
			if (extraLog.isNotEmpty){
				bookmark = extraLog == null
						? null
						: int.parse(extraLog.trim());
			}
			
			model = PatrolRecordModel.fromByteString(bytes);
		} catch (e, s) {
			print('[ERROR] TNtagLogRecord.TNtagLogRecord failed: \n$s');
			rethrow;
		}
	}
//<editor-fold desc="Data Methods" defaultstate="collapsed">
	@override
	bool operator ==(Object other) =>
			identical(this, other) ||
					(other is TNtagLogRecord &&
							runtimeType == other.runtimeType &&
							categoryTitle == other.categoryTitle &&
							rawLog == other.rawLog &&
							date == other.date &&
							extraLog == other.extraLog);
	
	@override
	int get hashCode =>
			categoryTitle.hashCode ^
			rawLog.hashCode ^
			date.hashCode ^
			extraLog.hashCode;
//</editor-fold>
}



abstract class ThumbRecordSketch{
	TEntity identEntity;
	TEntity get thumbEntity;
	TEntity get extraEntity;
	ImageModel imageModel;
	List<TakeshotSubRecord> bundledTakeshots;
//	List<TNtagLogRecord>    bundledNtags;
	//List<TNtagLogRecord>    attachedNtags;
	List<TNtagLogRecord>    attachedNtags;
	String description;
	int bookmark;
	int index;
}


class TakeshotSubRecord{
	TakeshotRecord delegate;
	TakeshotRecord parent;
	final StoreInf Function(String path) io;
	
	TakeshotSubRecord.shadow(TakeshotSubRecord record, TakeshotRecord parent, this.io){
		this.parent = parent;
		record.delegate.deviceid = parent.deviceid;
		delegate = TakeshotRecord.shadow(record.delegate, io);
		delegate.bundledTakeshots ??= [];
	}
	
	TakeshotSubRecord(this.parent, TEntity entity, int index, this.io){
		delegate = TakeshotRecord(entity, index, io);
		delegate.attachedNtags = parent.attachedNtags;
		delegate.deviceid  = parent.deviceid;
		delegate.bundledTakeshots ??= [];
	}
	
	TakeshotSubRecord.empty(this.parent, int index, this.io){
		delegate = TakeshotRecord.empty(index, io);
		delegate.attachedNtags = parent.attachedNtags;
		delegate.deviceid  = parent.deviceid;
		delegate.bundledTakeshots ??= [];
	}
	
	TakeshotSubRecord.fromTakeshot(this.parent, this.delegate, this.io){
		if (parent.attachedNtags.isEmpty){
			parent.attachedNtags = delegate.attachedNtags;
		}else{
			delegate.attachedNtags = parent.attachedNtags;
		}
		delegate.deviceid  = parent.deviceid;
		assert(parent.attachedNtags.isNotEmpty);
		assert(delegate.attachedNtags.isNotEmpty);
		delegate.bundledTakeshots ??= [];
	}
	
	TakeshotSubRecord.fromPatrol(this.parent, String deviceid, String patrolDate, int index, this.io){
		try {
			delegate = TakeshotRecord._fromPatrol(this.parent, io, deviceid, patrolDate, index);
			delegate.attachedNtags = parent.attachedNtags;
//			try {
//				if (deviceid != "23635")
//					throw Exception("temp exception!!");
//			} catch (e, s) {
//				print('[ERROR] TakeshotReactSketch.pickBundleImageAction failed: $e\n$s');
//				rethrow;
//			}
			delegate.bundledTakeshots ??= [];
		} catch (e, s) {
			print('[ERROR] TakeshotSubRecord.fromPatrol failed: $e\n$s');
			rethrow;
		}
	}
	
	TakeshotSubRecord.fromMap(Map<String,dynamic> data, int index, this.io){
		delegate = TakeshotRecord.empty(index, io)
			.._fromMap(data);
		delegate.bundledTakeshots ??= [];
	}
	
	TakeshotSubRecord.fromRawImageFIle(this.parent, TEntity entity, int order, _Image.Image imageData, this.io){
		final path = getImagePath(order, () => getImageIdent(
				parent.patrolDate, imageData, parent.attachedNtags.first.model.patrol, io(entity.path)
		));
		
		_D.debug('takeshotRecord init');
		delegate = TakeshotRecord(TEntity(entity: File(path)), order, io)
			..attachedNtags = parent.attachedNtags
			..imageModel.resized_image = imageData;
		delegate.bundledTakeshots ??= [];
	}
	
	TEntity get identEntity => delegate.identEntity;
	TEntity get thumbEntity => delegate.thumbEntity;
	
	String get description {
		return delegate.description;
	}
	
	void set description(String v) {
		delegate.description = v;
	}
	
	List<IJOptionModel> get defects 				=> delegate.defects;
	void set defects(List<IJOptionModel> v) => delegate.defects = v;
	
	
	
	ImageModel get imageModel {
		return delegate.imageModel;
	}
	
	String get deviceid {
		return delegate.deviceid;
	}
	
	String get patrolDate {
		return delegate.patrolDate;
	}
	
	String get imageDate {
		return delegate.imageDate;
	}
	
	String get deviceType {
		return delegate.deviceType;
	}
	
	String get deviceName {
		return delegate.deviceName;
	}
	String get deviceArea {
		return delegate.deviceArea;
	}
	
	TEntity get entity {
		return delegate.identEntity;
	}
	
	Map<String,dynamic> Function() get asExtraMap {
		return delegate.asExtraMap;
	}
}


class TakeshotRecord implements ThumbRecordSketch, CategorizeRecognizableSketch {
	@external @override List<TakeshotSubRecord>  bundledTakeshots; // bundled by other takeshotRecord
	@override TEntity identEntity;
	@override TEntity get thumbEntity => TEntity(entity: File(identEntity.path + _THUMB_SUFFIX));
	@override TEntity get extraEntity => TEntity(entity: File(identEntity.path + _EXTRA_SUFFIX));
	
	@external TEntity journalEntity;
	
	@override List<TNtagLogRecord> attachedNtags = [];
	@override ImageModel imageModel;
	@override int 		bookmark 		= 0;
	@override int     index;
	
	@override TCateTitle categoryTitle;
	@override bool get isCategory => categoryTitle != null;
	
	String _description = '';
	@override String get description => _description;
	@override set description(String v) {
		_description = v;
		imageModel?.description = v;
	}
	
	final StoreInf Function(String path) io;
	
	/*bool isTheSame(TakeshotRecord other){
		return identEntity.path == other.identEntity.path
				&& imageModel.theSame(other.imageModel)
	}*/
	@external List<IJOptionModel> _compoundDefects = [];
	List<IJOptionModel> get compoundDefects{
		return _compoundDefects;
	}
	set compoundDefects (List<IJOptionModel> v){
		_compoundDefects = v;
		_D.debug('set compoundDefects to: ${v.map((e) => e.name )}');
		assert(v != null);
	}
	
	List<IJOptionModel> _defects = [];
	List<IJOptionModel> get defects {
		final result 				= _defects ?? imageModel?.defects ?? [];
		_defects 						= result;
		imageModel?.defects = result;
		return result;
	}
	set defects(List<IJOptionModel> v){
		_defects = v;
		imageModel?.defects =	v;
	}

//	bool _extraInitialized = false;
	bool get extraInitialized => imageModel != null && attachedNtags.isNotEmpty && bundledTakeshots != null;
	void resetInitialized() {
		imageModel = null;
		attachedNtags = [];
		bundledTakeshots = null;
	}
	
	String orientation;
	String deviceid;
	String patrolDate;
	String imageDate;
	String get deviceType => attachedNtags.isEmpty ? null : attachedNtags.first.model.patrol.getType();
	String get deviceName => attachedNtags.isEmpty ? null : attachedNtags.first.model.patrol.getExtraInfoOfName(Msg.codec);
	String get deviceArea => attachedNtags.isEmpty ? null : attachedNtags.first.model.patrol.getExtraInfoOfArea(Msg.codec);
	
	// create from map
	bool get extraNotInitialized => extraInitialized == false;
	
	// untested:
	TakeshotRecord.fromMap( Map<String, dynamic> data, this.index, Completer completer, this.io ){
		try {
			int receivedCounter = 0;
			int imagesTobeProcess = 0;
			void onReceiveImage(_Image.Image resized) {
				receivedCounter ++;
				if (imagesTobeProcess >= receivedCounter) {
					if (!completer.isCompleted)
						completer.complete();
				}}
			bookmark 		= data['bookmark'] as int;
			description = data['description'] as String;
			// -----------------------------------------
			final rawlog 	 = List<String>.from(data['ntaglogs']      as List).first;
			final extraLog = List<int>   .from(data['ntaglogsExtra'] as List).first ?? bookmark;
			attachedNtags  = [TNtagLogRecord(rawlog, extraLog.toString())];
			deviceid       = attachedNtags.first.model.patrol.getDevId().first.toString();
			final takeshots 	= List<Map<String, dynamic>>.from(data['takeshotRecords'] as List ?? []);
			final imageData 	= data['imageModel'] as Map<String, dynamic>;
			imagesTobeProcess = 1 + takeshots.length;
			imageModel  = ImageModel.fromMap(imageData, onReceiveImage, (e) => throw Exception(e));
			defects 		= imageModel.defects;
			identEntity = TEntity(entity: File(imageModel.path));
			_identEntityInit();
			if (takeshots.isEmpty)
				return;
			// ------------------------------------------
			final subshots 	 = List.generate(takeshots.length, (i) => TakeshotRecord.fromMap(takeshots[i], i + 1, completer, io)).toList();
			bundledTakeshots = List.generate(subshots.length, (i) {
				final subrecord =  TakeshotSubRecord.fromTakeshot(this, subshots[i], io);
				subrecord.delegate.identEntity = TEntity(entity: File(subrecord.imageModel.path));
				return subrecord;
			});
		} catch (e, s) {
			print('[ERROR] TakeshotRecord.fromMap failed: $e\n$s');
			print('data: $data');
			completer.completeError(e);
			rethrow;
		}
	}
	
	TakeshotRecord.category(String k, String v, this.io){
		categoryTitle = TCateTitle(k, v);
	}
	
	TakeshotRecord.empty(this.index, this.io){
		imageModel = ImageModel.empty();
	}
	
	TakeshotRecord._fromPatrol(TakeshotRecord record, this.io, this.deviceid, this.patrolDate, this.index){
		try {
		} catch (e, s) {
			print('[ERROR] TakeshotRecord.fromPatrol failed: $e\n$s');
			rethrow;
		}
	}
	
	TakeshotRecord(TEntity ident, this.index, this.io, {_Image.Image imageData}){
		init(ident, imageData: imageData);
	}
	
	// untested:
	TakeshotRecord.fromExtra(TEntity ident, this.io, {_Image.Image imageData}){
		index = 0;
		init(ident, imageData: imageData);
		extraInit();
//		imageModel.imageInit();
		assert(this != null);
	}
	
	
	TakeshotRecord.shadow(TakeshotRecord record, this.io){
		try {
			_D.debug('shadow.deviceid1: ${record.deviceid}, set compounds from shadow');
			compoundDefects = List.from(record.compoundDefects);
			_defects      = List.from(record.defects);
			_description  = record._description;
			bookmark      = record.bookmark;
			categoryTitle = record.categoryTitle;
			deviceid      = record.deviceid;
			identEntity   = record.identEntity;
			imageDate     = record.imageDate;
			//imageModel  = ImageModel.clone(record.imageModel);
			imageModel    = record.imageModel;
			defects       = record.imageModel.defects;
			index         = record.index;
			orientation   = record.orientation;
			patrolDate    = record.patrolDate;
			attachedNtags   = List.from(record.attachedNtags);
			bundledTakeshots= List.from(record.bundledTakeshots.map((s){
				return TakeshotSubRecord.shadow(s, this, io);
			}));
			
			_D.debug('shadow.deviceid2: ${deviceid}, identEntity: $identEntity');
			_D.debug('shadow.deviceid3: ${record.deviceid}, identEntity: ${record.identEntity}');
			
		} catch (e, s) {
			print('[ERROR] TakeshotRecord.shadow failed:$e \n$s');
			rethrow;
		}
	}
	
	void _identEntityInit(){
		try {
			final segments = _Path.basename(identEntity.path).split('-');
			orientation = segments [0];
			deviceid 		= segments [1];
			patrolDate 	= segments [2];
			imageDate 	= segments [3].split('.').first;;
		} catch (e, s) {
			print('[ERROR] TakeshotRecord._identEntityInit failed: \nentity: ${identEntity.path}\n$e\n$s');
			rethrow;
		}
	}
	
	void init(TEntity ent, {_Image.Image imageData}){
		final rectifiedPath = rectifyInitialEntityPath(ent);
		identEntity 			  = TEntity(entity: File(rectifiedPath));
//		thumbEntity = TEntity(entity: File(entity.path + _THUMB_SUFFIX));
//		extraEntity = TEntity(entity: File(entity.path + _EXTRA_SUFFIX));
		bundledTakeshots = [];
		final segments = _Path.basename(identEntity.path).split('-');
		try {
			_identEntityInit();
			imageModel 	= ImageModel.fromResizedImage (imageData, description, identEntity.path, ImageModel.RESIZE, int.parse(deviceid), patrolDate, rec_id: index);
			if (ent.path.endsWith('.extra')){
			}
		} catch (e, s) {
			_D.error('[ERROR] TakeShotRecord.TakeShotRecord failed: \n$s');
			_D.error('thumbEntity: ${thumbEntity.path}, ${thumbEntity.entity.existsSync()}');
			_D.error('extraEntity: ${extraEntity.path}, ${extraEntity.entity.existsSync()}');
			_D.error('segments: $segments');
			rethrow;
		}
	}
	
	String rectifyInitialEntityPath(TEntity ent){
		return ent.path.split('.jpg').first + '.jpg';
	}
	
	DateTime parseDateString(String datestring){
		final s = datestring.substring(0,8);
		return DateTime(
				int.parse(s.substring(0, 4)),
				int.parse(s.substring(4, 6)),
				int.parse(s.substring(6, 8)) );
	}
	
	String getImageIdent(int patrolId, String date){
		final im = ImageModel.empty();
		final isIdentified = im.isIdentifiedPath(identEntity.path)
				? identEntity.path
				: null;
		return ImageModel.empty().generateIdentName(
				orientation, io(identEntity.path).statSync().modified, patrolId, date, isIdentified);
	}
	
	String getImagePath(int id, String date, int order){
		final suffix = order == 0 ? "" : order.toString();
		return _Path.join(ImageModel.RESIZED_PATH, getImageIdent(id, date) + '.jpg$suffix', );
	}
	
	Future<bool> rename(int id, String date, int imageOrder){
		final completer = Completer<bool>();
		final idents = imageOrder == 0
				? [identEntity, thumbEntity, extraEntity]
				: [identEntity, thumbEntity];
		final newpath = getImagePath(id, date, imageOrder);
		
		List.generate(idents.length, (i){
			final ident = idents[i];
			final subname = ident.path.split('.').last;
			final path = subname.startsWith('jpg')
					? newpath
					: newpath + '.$subname';
			
			io(ident.path).rename(path).then((file){
				if (subname.startsWith('jpg'))
					init(TEntity(entity: File(file.path)));
				if (i >= idents.length - 1)
					completer.complete(true);
			});
		});
		return completer.future;
	}
	
	void _renameTakeshots(int id, String date){
		assert (identEntity != null && imageModel.resized_image != null);
		final shots = <dynamic>[this] + bundledTakeshots;
		List.generate(shots.length, (i){
			final _shot = shots[i];
			final newpath = getImagePath(id, date, i);
			if (i == 0){
				rename(id, date, 0).then((_) => dumpExtra());
			}else{
				final shot = _shot as TakeshotSubRecord;
				shot.delegate.rename(id, date, i);
			}
		});
	}
	
	/*
	void setBundledNtags(List<TakeshotRecord> records){
		bundledNtags  = records.map((r) => r.attachedNtags.first).toSet().toList();
	}
	*/
	
	void setBundledTakeshots(List<TEntity> bundledEntities){
		bundledTakeshots = List.generate(bundledEntities.length, (i) => TakeshotSubRecord(this, bundledEntities[i], i + 1, io));
//		bundledTakeshots = bundledEntities.map((e) => TakeshotSubRecord(this, e)).toList();
	}
	
	// untested: unused:
	void addBundleImage(String path){
		final index = bundledTakeshots.length + 1;
		bundledTakeshots.add(TakeshotSubRecord(this, TEntity(entity: File(path)), index, io));
	}
	void removeBundleImage(String path){
		bundledTakeshots.removeWhere((t) => t.entity.path == path);
	}
	
	Future<ImageModel> allEntitiesInit(){
		if (extraNotInitialized)
			extraInit();
		return imageModel.imageInit();
	}
	
	Map<String,dynamic> extraInit(){
		if (identEntity != null && extraEntity.entity.existsSync()){
			String rawstring;
			Map<String, dynamic> data;
			try {
				rawstring = File(extraEntity.path).readAsStringSync();
				data 			= jsonDecode(rawstring) as Map<String, dynamic>;
				_fromMap(data);
//			extraInitialized = true;
				return data;
			} catch (e, s) {
				print('[ERROR] TakeshotRecord.extraInit failed: $e\n$s');
				print('[ERROR] unexpected data: $data');
				rethrow;
			}
		}else{
			if (attachedNtags.isEmpty && !isCategory){
				_D.error('initialized: ${extraInitialized}');
				_D.error('entity		 : ${identEntity}, exists(${identEntity.entity.existsSync()})');
				_D.error('extraEntity: ${extraEntity}, exists(${extraEntity.entity.existsSync()})');
				throw Exception('either extraEntity is not exists or ntag is not being attached!!');
			}
		}
	}
	
	Map<String,dynamic> asExtraMap(){
		try {
			final subRecords = bundledTakeshots.map((e){
				return e.asExtraMap();
			}).toList();
			
			return {
				'bookmark'		: bookmark,
				'description'	: description,
				'ntaglogs'		: attachedNtags.map((n) => n.rawLog).toSet().toList(),
				'ntaglogsExtra' : attachedNtags.map((n) => n.bookmark).toSet().toList(),
				'imageModel'	  : imageModel.asMapForUpload(),
				'bundledImages' : bundledTakeshots.map((e) => e.entity.path).toSet().toList(),
				'takeshotRecords': _uniqueTakeshot(subRecords)
			};
		} catch (e, s) {
			print('[ERROR] TakeshotRecord.asExtraMap failed: $e\n$s');
			rethrow;
		}
	}
	
	List<Map<String,dynamic>> _uniqueTakeshot(List<Map<String,dynamic>> data){
		return data.fold<List<Map<String,dynamic>>>
			([], (initial, b){
			if (initial.any((a) => _isTheSameTakeshot(a, b)))
				return initial;
			return initial + [b];
		});
	}
	
	bool _isTheSameTakeshot(Map<String,dynamic> takeshotDataA, Map<String,dynamic> takeshotDataB){
		final identA = takeshotDataA["imageModel"]['ident'] as String;
		final identB = takeshotDataB["imageModel"]['ident'] as String;
		final descA = takeshotDataA["imageModel"]['description'] as String;
		final descB = takeshotDataB["imageModel"]['description'] as String;
		return identA == identB && descA == descB;
	}
	
	void _fromMap(Map<String,dynamic> data){
		try {
			bookmark 		= (data['bookmark'] ?? 0) as int;
			description = (data['description'] ?? "") as String;
			
			final attachedLogs 			= (data['ntaglogs'] as List).toSet().toList();
			final attachedLogsExtra = (data['ntaglogsExtra'] as List).toSet().toList();
			final imageData 				= imageModel.resized_image;
			
			final rawmodel = data['imageModel'] as Map<String,dynamic>;
			assert(rawmodel['ident'] != null, 'invalid serializable for imageModel: $data');
			
			imageModel = ImageModel.fromMap(rawmodel, null, null, initialize: false)
				..resized_image = imageData;
			defects = imageModel.defects;
			
			assert(imageModel.path != null, "data[imageModel]: ${data['imageModel']}, data: $data");
			identEntity ??= TEntity(entity: File(imageModel.path));
			imageModel.description = description;
			
			assert(attachedLogs.length == attachedLogsExtra.length);
			attachedNtags = List.generate(attachedLogs.length,
							(i) => TNtagLogRecord(attachedLogs[i] as String, attachedLogsExtra[i].toString()));
			
			final takeshotRecordsdata = _uniqueTakeshot(List<Map<String,dynamic>>.from(data['takeshotRecords'] as List));
			bundledTakeshots = List.generate(takeshotRecordsdata.length, (i) => TakeshotSubRecord.fromMap(takeshotRecordsdata[i], i + 1, io));
		} catch (e, s) {
			print('[ERROR] TakeshotRecord._fromMap failed: $e \n$s');
			FN.prettyPrint(data);
			rethrow;
		}
		
	}
	
	void removeNtags(Set<TNtagLogRecord> removed){
		if (extraNotInitialized)
			extraInit();
		attachedNtags.removeWhere((attached) => removed.any((r) => r.isTheSame(attached)));
		dumpExtra();
	}
	
	// untested:
	void addNtags(Set<TNtagLogRecord> appended){
		if (extraNotInitialized)
			extraInit();
		final newAppended = appended.where((append) => attachedNtags.every((a) => !a.isTheSame(appended))).toSet();
		if (newAppended.isNotEmpty){
			if (attachedNtags.isEmpty){
				attachedNtags.addAll(appended);
				_renameTakeshots(attachedNtags.first.recordId, attachedNtags.first.dateString);
			} else {
				attachedNtags.addAll(newAppended);
			}
		}
		dumpExtra();
	}
	
	Future<bool> dumpExtra({Map<String,dynamic> dumpData}){
		try {
			if (extraNotInitialized && dumpData == null)
				extraInit();
			final String content = jsonEncode(dumpData ?? asExtraMap());
			io(extraEntity.path).writeSync(content, encrypt: false);
			return Future.value(true);
		} catch (e, s) {
			print('[ERROR] TakeShotRecord.dumpExtra failed: \n$s');
			rethrow;
		}
	}
	
	void del(){
		if (identEntity?.entity?.existsSync() ?? false)
			io(identEntity.path).deleteSync();
		if (extraEntity?.entity?.existsSync() ?? false)
			io(extraEntity.path).deleteSync();
		if (thumbEntity?.entity?.existsSync() ?? false)
			io(thumbEntity.path).deleteSync();
		
		bundledTakeshots.forEach((e){
			if (e.identEntity?.entity?.existsSync() ?? false)
				io(e.identEntity.path).deleteSync();
			if (e.thumbEntity?.entity?.existsSync() ?? false)
				io(e.thumbEntity.path).deleteSync();
		});
		
		bundledTakeshots?.clear();
//		bundledNtags?.clear();
		attachedNtags?.clear();
//		extraInitialized =false;
	}


//<editor-fold desc="Data Methods" defaultstate="collapsed">











//</editor-fold>
}




