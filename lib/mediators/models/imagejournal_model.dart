
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image/image.dart';
import 'package:nxp_bloc/consts/http.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/models/validator_model.dart';

abstract class ImageJournalInf implements SerializableModel {
	DateTime created;
	DateTime modified;
	String title;
	String summary;
	String conclusion;
	int imagejournal_id;
	int device_id;
	
	Map<String, UploadFileInfo> files;
	List<Map<String, dynamic>> recs;
	List<int> selected_options;
	
	Map<String, dynamic> asMap();
}

class ImageJournalModel implements ImageJournalInf {
	@override int device_id;
	@override int imagejournal_id;
	@override DateTime created;
	@override DateTime modified;
	@override String conclusion;
	@override String summary;
	@override String title;
	
	@override Map<String, UploadFileInfo> files;
	@override List<Map<String, dynamic>> recs;  // fixme: data structure of recs already changed
	@override List<int> selected_options;
	
	int machine_id;
	int bookmark;
	PatrolRecordModel patrol;
	List<BaseIJState> states;
	final int user_id;
	
	//machine_id untested;
	ImageJournalModel(
			{ this.user_id, this.title, this.conclusion, this.summary, this.recs, this.created, this.machine_id, this.imagejournal_id, this.device_id, this.selected_options, this.patrol});
	
	String get thumbPath {
		final first = states.firstWhere((state) => state.model.path != null, orElse: () => null);
		return first?.model?.path;
	}
	
	ImageJournalModel.fromMap(Map<String, dynamic> data): user_id = data["user_id"] as int{
		fromMap(data);
	}
	
	void fromMap(Map<String, dynamic> data){
		try {
			imagejournal_id = data['id'] as int;
			title = data['title'] as String;
			summary = data['summary'] as String;
			conclusion = data['conclusion'] as String;
			device_id = data['device_id'] as int;
			machine_id = data['machine_id'] as int;
			selected_options = List<int>.from(
					(data['selected_options'] as List).map((i) {
						return i is int
								? i
								: i['id'] as int;
					}).toList());
			created = DateTime.parse(data['created'] as String);
			modified = DateTime.parse(data['modified'] as String);
			patrol = PatrolRecordModel.fromMap(data['patrol'] as Map<String, dynamic>);
			recs = List<Map<String, dynamic>>.from(data['recs'] as List);
			if (data.containsKey('bookmark'))
				bookmark = data['bookmark'] as int;
		} catch (e, s) {
			print('[ERROR] ImageJournalModel.fromMap failed: $e\n$s');
			rethrow;
		}
	}
	
	void statesInit({ then(Map<String, dynamic> rec, Image image), error(Map<String, dynamic> rec, e)}) {
		final records = <BaseIJState>[];
		for (var i = 0; i < recs.length; ++i) {
			final rec = recs[i];
			final rec_id = rec['rec_id'] as int;
			final desc = rec['description'] as String;
			final model = ImageModel.fromMap(rec, (i) => then(rec, i), (e) => error(rec, e));
			final state = IJStateAdd(rec_id, desc, model: model);
			records.add(state);
		}
		addRecords(records);
	}
	
	@override
	Map<String, dynamic> asMap() {
		try {
			final ret = {
				'id': imagejournal_id,
				'title': title ?? "",
				'summary': summary ?? "",
				'conclusion': conclusion ?? "",
				'device_id': device_id ?? 1,
				'machine_id': machine_id,
				'selected_options': selected_options ?? [],
				'created': created?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
				'modified': modified?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
				'patrol': PatrolRecordModel.fromMap(patrol.asMap()).asMap(),
				'bookmark': bookmark,
				'recs': recs?.map((Map<String, dynamic> rec) {
					final ret = <String, dynamic>{};
					rec.forEach((k, v) {
						ret[k] = v ?? "";
					});
					ret.remove('resized_image');
					ret.remove('thumb_image');
					return ret;
				})?.toList?.call()
			};
			filterNullInMap(ret);
			return ret;;
		} catch (e, s) {
			print('[ERROR] ImageJournalModel.asMap failed: $e\n$s');
			rethrow;
		}
	}
	
	UploadFileInfo genUploadFile(Image img, String field_name, bool encodeToJpg){
		if (!encodeToJpg)
			return UploadFileInfo.fromBytes(img.getBytes(), field_name);
		
		final bytes = ImageModel.encodeToJPG(img);
		return UploadFileInfo.fromBytes(bytes, field_name);
	}
	
	List<UploadFileInfo> streamFiles = [];
	
