import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:nxp_bloc/consts/server.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_state.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/models/newIJModel.dart';
import 'package:nxp_bloc/mediators/models/takeshotModel.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:path/path.dart' as _Path;
import 'package:dio/dio.dart' as Dio;
import 'package:IO/src/io.dart';


// Include generated file
final _D = AppState.getLogger("DefectServ");
/*
*
* 				R E A C T     S T A T E M A N A G E R ..
*
*
*/

enum EOPtActions {
	add, edit, del,
}

abstract class DefectsServiceSketch {
	StoreInf Function(String path) io;
	String defaultSavePath; // _Path.join(_store.configDir, localpath);
	
	String filePath;
	List<IJOptionModel> options = [];
	
	void Function() onDuplicate;
	void Function() onSaving;
	void Function() onSaved;
	void Function() onSaveFailed;
	bool Function() networkTester;
	
	Future<List<IJOptionModel>> readFromCloud(String mssageId, {bool cache = true, void onDumpToDisk(String data)});
	
	void pSort();
	
	void pMerge();
	
	Future<List<IJOptionModel>> readFromDisk();
	
	List<IJOptionModel> fromMap(List<Map<String, dynamic>> data);
	
	int getId(IJOptionModel option);
	
	void dump();
	
	Future uploadAll();
	
	void add(IJOptionModel option);
	
	void edit(IJOptionModel option);
	
	void del(IJOptionModel option);
	
	bool isTheSameOptions(List<IJOptionModel> models);
	
	List<IJOptionModel> unionDefectsFromTakeshot(TakeshotRecord trecord);
}


class PseudoDefectService extends DefectsService {
	PseudoDefectService._() : super._(
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null);
	
	factory PseudoDefectService.F(List<IJOptionModel> options){
		return PseudoDefectService._()
			..options = options;
	}
}

class DefectsService implements DefectsServiceSketch {
	static String get localpath => DescOptState.manager.store.localpath;
	static String get unsavedpath => DescOptState.manager.store.unsavedpath;
	static final get_request_path = '/${ename(ROUTE.descoption)}/all/';
	static final post_request_path = '/${ename(ROUTE.descoption)}/batch/';
	static final merge_request_path = '/${ename(ROUTE.descoption)}/merge/';
	static final del_request_path = '/${ename(ROUTE.descoption)}/delid/';
	static final create_request_path = '/${ename(ROUTE.descoption)}/add/';
	static final edit_request_path = '/${ename(ROUTE.descoption)}/edit/';
	
	static DefectsService instance;
	
	StoreInf Function(String path) io;
	String defaultSavePath; // _Path.join(_store.configDir, localpath);
	
	String filePath;
	
	//DescOptionHistory history;
	List<IJOptionModel> options = [];
	
	void Function() onDuplicate;
	void Function() onSaving;
	void Function() onSaved;
	void Function() onSaveFailed;
	bool Function() networkTester;
	
	DefectsService._(this.io, this.defaultSavePath, this.onDuplicate, this.onSaving, this.onSaved, this.onSaveFailed, this.filePath,
			this.networkTester);

//	DescOptionService();
	
	factory DefectsService.F(StoreInf io(String path), String defaultSavePath,
			{ void Function() onDuplicate, void Function() onSaving, void Function() onSaved, void Function() onSaveFailed, String filePath, bool Function() networkTester }){
		if (instance == null) {
			filePath ??= defaultSavePath;
			return instance = DefectsService._(
					io,
					defaultSavePath,
					onDuplicate,
					onSaving,
					onSaved,
					onSaveFailed,
					filePath,
					networkTester);
		}
		return instance;
	}
	
