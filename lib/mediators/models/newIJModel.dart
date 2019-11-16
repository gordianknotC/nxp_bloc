import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:meta/meta.dart';
import 'package:nxp_bloc/consts/http.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:IO/src/io.dart';

import 'package:nxp_bloc/mediators/models/imagejournal_model.dart';
import 'package:nxp_bloc/mediators/models/takeshotModel.dart';
import 'package:nxp_bloc/mediators/models/defectsService.dart';

import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:path/path.dart' as _Path;
import 'package:image/image.dart';





// Include generated file


final _D = AppState.getLogger("DefectServ");
final ntaglogs = [
	"2019/08/08 13:52:33 read 990210080f000119c742170b216a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000",
	"2019/08/09 12:52:33 read 990220080f000129c742270b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000",
	"2019/08/10 11:52:33 read 990230080f000139c742370b236a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000",
];

final _streamFields = {
	"id": "10000001",
	"title": "",
	"summary": "",
	"conclusion": "",
	"selected_options": "[0]",
	"device_id": "23635",
	"created": "2019-10-08T00:49:56.725243Z",
	"modified": "2019-10-08T00:49:56.725243Z",
	"rec_num": "4",
	"patrol_id": "null",
	"rec0_takeshot.bookmark": "0",
	"rec0_takeshot.description": "\"\"",
	"rec0_takeshot.ntaglogs": "[\"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000\"]",
	"rec0_takeshot.ntaglogsExtra": "[0]",
	"rec0_takeshot.imageModel.rec_id": "0",
	"rec0_takeshot.imageModel.ident": "\"V-23635-20190808-20190905162333\"",
	"rec0_takeshot.imageModel.path": "\".\\\\test\\\\assets\\\\resized\\\\V-23635-20190808-20190905162333.jpg\"",
	"rec0_takeshot.imageModel.description": "",
	"rec0_takeshot.imageModel.image_size": "[768,300]",
	"rec0_takeshot.imageModel.filename": "\"V-23635-20190808-20190905162333.jpg\"",
	"rec0_takeshot.imageModel.defects": "[{\"id\":2,\"name\":\"case broken\",\"description\":\"case broken\",\"certificated\":true,\"imageJournals\":[1,1,1,1,2,6,7,7,8],\"created\":\"2019-04-17T00:49:42.711183Z\",\"modified\":\"2019-05-07T12:18:57.621930Z\"}]",
	"rec0_takeshot.bundledImages": "[\".\\\\test\\\\assets\\\\resized\\\\V-23635-20190808-2019090516255.jpg\",\".\\\\test\\\\assets\\\\resized\\\\V-23635-20190808-20190904234429.jpg\",\".\\\\test\\\\assets\\\\resized\\\\V-23635-20190808-2019090423450.jpg\"]",
	"rec1_takeshot.bookmark": "0",
	"rec1_takeshot.description": "\"\"",
	"rec1_takeshot.ntaglogs": "[\"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000\"]",
	"rec1_takeshot.ntaglogsExtra": "[0]",
	"rec1_takeshot.imageModel.ident": "\"V-23635-20190808-2019090516255\"",
	"rec1_takeshot.imageModel.path": "\"/sdcard/Documents/assets/resized/V-23635-20190808-2019090516255.jpg\"",
	"rec1_takeshot.imageModel.image_type": "\"jpg\"",
	"rec1_takeshot.imageModel.description": "",
	"rec1_takeshot.imageModel.image_size": "[768,336]",
	"rec1_takeshot.imageModel.filename": "\"V-23635-20190808-2019090516255.jpg\"",
	"rec1_takeshot.imageModel.defects": "[{\"id\":1,\"name\":\"oil leakage\",\"description\":\"found oil leakage trackings\",\"certificated\":true,\"imageJournals\":[2,3,4,7,7],\"created\":\"2019-04-17T00:49:42.711183Z\",\"modified\":\"2019-05-07T12:18:57.617934Z\"}]",
	"rec1_takeshot.bundledImages": "[]",
	"rec2_takeshot.bookmark": "0",
	"rec2_takeshot.description": "\"\"",
	"rec2_takeshot.ntaglogs": "[\"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000\"]",
	"rec2_takeshot.ntaglogsExtra": "[0]",
	"rec2_takeshot.imageModel.ident": "\"V-23635-20190808-20190904234429\"",
	"rec2_takeshot.imageModel.path": "\"/sdcard/Documents/assets/resized/V-23635-20190808-20190904234429.jpg\"",
	"rec2_takeshot.imageModel.image_type": "\"jpg\"",
	"rec2_takeshot.imageModel.description": "",
	"rec2_takeshot.imageModel.image_size": "[386,234]",
	"rec2_takeshot.imageModel.filename": "\"V-23635-20190808-20190904234429.jpg\"",
	"rec2_takeshot.imageModel.defects": "[{\"id\":3,\"name\":\"unKnown\",\"description\":\"animal threatening\",\"certificated\":false,\"imageJournals\":[4,4,4,5,5,8,9],\"created\":\"2019-05-07T11:21:38.537217Z\",\"modified\":\"2019-05-07T12:18:57.624924Z\"}]",
	"rec2_takeshot.bundledImages": "[\".\\\\test\\\\assets\\\\resized\\\\V-23635-20190808-2019090423450.jpg\"]",
	"rec3_takeshot.bookmark": "0",
	"rec3_takeshot.description": "\"\"",
	"rec3_takeshot.ntaglogs": "[\"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000\"]",
	"rec3_takeshot.ntaglogsExtra": "[0]",
	"rec3_takeshot.imageModel.ident": "\"V-23635-20190808-2019090423450\"",
	"rec3_takeshot.imageModel.path": "\"/sdcard/Documents/assets/resized/V-23635-20190808-2019090423450.jpg\"",
	"rec3_takeshot.imageModel.image_type": "\"jpg\"",
	"rec3_takeshot.imageModel.description": "",
	"rec3_takeshot.imageModel.image_size": "[674,560]",
	"rec3_takeshot.imageModel.filename": "\"V-23635-20190808-2019090423450.jpg\"",
	"rec3_takeshot.imageModel.defects": "[{\"id\":794,\"name\":\"oil leakage\",\"description\":\"found oil leakage trackings\",\"certificated\":true,\"imageJournals\":[],\"created\":\"2019-05-17T03:22:57.810423Z\",\"modified\":\"2019-05-17T03:22:57.810423Z\"}]",
	"rec3_takeshot.bundledImages": "[]"
}
;