	String parseField(String key, dynamic value){
		if (key == 'created' || key == 'modified'){
			return value as String;
		}else if (value is String && value.isEmpty){
			return "";
		}else{
			if (value is String){
				return value;
			}else{
				try {
					return jsonEncode(value);
				} catch (e, s) {
					print('[ERROR] IJFormDataParser.parseField failed: $e\n$s\n'
							'value: $value');
					rethrow;
				}
			}
			
		}
	}
	
	/*
	List<UploadFileInfo> uploadFilesInit(Map<String, String> fields, bool isFile(String f)){
		//fixme:
		streamFiles  = <UploadFileInfo>[];
		for (var i = 0; i < recs.length; ++i) {
			var rec = recs[i];
			rec.forEach((String k, v) {
				final field_name = 'rec${i}_$k';
				if (isFile(k)) {
					final image_file = v != null ? genUploadFile((v as Image), field_name) : null;
					streamFiles.add(image_file);
				} else {
					fields[field_name] = parseField(k, v);
					//fields[field_name] = (v ?? "").toString();
				}
			});
		}
		return streamFiles;
	}*/
	
	MultipartForm asMultipartForm({bool ignoreAddingToStreamFile , bool encodeToJpg }) {
		ignoreAddingToStreamFile ??= false;
		encodeToJpg ??= false;
		try {
			final fields = <String, String>{
				'id': imagejournal_id?.toString(),
				'title': title ?? "",
				//'bookmark'  : bookmark?.toString() ?? "",
				'summary': summary ?? "",
				'conclusion': conclusion ?? "",
				'selected_options': jsonEncode(selected_options ?? []),
				'device_id': device_id?.toString() ?? "1",
				'machine_id': machine_id?.toString(),
				'user_id': user_id?.toString(),
				'created': created?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
				'modified': modified?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
				'rec_num': recs.length.toString(),
				'patrol_id': patrol.id.toString(),
				// patrol_id untested
			};
			
			filterNullInMap(fields);
			//uploadFilesInit(fields, (f) => f == 'resized_image');
			streamFiles  = <UploadFileInfo>[];
			if (!ignoreAddingToStreamFile){
				for (var i = 0; i < recs.length; ++i) {
					var rec = recs[i];
					rec.forEach((String k, v) {
						final field_name = 'rec${i}_$k';
						if (k == 'resized_image') {
							final image_file = v != null
									? genUploadFile((v as Image), field_name, encodeToJpg)
									: null;
							streamFiles.add(image_file);
						} else {
							fields[field_name] = parseField(k, v);
						}
					});}
			}
			
			/*if (encodeToJpg){
				final List<List<int>>image_sizes = fields.keys.where((k) => k.endsWith('image_size'))
						.map((k) => List<int>.from(jsonDecode(fields[k]) as List)).toList();
				List.generate(streamFiles.length, (i){
					final file = streamFiles[i];
					final imageSize = image_sizes[i];
					final image = Image.fromBytes(imageSize[0], imageSize[1], file.bytes);
					final bytes = ImageModel.encodeToJPG(image);
					
				});
			}*/
			
			final result = MultipartForm.from(fields: fields, files: streamFiles);
			return result;
		} catch (e, s) {
			print('[ERROR] ImageJournalModel.asMultipartForm failed: $e\n$s');
			rethrow;
		}
	}
	
	Future updateRecs() async {
		for (var i = 0; i < states.length; ++i) {
			var state = states[i];
			if (state.model.resized_image == null) await state.model.imageInit();
			
			final model = state.model;
			final ret = model.asMap();
			final rec_id = states
					.firstWhere((v) => v.model == model)
					.rec_id;
			ret["rec_id"] = rec_id;
			if (rec_id == null) throw Exception('rec_id should not be null');
			recs[i] = ret;
		}
	}
	
	Future<List<Map<String, dynamic>>> addRecords(List<BaseIJState> records, {bool forUpload = false}) async {
		states = records;
		recs ??= [];
		for (var i = 0; i < records.length; ++i) {
			var state = records[i];
			if (state.model.isEmpty) continue;
			
			await state.model.imageInit();
			final model = state.model;
			final ret = model.asMap();
			final rec_id = records
					.firstWhere((v) => v.model == model)
					.rec_id;
			ret["rec_id"] = rec_id;
			if (rec_id == null) throw Exception('rec_id should not be null');
			recs.add(ret);
		}
		return recs;
	}
	
	readFromJson(Map<String, dynamic> rawdata) {}
	
}