	@override Future<List<IJOptionModel>>
	readFromCloud(String mssageId, {bool cache = true, void onDumpToDisk(String data)}) async {
		const pth = '/descoption';
		_D.debug('readFromCloud0');
		final res = await Http().dioGet(pth, qparam: {'pagenum': -1, 'perpage': -1}, isCached: cache)
			.catchError((_){
			});
		
		if (res?.statusCode == 200) {
			final body = List<Map<String, dynamic>>.from(res.data as List);
			if (onDumpToDisk == null)
				await UserState.manager.file(DescOptState.manager.store.localpath).writeAsync(jsonEncode(body));
			else
				onDumpToDisk.call(jsonEncode(body));
			// ------------------------
			options = body.map((data) => IJOptionModel.from(data)).toList();
			pMerge();
			return options;
		} else {
			_D.error("get defects from cloud failed, statusCode: ${res?.statusCode}");
			AppState.msg.onInferNetworkError(res?.statusCode ?? 503, mssageId, "get defects options failed");
			return readFromDisk();
		}
	}
	
	@override void pSort() {
		options.sort((a, b) => a.name.codeUnits.reduce((a, b) => a + b) - b.name.codeUnits.reduce((a, b) => a + b));
	}
	
	@override void pMerge() {
		final result = <IJOptionModel>[];
		for (final option in options) {
			if (option.name == null && option.description == null)
				continue;
			if (result.isEmpty)
				result.add(option);
			else {
				final parallel = result.firstWhere((o) => o.sameTag(option), orElse: () => null);
				if (parallel == null)
					result.add(option);
				else if (parallel.modified.isBefore(option.modified)) {
					if (option.theSame(parallel))
						result[result.indexOf(parallel)] = option;
					else {
						if (option.imagejournals?.isEmpty ?? true)
							option.imagejournals = parallel.imagejournals;
						else if (parallel.imagejournals?.isEmpty ?? true) var pass;
						result[result.indexOf(parallel)] = option;
					}
				} else if (parallel.modified.isAfter(option.modified)) var pass;
			}
		}
		options = result;
		pSort();
	}
	
	@override Future<List<IJOptionModel>> readFromDisk() async {
		if (io(filePath).existsSync()) {
			final rawString = await io(filePath).readAsync();
			final json = jsonDecode(rawString);
			print('readFromDisk path: $filePath');
			print('readFromDisk rawString: $rawString');
			print('readFromDisk json: $json');
			final body = List<Map<String, dynamic>>.from(json as List);
			options = body.isEmpty
				? [] : body.map((data) => IJOptionModel.from(data)).toList();
			pMerge();
			return options;
		} else {
			return [];
		}
	}
	
	@override List<IJOptionModel> fromMap(List<Map<String, dynamic>> data) {
		return options = data.map((d) => IJOptionModel.from(d)).toList();
	}
	
	@override int getId(IJOptionModel option) {
		try {
			if (option.id == null) {
				if (options.isEmpty) {
					return 100000;
				} else {
					return max(options.map((o) => o.id).reduce(max) + 1, 100000);
				}
			}
			return option.id;;
		} catch (e, s) {
			print('[ERROR] DefectsService.getId failed: $e'
					'\noption: ${option.asMap()}'
					'\n$s');
			rethrow;
		}
	}
	
	void dump() {
		onSaving?.call();
		try {
			final content = jsonEncode(options.map((option) => option.asMap()).toList());
			io(filePath).writeSync(content, encrypt: true);
			onSaved?.call();
		} catch (e, s) {
			print('[ERROR] DescOptionService.dump failed: \n$s');
			onSaveFailed?.call();
			rethrow;
		}
	}
	
	@override Future<Response> uploadAll() async {
		final body = options.map((o) => o.asMap()).toList();
		_D.debug('uploadAll0...$body');
		final response = await Http().dioPost(post_request_path, body: body).catchError((_){
			_D.error('uploadAll failed...');
		});
		if (response?.statusCode == 200)
			_D.debug('uploadAll success...');
		return response;
	}
	
	Future<Response> addOnCloud(List<IJOptionModel> options) async {
		return await Http().dioPost(create_request_path, body: options.map((e) => e.asMap()).toList());
	}
	