final _fieldsToMap = {
	"id": "10000001",
	"title": "",
	"summary": "",
	"conclusion": "",
	"selected_options": "[0]",
	"device_id": "23635",
	"created": "2019-10-07T23:29:44.540130Z",
	"modified": "2019-10-07T23:29:44.540130Z",
	"rec_num": "4",
	"patrol_id": "null",
	"takeshot": [
		{
			"bookmark": 0,
			"description": "",
			"ntaglogs": [
				"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000"
			],
			"ntaglogsExtra": [0],
			"imageModel": {
				"rec_id": 0,
				"ident": "V-23635-20190808-20190905162333",
				"path": ".\\test\\assets\\resized\\V-23635-20190808-20190905162333.jpg",
				"description": "",
				"image_size": [768, 300],
				"filename": "V-23635-20190808-20190905162333.jpg",
				"defects": [
					{
						"id": 2,
						"name": "case broken",
						"description": "case broken",
						"certificated": true,
						"imageJournals": [1, 1, 1, 1, 2, 6, 7, 7, 8],
						"created": "2019-04-17T00:49:42.711183Z",
						"modified": "2019-05-07T12:18:57.621930Z"
					}
				]
			},
			"bundledImages": [
				".\\test\\assets\\resized\\V-23635-20190808-2019090516255.jpg",
				".\\test\\assets\\resized\\V-23635-20190808-20190904234429.jpg",
				".\\test\\assets\\resized\\V-23635-20190808-2019090423450.jpg"
			],
			"takeshotRecords": []
		},
		{
			"bookmark": 0,
			"description": "",
			"ntaglogs": [
				"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000"
			],
			"ntaglogsExtra": [0],
			"imageModel": {
				"ident": "V-23635-20190808-2019090516255",
				"path": "/sdcard/Documents/assets/resized/V-23635-20190808-2019090516255.jpg",
				"image_type": "jpg",
				"description": "",
				"image_size": [768, 336],
				"filename": "V-23635-20190808-2019090516255.jpg",
				"defects": [
					{
						"id": 1,
						"name": "oil leakage",
						"description": "found oil leakage trackings",
						"certificated": true,
						"imageJournals": [2, 3, 4, 7, 7],
						"created": "2019-04-17T00:49:42.711183Z",
						"modified": "2019-05-07T12:18:57.617934Z"
					}
				]
			},
			"bundledImages": [],
			"takeshotRecords": []
		},
		{
			"bookmark": 0,
			"description": "",
			"ntaglogs": [
				"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000"
			],
			"ntaglogsExtra": [0],
			"imageModel": {
				"ident": "V-23635-20190808-20190904234429",
				"path": "/sdcard/Documents/assets/resized/V-23635-20190808-20190904234429.jpg",
				"image_type": "jpg",
				"description": "",
				"image_size": [386, 234],
				"filename": "V-23635-20190808-20190904234429.jpg",
				"defects": [
					{
						"id": 3,
						"name": "unKnown",
						"description": "animal threatening",
						"certificated": false,
						"imageJournals": [4, 4, 4, 5, 5, 8, 9],
						"created": "2019-05-07T11:21:38.537217Z",
						"modified": "2019-05-07T12:18:57.624924Z"
					}
				]
			},
			"bundledImages": [".\\test\\assets\\resized\\V-23635-20190808-2019090423450.jpg"],
			"takeshotRecords": []
		},
		{
			"bookmark": 0,
			"description": "",
			"ntaglogs": [
				"2019/08/08 23:52:33 read 990210080f000109c742470b226a63000000010004005c530000000000000000a5bba4e5a6720000000000000000000000000000000000000000000000000000bf4eadbbaef00000000000000000000000000000000000000000000000000000"
			],
			"ntaglogsExtra": [0],
			"imageModel": {
				"ident": "V-23635-20190808-2019090423450",
				"path": "/sdcard/Documents/assets/resized/V-23635-20190808-2019090423450.jpg",
				"image_type": "jpg",
				"description": "",
				"image_size": [674, 560],
				"filename": "V-23635-20190808-2019090423450.jpg",
				"defects": [
					{
						"id": 794,
						"name": "oil leakage",
						"description": "found oil leakage trackings",
						"certificated": true,
						"imageJournals": [],
						"created": "2019-05-17T03:22:57.810423Z",
						"modified": "2019-05-17T03:22:57.810423Z"
					}
				]
			},
			"bundledImages": [],
			"takeshotRecords": []
		}
	]
};

/*
*
* 				R E A C T     S T A T E M A N A G E R ..
*
*
*/


enum EOPtActions {
	add,
	edit,
	del,
}

class DescOptionHistoryRecord {
	int get id => option.id;
	IJOptionModel get option => records?.last?.value;
	List<MapEntry<EOPtActions, IJOptionModel>> records;
	
	DescOptionHistoryRecord.empty();
	
	DescOptionHistoryRecord(IJOptionModel opt, EOPtActions act) {
		init(opt, act);
	}
	
	void init(IJOptionModel opt, EOPtActions act) {
		switch (act) {
			case EOPtActions.add:
				add(opt, act);
				break;
			case EOPtActions.edit:
				edit(opt, act);
				break;
			case EOPtActions.del:
				del(opt, act);
				break;
		}
	}
	
	IJOptionModel getOptionByAction(EOPtActions act) {
		return records
				.firstWhere((e) => e.key == act, orElse: () => null)
				?.value;
	}
	
	void add(IJOptionModel option, EOPtActions action) {
		records ??= [];
		records.add(MapEntry(action, IJOptionModel.clone(option)));
	}
	
	void edit(IJOptionModel option, EOPtActions action) {
		records ??= [];
		records.removeWhere((e) => e.key == action);
		records.add(MapEntry(action, IJOptionModel.clone(option)));
	}
	
	void del(IJOptionModel option, EOPtActions action) {
		records ??= [];
		records.removeWhere((e) => e.key == action);
		records.add(MapEntry(action, IJOptionModel.clone(option)));
	}
	
	Map<String, Map<String, List<Map<String, dynamic>>>> asMap() {
		final Map<String, List<Map<String, dynamic>>> result = {};
		records.forEach((record) {
			result[record.key.toString()] ??= [];
			result[record.key.toString()].add(record.value.asMap());
		});
		return {option.id.toString(): result};
	}
}



class PseudoNewImageJournalModel extends NewImageJournalModel {
	PseudoNewImageJournalModel(StoreInf Function(String path) io, String journalSavePath, String defectSavePath, int userid, TakeshotRecord record,
			List<IJOptionModel> defects, int jid, int order, TEntity entity) : super(io, journalSavePath, defectSavePath, userid, record: record,
			compoundDefects: defects,
			imagejournal_id: jid,
			order: order,
			entity: entity);
	
	PseudoNewImageJournalModel.category(TCateTitle categoryTitle, StoreInf Function(String path) io) : super.category(categoryTitle, io);
	
	PseudoNewImageJournalModel.fromMap(Map<String, dynamic> data, Completer completer, TEntity entity, StoreInf Function(String path) io,
			String journalSavePath, String defectSavePath) : super.fromMap(data, completer, entity, io, journalSavePath, defectSavePath);
}


class NewImageJournalModel extends ImageJournalModel implements CategorizeRecognizableSketch {
	@override int imagejournal_id;
	static int _newRboundId = 100000000;
	static const int baseRboundId = 100000000;
	List<IJOptionModel> compoundDefects; // fixme:
//	List<IJOptionModel> get compoundDefects {
//		selected_options...
//	}
	TEntity entity;
	TakeshotRecord record;
	List<NewImageJournalModel> submodels;
	int order;
	
	final StoreInf Function(String path) io;
	final String defectSavePath;
	final String journalSavePath;
	final int userid;
	
	DefectsServiceSketch defectService() {
		return DefectsService.F(io, defectSavePath);
	}
	
	void _init() {
		try {
			order ??= 0;
			device_id = int.parse(record.deviceid);
			imagejournal_id ??= _newRboundId ++;
			// -----------------------------------
			final options = defectService().options;
			selected_options = (compoundDefects != null || selected_options != null)
				?	compoundDefects?.map((o) => o.id)?.toList?.call() ?? selected_options
				: record.defects.map((o) => options.indexWhere((opt) => opt.sameTag(o)))
						.where((x) => x != -1).toList();
			patrol = record.attachedNtags.first.model;
			bookmark = record.bookmark;
			if (order == 0) {
				final subsets = record.bundledTakeshots;
				if (subsets != null)
					submodels = List.generate(subsets.length, (i) {
						final subrecord = subsets[i].delegate;
						final result = NewImageJournalModel(io, journalSavePath, defectSavePath, userid, compoundDefects: subrecord.defects,
							record: subrecord,
							imagejournal_id: imagejournal_id,
							order: i + 1);
						return result;
					});
			} else {
				submodels = [];
			}
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel._init failed: $e\n$s');
			rethrow;
		}
	}
	