	@override void add(IJOptionModel option) {
		option.id = getId(option);
		try {
			if (options.any((o) => o.name == option.name && o.description == option.description))
				onDuplicate?.call();
			else {
				options.add(option);
			};
		} catch (e, s) {
			print('[ERROR] DescOptionService.add failed: \n$s');
			rethrow;
		}
	}
	
	Future<Response> editOnCloud(IJOptionModel option) async {
		return await Http().dioPost(edit_request_path, body: option.asMap());
	}
	
	@override void edit(IJOptionModel option) {
		assert(option.id != null);
		final record = options.firstWhere((opt) => opt.id == option.id, orElse: () => throw Exception('id not found'));
		try {
			options[options.indexOf(record)] = option;
		} catch (e, s) {
			print('[ERROR] DescOptionService.edit failed: \n$s');
			rethrow;
		}
	}
	
	Future<Dio.Response> mergeWholeSetOnCloud(List<int> mergeList, List<IJOptionModel> selecteds) async {
		final result = await Http().dioPost(merge_request_path, qparam: {'mergeList': mergeList});
		final tobeRemoved = FN.head(mergeList);
		if (result.statusCode == 200){
			selecteds.removeWhere((opt) => tobeRemoved.contains(opt.id));
			return result;
		}
		return result;
	}
	
	Future<Dio.Response> mergeOnCloud(int sourceId, int targetId, List<IJOptionModel> selecteds) async {
		return await Http().dioPost(merge_request_path, qparam: {"sourceid": sourceId, "targetid": targetId});
	}
	
	Future<Dio.Response> delOnCloud(IJOptionModel option, void onForbid()) async {
		final result = await Http().dioDelete(
			'${del_request_path}${option.id}',
			body: {'id': option.id},
			headers: {'request_type': 'del'});
		if (result.statusCode == 403){
			onForbid();
			return null;
		}
		return result;
	}
	
	@override void del(IJOptionModel option) {
		assert(option.id != null);
		final record = options.firstWhere((opt) => opt.id == option.id,
				orElse: () => throw Exception('id(${option.id}) not found within options: ${options.map((o) => o.id)}'));
		try {
			options.removeAt(options.indexOf(record));
			dump();
		} catch (e, s) {
			print('[ERROR] DescOptionService.del failed: \n$s');
			rethrow;
		}
	}
	
	void merge(IJOptionModel source, IJOptionModel target, bool dumpFile){
		final sRecord = options.firstWhere((opt) => opt.id == source.id, orElse: () => throw Exception('id(${source.id}) not found within options: ${options.map((o) => o.id)}'));
		final tRecord = options.firstWhere((opt) => opt.id == target.id, orElse: () => throw Exception('id(${target.id}) not found within options: ${options.map((o) => o.id)}'));
		try {
			options.removeAt(options.indexOf(sRecord));
			options.removeAt(options.indexOf(tRecord));
			if (dumpFile)
				dump();
		} catch (e, s) {
			print('[ERROR] DescOptionService.del failed: \n$s');
			rethrow;
		}
	}
	
	bool isTheSameOptions(List<IJOptionModel> models) {
		return options.length == models.length && options.every((o) => models.any((m) => m.sameTag(o)));
	}
	
	List<IJOptionModel> unionDefectsFromTakeshot(TakeshotRecord trecord) {
		final records = [trecord.defects] + trecord.bundledTakeshots.map((m) => m.delegate.defects).toList();
		return records.reduce((d1, d2) {
			return FN.union_1dlist(d1, d2).toList();
		});
	}
}


abstract class JournalServiceSketch {
	void Function() onDuplicate;
	void Function() onSaving;
	void Function() onSaved;
	void Function() onSaveFailed;
	bool Function() networkTester;
	
	// -------------------------------
	int journalid;
	int deviceid;
	String journalPath; // _store.journalDir;
	StoreInf Function(String path) io;
	