	NewImageJournalModel.category(this.categoryTitle, this.io, [this.defectSavePath = null, this.journalSavePath = null]): userid = null;
	
	NewImageJournalModel(this.io, this.journalSavePath, this.defectSavePath, this.userid,
			{@required this.record, this.compoundDefects, this.imagejournal_id, this.order = 0, this.entity}) {
		if (order == 0) {
			//assert(record.extraEntity.entity.existsSync(), "extra ${record.extraEntity} not exists");
		}
		if (compoundDefects != null) {
			_D.debug('set compounds from IJModel');
			record.compoundDefects = compoundDefects;
		}
		_init();
		var pass;
	}
	
	factory NewImageJournalModel.fromEntity(TEntity entity, Completer completer, StoreInf io(String path), String journalSavePath,
			String defectSavePath, String decryptor(String t)){
		final text = File(entity.path).readAsStringSync();
		final data = jsonDecode(decryptor(text)) as Map<String, dynamic>;
		return NewImageJournalModel.fromMap(
			data, completer,  entity, io, journalSavePath, defectSavePath, 0,);
	}
	
	Map<String, dynamic> recordsToTakeshot(Map<String, dynamic> data, Completer completer) {
//		data;
//		TakeshotRecord.fromMap(newData, 0, completer, io);
		return data;
	}
	
	NewImageJournalModel.fromResponseBody(Map<String, dynamic> data, Completer completer, this.entity, this.io, this.journalSavePath,
			this.defectSavePath, [this.order = 0]): userid = data["user_id"] as int {
		try {
			data['recs'] 		 = data['image_records'];
			data['takeshot'] = data['recs'];
			data['takeshot'].forEach((a){
				a['ntaglogs'] =  data["image_records"][0]["ntaglogs"];
				a['ntaglogsExtra'] = [bookmark];
			});
			// todo: read
			_fromResponseMap(data, completer);
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel.fromResponseBody failed: $e\n$s');
			rethrow;
		}
	}
	
	NewImageJournalModel.fromMap(Map<String, dynamic> data, Completer completer, this.entity, this.io, this.journalSavePath, this.defectSavePath,
			[this.order = 0]) : userid = data["user_id"] as int, super.fromMap(data){
		try {
			_fromMap(data, completer);
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel.fromMap failed: $e\n$s');
			rethrow;
		}
	}
	
	void _fromMap(Map<String, dynamic> data, Completer completer){
		final _completer = Completer();
		title     = data['title'] as String;
		summary   = data['summary'] as String;
		conclusion= data['conclusion'] as String;
		device_id = data['device_id'] as int;
		bookmark ??= 0;
		if (data['id'] != null){
			final _id = data['id'] as int;
			if (_id >= baseRboundId)
				var pass;
			else
				imagejournal_id = _id;
		}
		// ----------------------------------
		//final takeshots  = List<Map<String,dynamic>>.from(data['takeshot'] as List);
		final takeshot = data['takeshot'] as Map<String,dynamic>;
		record = TakeshotRecord.fromMap(takeshot , order, _completer, io);
		final options  = defectService().options;
		// ----------------------------
		if (options?.isEmpty ?? true) {
			defectService().readFromDisk().then((list) {
				_D.debug('set compounds from IJModel.fromMap, ${data['selected_options']}');
				compoundDefects = selected_options.isNotEmpty
						? selected_options.map((i) => list.firstWhere((opt) => opt.id == i, orElse: () => null)).where((e) => e != null).toList()
						: [];
				record.compoundDefects = compoundDefects;
				if (_completer.isCompleted) {
					completer.complete();
				} else {
					_completer.future.then((_) {
						completer.complete();
					});
				}
			});
		} else {
			_D.debug('set compounds from IJModel.fromMap, ${data['selected_options']}');
			compoundDefects = selected_options.isNotEmpty ? selected_options.map((i) => options.firstWhere((opt) => opt.id == i, orElse: () => null))
					.where((e) => e != null)
					.toList() : [];
			record.compoundDefects = compoundDefects;
			if (_completer.isCompleted) {
				completer.complete();
			} else {
				_completer.future.then((_) {
					completer.complete();
				});
			}
		}
		_init();
	}
	
	String _getUrlByIdent(String ident){
		//todo:
	}
	
	Future<Image> _loadResponseImageByIdent(String ident, String savePath, [bool autoSave = true]){
		final completer = Completer<Image>();
		final _downloadData = <int>[];
		final fileSave = File(savePath);
		final url = _getUrlByIdent(ident);
		HttpClient client = HttpClient();
		client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
			// Optionally set up headers...
			// Optionally write to the request object...
			// Then call close.
			return request.close();
		}).then((HttpClientResponse response) {
			// Process the response.
			response.listen(_downloadData.addAll, onDone: () {
				if (autoSave)
					fileSave.writeAsBytes(_downloadData);
				completer.complete(ImageModel.decodeRawImg(_downloadData));
			});
		});
		return completer.future;
	}
	
	Future _responseImageInit() async {
		final completer = Completer();
		final imodels    = [record.imageModel] + record.bundledTakeshots.map((m) => m.imageModel).toList();
		final idents 		 = [record.imageModel.ident] + record.bundledTakeshots.map((m) => m.imageModel.ident).toList();
		final localpaths = <String>[record.identEntity.path] + record.bundledTakeshots.map((m) => m.identEntity.path).toList();
		int counter = 0;
		List.generate(idents.length, (i) {
			if (File(localpaths[i]).existsSync()){
				imodels[i].loadImage().then((_){
					imodels[i].resized_image = _;
					counter ++;
					if (counter >= idents.length){
						completer.complete();
					}
				});
			}else{
				final ident = idents[i] as String;
				final savePath =  _Path.join('assets/resized', ident);
				_loadResponseImageByIdent(ident, savePath).then((image){
					imodels[i].resized_image = image;
					counter ++;
					if (counter >= idents.length){
						completer.complete();
					}
				});
			}
		});
		return completer.future;
	}
	
	void _fromResponseMap(Map<String, dynamic> data, Completer completer){
		try {
			final _completer = Completer();
			title     = data['title'] as String;
			summary   = data['summary'] as String;
			conclusion= data['conclusion'] as String;
			device_id = data['device_id'] as int;
			bookmark ??= 0;
			if (data['id'] != null){
				final _id = data['id'] as int;
				if (_id >= baseRboundId)
					var pass;
				else
					imagejournal_id = _id;
			}
			// ----------------------------------
			final takeshots  = List<Map<String,dynamic>>.from(data['takeshot'] as List);
			final compounds  = List<Map<String,dynamic>>.from(data['selected_options'] as List);
			compoundDefects = compounds.isNotEmpty
					? compounds.map((m) => IJOptionModel.from(m)).toList()
					: [];
			List.generate(takeshots.length, (i){
				final tdata = takeshots[i];
				tdata['imageModel'] = tdata;
				if (i == 0){
					tdata['takeshotRecords'] = takeshots.sublist(1);
				}
				//fixme:
				final model = tdata['imageModel'];
				final defects = List<int>.from(model['defects'] as List);
				model['defects'] = defects.map((id) => compounds.firstWhere((o) => o['id'] == id)).toList();
			});
			
			record = TakeshotRecord.fromMap(takeshots.first , order, _completer, io);
			record.bundledTakeshots ??= [];
			record.bundledTakeshots.forEach((b) => b.delegate.bundledTakeshots ??= []);
			final selectedIdx= List<Map<String,dynamic>>.from (data['selected_options'] as List).map((o) => o['id'] as int).toList();
			final options 	 = defectService().options;
			// ----------------------------
			if (options?.isEmpty ?? true) {
				defectService().readFromDisk().then((list) {
					_D.debug('set compounds from IJModel.fromMap, ${data['selected_options']}');
					compoundDefects = selectedIdx.isNotEmpty
							? selectedIdx.map((i) => list.firstWhere((opt) => opt.id == i, orElse: () => null)).where((e) => e != null).toList()
							: [];
					record.compoundDefects = compoundDefects;
					if (_completer.isCompleted) {
						_responseImageInit().then((_){
							completer.complete();
						});
					} else {
						_completer.future.then((_) {
							_responseImageInit().then((_){
								completer.complete();
							});
						});
					}
				}).catchError((e){
					throw(e);
				});
			} else {
				_D.debug('set compounds from IJModel.fromMap, ${data['selected_options']}');
				compoundDefects = selectedIdx.isNotEmpty ? selectedIdx.map((i) => options.firstWhere((opt) => opt.id == i, orElse: () => null))
						.where((e) => e != null)
						.toList() : [];
				record.compoundDefects = compoundDefects;
				if (_completer.isCompleted) {
					_responseImageInit().then((_){
						completer.complete();
					});
				} else {
					_completer.future.then((_) {
						_responseImageInit().then((_){
							completer.complete();
						});
					});
				}
			}
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel._fromResponseMap failed: $e\n$s');
			rethrow;
		}
		_init();
	}
	
	@override Map<String, dynamic> asMap() {
		try {
			submodels ??= [];
			recs = List.generate(submodels.length, (i) {
				return submodels[i].asMap();
			});
			final data = super.asMap();
			data['selected_options'] = compoundDefects?.map?.call((o) => o.id)?.toList() ?? selected_options ?? [];
			data['entity']   = entity?.path;
			data['takeshot'] = record.asExtraMap();
			data["user_id"] = UserState?.currentUser?.id;
			return data;
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel.asMap failed: $e\n$s');
			rethrow;
		}
	}
	
	void processExtraMap(String field_name, String keyname, dynamic val, int counter, MultipartForm result, bool root, bool encodeToJpg) {
		try {
			if (keyname == 'imageModel') {
				final imodelData = val as Map<String, dynamic>;
				final ident = imodelData['ident'] as String;
				final records = [record] + record.bundledTakeshots.map((t) => t.delegate).toList();
				final resized_image = records
						.firstWhere((r) => r.identEntity.path.contains(ident), orElse: () {
					print('entities: ${records.map((r) => r.identEntity.path).toList()}');
					print('ident: $ident');
					throw Exception('no element');
				})
						.imageModel
						.resized_image;
				
				if (resized_image == null) {
					print('entities		: ${records.map((r) => r.identEntity.path).toList()}');
					print('resizedImgs: ${records.map((r) => r.imageModel.resized_image)}');
					print('ident			: $ident');
					assert(resized_image != null);
				}
				
				streamFiles.add(genUploadFile(resized_image, 'rec${counter}_$field_name.$keyname.resized_image', encodeToJpg));
				imodelData.forEach((ik, iv) {
					final value = (iv ?? "") == "" ? "" : jsonEncode(iv);
					result.fields['rec${counter}_$field_name.$keyname.$ik'] = value;
				});
			} else if (keyname == 'takeshotRecords') {
				if (root) (List<Map<String, dynamic>>.from(val as List)).forEach((rec) {
					counter ++;
					rec.forEach((k, v) {
						processExtraMap(field_name, k, v, counter, result, false, encodeToJpg);
					});
				});
			} else {
				final value = (keyname ?? "") == "" ? "" : jsonEncode(val);
				final key = root && counter != 0 ? field_name : "rec${counter}_$field_name.$keyname";
				result.fields[key] = value;
			}
			;
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel.processExtraMap failed: $e\n$s');
			rethrow;
		}
	}
	
	
	@override asMultipartForm({bool ignoreAddingToStreamFile , bool encodeToJpg = false}) {
		try {
			String field_name;
			recs = List.generate(submodels.length, (i) {
				return submodels[i].asMap();
			});
			final result = super.asMultipartForm(ignoreAddingToStreamFile:true, encodeToJpg: encodeToJpg);
			final extraMap = record.asExtraMap();
			int counter = 0;
			result.fields["user_id"] = UserState?.currentUser?.id?.toString();
			result.fields['rec_num'] = (record.bundledTakeshots.length + 1).toString();
			extraMap.forEach((tk, tv) {
				processExtraMap('takeshot', tk, tv, counter, result, true, encodeToJpg);
			});
			
			return result;
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel.asMultipartForm failed: $e\n$s');
			rethrow;
		}
	}
	
	@override String get thumbPath;
	
	bool assertTheSame(NewImageJournalModel other) {
		try {
			if (order == 0)
				assert(imagejournal_id == other.imagejournal_id, "journal id missmatch $imagejournal_id(${other.imagejournal_id})");
			assert(device_id == other.device_id						 , "device id missmatch $device_id(${other.device_id})" );
			assert(bookmark == other.bookmark							 , "bookmark missmatch $bookmark(${other.bookmark})");
			assert(patrol.patrol.isTheSame(other.patrol.patrol), "patrol missmatch\n${patrol.patrol.showDiff(other.patrol.patrol)}");
			assert(
				FN.orderedTheSame(selected_options.toSet().toList(), other.selected_options.toSet().toList()),
				"\ntarget: ${other.selected_options}, expected: $selected_options");
			assert(submodels.toSet().length == other.submodels.toSet().length,
				"target:${other.submodels.length}, expected: ${submodels.length}");
			if (order == 0)
				assert(FN.orderedEqualBy<NewImageJournalModel>(submodels, other.submodels, (sa, sb) {
					return sa.assertTheSame(sb);
			}), "submodels missmatch");
			return true;
		} catch (e, s) {
			print('[ERROR] NewImageJournalModel.assertTheSame failed: $e\n$s');
			return false;
		}
	}
	
	void delEntity() {
		io(entity.path).deleteSync();
	}
	
	void dump() {
		UserState.manager.file(journalSavePath);
	}
	
	bool isAutoGeneratedId() {
		return imagejournal_id > NewImageJournalModel.baseRboundId;
	}
	
	@override TCateTitle categoryTitle;
	@override bool get isCategory => categoryTitle != null;
	
}