	// -------------------------------
	String getFilePath(NewImageJournalModel model);
	
	String genJournalFilename(NewImageJournalModel model);
	
	Future<StoreInf> dumpByTakeshot(TakeshotRecord record);
	
	Future<StoreInf> dumpByIJModel(NewImageJournalModel model);
}


class JournalService implements JournalServiceSketch {
	static JournalService instance;
	
	// -------------------------------
	void Function() onDuplicate;
	void Function() onSaving;
	void Function() onSaved;
	void Function() onSaveFailed;
	bool Function() networkTester;
	
	// -------------------------------
	int journalid;
	int deviceid;
	
	String journalPath; // _store.journalDir;
	StoreInf Function(String path) io;
	
	JournalService._(this.journalPath, this.io, this.onDuplicate, this.onSaving, this.onSaved, this.onSaveFailed, this.networkTester);
	
	factory JournalService.F(StoreInf io(String path), String journalPath,
			{ void Function() onDuplicate, void Function() onSaving, void Function() onSaved, void Function() onSaveFailed, bool Function() networkTester }){
		if (instance == null) {
			return instance = JournalService._(
					journalPath,
					io,
					onDuplicate,
					onSaving,
					onSaved,
					onSaveFailed,
					networkTester);
		}
		return instance;
	}
	
	String getFilePath(NewImageJournalModel model) => TEntity(entity: File(_Path.join(journalPath, genJournalFilename(model)))).path;
	
	String genJournalFilename(NewImageJournalModel model) {
		final device_id = model.device_id;
		final imagejournal_id = model.isAutoGeneratedId() ? 'null' : model.imagejournal_id.toString();
		
		final date = model.record.patrolDate;
		// save by ids mapping from description_id and device_id
		final t = DateTime.now();
		final month = ('0' + t.month.toString()).substring(t.month
				.toString()
				.length - 1);
		final day = ('0' + t.day.toString()).substring(t.day
				.toString()
				.length - 1);
		final hour = ('0' + t.hour.toString()).substring(t.hour
				.toString()
				.length - 1);
		final time = '${t.year}-${month}-${day}-${hour}';
		return 'D${device_id ?? ""}-$date-J${imagejournal_id ?? ""}-$time-V1.json';
	}
	
	Future<StoreInf> dumpByTakeshot(TakeshotRecord record) {
		final userid = UserState.currentUser.id;
		final model = NewImageJournalModel(
				io, journalPath, null, userid, record: record, imagejournal_id: null, order: 0, compoundDefects: record.compoundDefects);
		return dumpByIJModel(model);
	}
	
	Future<StoreInf> dumpByIJModel(NewImageJournalModel model) {
		try {
			final filePath = getFilePath(model);
			final content = jsonEncode(model.asMap());
			_D.debug('dump ijmodel: $content');
			return io(TEntity(entity: File(filePath)).path).writeAsync(content, encrypt: true);;
		} catch (e, s) {
			print('[ERROR] JournalService.dumpByIJModel failed: $e\n$s');
			rethrow;
		}
	}
	
	
	
	Future<Dio.Response> uploadJournal(NewImageJournalModel model) async {
		final pth = ROUTE.imagejournal.toString().split('.').last;
		final form          = model.asMultipartForm();
		final completer     = Completer();
		final optionsGetter = () => DefectsService.F(io, "fake").options;
		final jpath         = getFilePath(model);
		final dpath         = DescOptState.manager.store.localpath;
		// ---------------------------
		final formParser 	= IJFormDataParser.fromMap(form.fields,form.files, completer,optionsGetter, io, jpath, dpath);
		await completer.future;
		
		final two_d 			= formParser.toTwoDBytes();
		final headers 		= <String, String>{};
		// ---------------------------
		return Http().dioMultiPost(pth, headers: headers, binary_data: two_d, onSend: (send, total) {
		}, onReceive: (send, total) {
		}).then((res) async {
			return res;
		});
	}
	
}