class IJFormDataParser {
	final StoreInf Function(String path) io;
	final String dpath;
	final String jpath;
	
	NewImageJournalModel model;
	List<Dio.UploadFileInfo> _files;
	Map<String, String> _fields;
	
	IJFormDataParser(this.io, this.dpath, this.jpath);
	
	dynamic parseField(String key, String value) {
		if (key == 'created' || key == 'modified') {
			return DateTime.parse(value);
		} else if (value.isEmpty) {
			return "";
		} else {
			try {
				return jsonDecode(value);
			} catch (e, s) {
				print('[ERROR] IJFormDataParser.parseField failed: $e\n$s\n'
						'value: $value');
				rethrow;
			}
		}
	}
	
	TwoDBytes toTwoDBytes() {
		final fields = _fields;
		final files = _files.where((f) => f != null);
		final raw_list = [utf8.encode(jsonEncode(fields))]
			..addAll(files.map((f) => f.bytes));
		return TwoDBytes(raw_list);
	}
	
	Uint8List toBytes() {
		final fields = _fields;
		final files = _files.where((f) => f != null);
		final raw_list = [utf8.encode(jsonEncode(fields))]
			..addAll(files.map((f) => f.bytes));
		return TwoDBytes(raw_list).bytes;
	}
	
	TakeshotRecord mapToTakeshotRecord() {}
	
	dynamic castType(String value) {
		if (value.isEmpty) return "";
		final ret = jsonDecode(value);
		if (ret is Map) return ret as Map<String, dynamic>;
		return ret;
	}
	
	Map<String, dynamic> fieldsToMap() {
		final decoded = _fields;
		final rec_num = int.parse(decoded['rec_num'] as String);
		final tkmaps = List<Map<String, dynamic>>.generate(rec_num, (i) => {});
		final nums = RegExp("rec[0-9]+_");
		final Map<String, dynamic> ijmap = {};
		
		int order;
		decoded.forEach((k, v) {
			try {
				order = k.startsWith(nums) ? int.parse(k
						.split('_')
						.first
						.substring(3)) : null;
				if (order == null) {
					ijmap[k] = v;
				} else {
					final keyset = k.split(nums).last.split('takeshot.').last;
					final mainkey = keyset.contains('.') ? keyset.split('.').first : keyset;
					final subkey = keyset.contains('.') ? keyset.split('.').last : null;
					tkmaps[order][mainkey] ??= <String, dynamic>{};
					if (subkey == null)
						tkmaps[order][mainkey] = castType(v);
					else
						tkmaps[order][mainkey][subkey] = castType(v);
				}
			} catch (e, s) {
				print('[ERROR] IJFormDataParser.fieldsToMap failed: $e\n$s');
				rethrow;
			}
		});
		tkmaps.forEach((rec) {
			rec['takeshotRecords'] ??= [];
		});
		ijmap['takeshot'] = tkmaps;
		return ijmap;
	}
	
	Future<TakeshotRecord> toTakeshot(List<IJOptionModel> optionsGetter(), {bool loadImage = false}) {
		final completer = Completer<TakeshotRecord>();
		final tkmaps = fieldsToMap();
		print('tkmaps: $tkmaps');
		// ------------------------------
		final takeshots = List<Map<String, dynamic>>.from(tkmaps['takeshot'] as List);
		final imagePaths = takeshots.map((t) => TEntity(entity: File(t['imageModel']['path'] as String)).path).toList();
		final imageSizes = takeshots.map((t) => List<int>.from(t['imageModel']['image_size'] as List)).toList();
		final images = <Image>[];
		takeshots.first['bundledImages'] = takeshots.map((t) => t['imageModel']['path']).toList();
		takeshots.first['takeshotRecords'] = takeshots.sublist(1);
		// ------------------------------
		if (optionsGetter == null) {
			final service = DefectsService.F(io, jpath);
			optionsGetter = () => service.options;
		}
		
		
		
		final record = TakeshotRecord.fromMap(takeshots.first, 0, completer, io);
		return completer.future.then((_) {
			if (loadImage)
				List.generate(_files?.length ?? 0, (i) {
					final info = _files[i];
					final filepath = imagePaths[i];
					Image image;
					if (File(filepath).existsSync()) {
						image = ImageModel.decodeImg(info.bytes, null, imageSizes[i]);
					} else {
						File(filepath).writeAsBytesSync(info.bytes);
						image = ImageModel.decodeImg(info.bytes, null, imageSizes[i]);
					}
					if (i == 0)
						record.imageModel.resized_image = image;
					else
						record.bundledTakeshots[i - 1].imageModel.resized_image = image;
				});
			return record;
		});
	}
	
	Future<TakeshotRecord> toTakeshotForServer(List<IJOptionModel> optionsGetter(), {bool loadImage = false}) {
		final completer = Completer<TakeshotRecord>();
		final tkmaps = fieldsToMap();
		//print('tkmaps: $tkmaps');
		// ------------------------------
		final takeshots = List<Map<String, dynamic>>.from(tkmaps['takeshot'] as List);
		final imagePaths = takeshots.map((t) => TEntity(entity: File(t['imageModel']['path'] as String)).path).toList();
		final imageSizes = takeshots.map((t) => List<int>.from(t['imageModel']['image_size'] as List)).toList();
		final images = <Image>[];
		takeshots.first['bundledImages'] = takeshots.map((t) => t['imageModel']['path']).toList();
		takeshots.first['takeshotRecords'] = takeshots.sublist(1);
		// ------------------------------
		if (optionsGetter == null) {
			final service = DefectsService.F(io, jpath);
			optionsGetter = () => service.options;
		}
		
		print('files: ${_files.map((f) => "${f.fileName}(${f.bytes?.length})")}');
		List.generate(_files?.length ?? 0, (i) {
			final info = _files[i];
			final filepath = imagePaths[i];
			if (File(filepath).existsSync()) {
				var pass;
			} else {
				print('write image: $filepath to disk, ${info.fileName}(${info.bytes?.length})');
//				ImageModel.decodeRawImg(info.bytes);
//				ImageModel.encodeToJPG;
//				Image.fromBytes(w, h, info.bytes)
				File(filepath).writeAsBytesSync(info.bytes);
			}
		});
		
		final record = TakeshotRecord.fromMap(takeshots.first, 0, completer, io);
		return completer.future.then((_) {
			if (loadImage)
				List.generate(_files?.length ?? 0, (i) {
					final info = _files[i];
					final filepath = imagePaths[i];
					Image image;
					if (File(filepath).existsSync()) {
						image = ImageModel.decodeImg(info.bytes, null, imageSizes[i]);
					} else {
						throw Exception('uncaught exception');
					}
					if (i == 0)
						record.imageModel.resized_image = image;
					else
						record.bundledTakeshots[i - 1].imageModel.resized_image = image;
				});
			return record;
		});
	}
	
	
	IJFormDataParser.fromUploadString(String encodedString, this._files, Completer completer, List<IJOptionModel> optionsGetter(),
			this.io, this.jpath, this.dpath, {bool loadImage = false
	}){
		_fields = Map<String, String>.from(jsonDecode(encodedString) as Map);
		toTakeshot(optionsGetter, loadImage: loadImage).then((record) {
			final jid = int.parse(_fields['id']);
			final entity = _fields['entity'] != null ? TEntity(entity: File(_fields['entity'])) : null;
			final defectIdx = List<int>.from(jsonDecode(_fields['selected_options']) as List);
			final compoundDefects = optionsGetter().where((opt) => defectIdx.contains(opt.id)).toList();
			final userid = int.parse(_fields["user_id"]);
			model = NewImageJournalModel(
					io, jpath, dpath, userid,
					record: record,
					compoundDefects: compoundDefects,
					imagejournal_id: jid,
					order: 0,
					entity: entity);
			completer.complete();
		});
	}
	
	IJFormDataParser.fromMap(this._fields, this._files, Completer completer, List<IJOptionModel> optionsGetter(),
			this.io, this.jpath, this.dpath, {bool loadImage = false
	}){
		toTakeshot(optionsGetter, loadImage: loadImage).then((record) {
			final jid = int.parse(_fields['id']);
			final entity = _fields['entity'] != null ? TEntity(entity: File(_fields['entity'])) : null;
			final defectIdx = List<int>.from(jsonDecode(_fields['selected_options']) as List);
			final compoundDefects = optionsGetter().where((opt) => defectIdx.contains(opt.id)).toList();
			final userid = int.parse(_fields["user_id"]);
			model = NewImageJournalModel(
					io, jpath, dpath, userid,
					record: record,
					compoundDefects: compoundDefects,
					imagejournal_id: jid,
					order: 0,
					entity: entity);
			completer.complete();
		});
	}
	
	
	IJFormDataParser.fromMapForServer(this._fields, this._files, Completer completer, List<IJOptionModel> optionsGetter(),
			this.io, this.jpath, this.dpath, {bool loadImage = false
			}){
//		transformFieldsForServer();
		toTakeshotForServer(optionsGetter, loadImage: loadImage).then((record) {
			final jid = int.parse(_fields['id']);
			final entity = _fields['entity'] != null ? TEntity(entity: File(_fields['entity'])) : null;
			final defectIdx = List<int>.from(jsonDecode(_fields['selected_options']) as List);
			final compoundDefects = optionsGetter().where((opt) => defectIdx.contains(opt.id)).toList();
			final userid = int.parse(_fields["user_id"]);
			model = NewImageJournalModel(
					io, jpath, dpath, userid,
					record: record,
					compoundDefects: compoundDefects,
					imagejournal_id: jid,
					order: 0,
					entity: entity);
			completer.complete();
		});
	}
	
	void transformFieldsForServer(){
		//fixme:
		print('after transform fields');
		_fields.forEach((k, v){
			if (k.endsWith('imageModel.path') && v.isNotEmpty) {
				final origpath = v.substring(1, v.length -1);
				final basename = _Path.basename(origpath);
				final serverpath = "${ImageModel.RESIZED_PATH}/$basename";
				_fields[k] = '"$serverpath"';
				print('$k: ${_fields[k]} (${k.endsWith('imageModel.path') || k.endsWith('.bundledImages')})');
			} else if (k.endsWith('.bundledImages') && v.length > 4){
				final paths = v.substring(1, v.length -1).split(',').where((m) => m.length > 3).map((m) => m.substring(1, m.length -1)).toList();
				final serverpaths = paths.map((p) => "${ImageModel.RESIZED_PATH}/${_Path.basename(p)}");
				_fields[k] = "[${serverpaths.map((m) => '"$m"').join(',')}]";
				print('$k: ${_fields[k]} (${k.endsWith('imageModel.path') || k.endsWith('.bundledImages')})');
			}
		});
	}
}


