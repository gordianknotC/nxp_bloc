import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:bloc/bloc.dart';
import 'package:image/image.dart';
import 'package:meta/meta.dart';
import 'package:nxp_bloc/impl/services.dart';
import 'package:nxp_bloc/mediators/controllers/app_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijdevice_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/ijoptions_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_bloc.dart';
import 'package:nxp_bloc/mediators/controllers/patrol_state.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import 'package:nxp_bloc/mediators/di.dart' show Http;
import 'package:nxp_bloc/consts/server.dart';
import 'package:common/common.dart' show ELevel, FN, TwoDBytes, guard;
import 'package:nxp_bloc/mediators/models/imagejournal_model.dart';
import 'package:nxp_bloc/mediators/sketch/configs.dart';
import 'package:nxp_bloc/mediators/sketch/store.dart';
import 'package:path/path.dart' as Path;
import 'package:nxp_bloc/consts/messages.dart';
import 'package:nxp_bloc/mediators/controllers/imagejournal_states.dart';

const _OK = "ok";
final debug = AppState.getLogger("IJ");

abstract class DialogUpdateBehavior<T> {
	List<int> initialSelected;
	Map<String, List<T>> _qcache;
	List<int> selected;
	
	List<T> get models;
	
	List<T> get selectedModels {
		return selected.map((s) => models[s]).toList();
	}
	
	void onSubmit(int v);
	
	Future<List<T>> modelsGetter({int page = 1, int uid = 1});
}


/*
*
*
*           B l o C    -    S T A T E    M E D I A T O R
*
*
* */
class IJState {
	static ConfigInf config;

//   static IJPatrolSelection patrolSelection = IJPatrolSelection();
	/// --------------------------------------------------------------
	///  general editor's states
	///  [processing] indicating states of current processing thread
	///         - onIdle, onLoad, onSave, onUpload
	///
//   static BgProc get processing              => AppState.processing;
//   static void   set processing(BgProc v)    => AppState.processing = v;
	static String get state_message => AppState.state_message;
	
	static void set state_message(String v) => AppState.state_message = v;
	
	static int get progress => AppState.progress;
	
	static String file_path;
	static String title;
	static String summary;
	static String conclusion;
	static bool changed;
	
	static List<DeviceModel> _device_data;
	
	static Future<List<DeviceModel>> get device_data {
		final completer = Completer<List<DeviceModel>>();
		DevState.manager.fetchInitialData().then((res) {
			_device_data = List<Map<String, dynamic>>.from(res as List).map((data) => DeviceModel.from(data)).toList();
			completer.complete(_device_data);
		});
		return completer.future;
	}
	
	static PatrolRecordModel selectedPatrol;
	static int _device_id;
	
	static int get device_id => _device_id;
	
	static selectDevice(int id, PatrolRecordModel patrol, {bool replace = true}) {
		selectedPatrol = patrol;
		if (id != null) {
			if (_device_data?.isEmpty ?? true) {
				return replace
						? _device_id = id
						: _device_id ??= id;
			}
			if (!_device_data.any((model) => model.id == id)) {
				throw Exception('selected id:$id not exists!\ndevice_data: ${_device_data.map((m) => m.id)}');
			}
			replace
					? _device_id = id
					: _device_id ??= id;
		} else {
			replace
					? _device_id = 1
					: _device_id ??= 1;
		}
	}
	
	
	static List<IJOptionModel> _option_data;
	
	static Future<List<IJOptionModel>> get option_data {
		final completer = Completer<List<IJOptionModel>>();
		DescOptState.manager.fetchInitialData().then((res) {
			_option_data = List<Map<String, dynamic>>.from(res as List)
					.map((data) => IJOptionModel.from(data)).toList();
			completer.complete(_option_data);
		});
		return completer.future;
	}
	
	static Set<int> _selected_ids;
	
	static Set<int> get selected_ids => _selected_ids;
	
	static Future<List<IJOptionModel>> get selected_options {
		final completer = Completer<List<IJOptionModel>>();
		option_data.then((data) {
			completer.complete(data.where((model) => _selected_ids.contains(model.id)).toList());
		});
		return completer.future;
	}
	
	static Map<int, BaseIJState> states = {};
	
	static IJBloC bloC;
	
	/// ---------------------------------------------------------------
	///  indexer for database
	///
	///  [imagejournal_id] id represents for current image journal. Null for
	///                    creating new image journal or performing update if
	///                    this id had been set.
	///  [device_id] id represent for the device id.
	///  [pagenum]   indicating page number also for database queries
	///  ---------------------------------------------------------------
	static int pagenum;
	
	// update via response
	static int imagejournal_id;
	static int selected_machine;
	static int user_id;
	
	// properties
	
	
	static Function(int, int) onLoadProgressOutput = (send, total) {
		print("load: $progress");
	};
	
	static Future
	surfingJournals([int userid, int deviceid, int page_num, int max_num]) async {
		const pth = '/imagejournal/browse/0';
		final res = await Http().dioGet(pth, isCached: true, qparam: {
			'max_num': max_num, 'page_num': page_num, "user_id": userid ?? 0, 'deviceid': deviceid ?? 0
		});
		if (res.statusCode == 200) {
			final body = List<Map<String, dynamic>>.from(res.data as List);
			int counter = (page_num - 1) * max_num;
			body.forEach((bd) {
				final model = ImageModel.fromMap(bd, (e) {}, (e) {});
				bloC.onAdd(counter, bd["description"] as String, model: model, id: bd["id"] as int);
			});
		} else {
		
		}
	}
	
	static Future<List<DeviceModel>>
	readDevices() async {
		const pth = '/device';
		final res = await Http().dioGet(pth, isCached: true);
		final body = res.statusCode == 200
				? List<Map<String, dynamic>>.from(res.data as List)
				: List<Map<String, dynamic>>.from(
				jsonDecode(await UserState.manager.file(IJDevBloC.jsonPath).readAsync()) as List);
		
		// dump to disk
		if (res.statusCode == 200) {
			(DevState.manager.store as DevMainStateStore).dumpServerData(body);
		} else {
		
		}
		return body.map((data) => DeviceModel.from(data)).toList();
	}
	
	static Future<List<IJOptionModel>>
	readOptions({bool cache = true}) async {
		const pth = '/descoption';
		// note: query by page not implemented yet
		final res = await Http().dioGet(
				pth,
				qparam: {'pagenum': -1, 'perpage': -1},
				isCached: cache
		);
		// dump to disk
		final body = res.statusCode == 200
				? List<Map<String, dynamic>>.from(res.data as List)
				: UserState.manager.file(DescOptState.manager.store.localpath).existsSync()
					? List<Map<String, dynamic>>.from(jsonDecode(await UserState.manager.file(
							DescOptState.manager.store.localpath).readAsync()) as List)
					: <Map<String, dynamic>>[];
		
		if (res.statusCode == 200) {
			await UserState.manager.file(DescOptState.manager.store.localpath).writeAsync(jsonEncode(body));
		} else {
			var pass;
		}
		
		return body.isEmpty
			? []
		  : body.map((data) => IJOptionModel.from(data)).toList();
	}
	
	static bool
	isStateCanSave(BaseIJState state) {
		return state is IJStateAdd
				//         || state is IJStateDefault
				|| state is IJStateLoadImage
				|| state is IJStateLoadImageFinished;
	}
	
	static Future<BaseIJState>
	newJournal(IJNewSheetEvent event) {
		imagejournal_id = null;
		_device_id = null;
		selectedPatrol = null;
		file_path = null;
		title = null;
		final completer = Completer<BaseIJState>();
		final result = saveState(IJStateNewSheet(), 'newJournal');
		DevState.manager.msg.bloC.onCreatingFile();
		
		option_data.whenComplete(() {
			selectDescOptions([], replace: false);
			completer.complete(result);
		});
		return completer.future;
	}
	
	static BaseIJState
	saveState(BaseIJState state, String msg) {
		if (isStateCanSave(state)) {
			states[state.rec_id] = state;
		}
		print('saveIJState: ${state.rec_id}, ${state.runtimeType}, from:$msg');
		return state;
	}
	
	static int recIdToRowId(int rec_id) {
		return rec_id - 1;
	}
	
	static int rowIdToRecId(int row_id) {
		return row_id + 1;
	}
	
	static rotateImage() {
	
	}
	
	static final String savingId = uuid.v4();
	static final String uploadingId = uuid.v4();
	static final String loadingId = uuid.v4();
	
	static Future<BaseIJState>
	loadImage(IJLoadImageEvent event, {void onLoad(Image image), void finish(Image image)}) async {
		final rec_id = event.rec_id,
				path = event.file_path,
				image = event.image,
				resize = event.resize,
				description = event.description;
		final state = states[rec_id];
		final result = saveState(IJStateLoadImage(path, state, resize: resize), 'loadImage');
//      final result = IJStateLoadImage(path, state, resize: resize);
//      startLoadingTimer();
		print('loadImage');
		logState(rec_id);
		
		try {
			assert(result.model != null);
			if (image == null) {
				if (result.model.isAValidIdentPath(path)) {
					AppState.bytestotal += ImageModel.getFileSizeByIdent(path);
				} else {
					final stat = UserState.manager.file(path).statSync();
					AppState.bytestotal += stat.size;
				}
				AppState.msg.onFileLoading(loadingId);
				print('onFile loading');
				
				final _onLoad = (Image image) async {
					assert(image != null);
					print('image loaded');
					if (onLoad != null)
						onLoad(image);
					AppState.bytesloaded += result.model.filesize;
					AppState.msg.onFileLoadingSuccess(loadingId);
					if (finish == null)
						bloC.onLoadImageFinished(
								response: image, rec_id: rec_id, message: _OK);
					else {
						final event = IJLoadImageFinishedEvent(rec_id: rec_id, image: image);
						loadImageFinished(event);
						finish(image);
					}
				};
				await result.model.loadImage().then(_onLoad).catchError((e) {
					AppState.bytesloaded = AppState.bytestotal;
					if (finish == null)
						bloC.onLoadImageFinished(message: e, rec_id: rec_id);
					else {
						final event = IJLoadImageFinishedEvent(rec_id: rec_id, image: image, message: e.toString());
						loadImageFinished(event);
						finish(null);
					}
					throw Exception(StackTrace.fromString(e.toString()));
				});
			} else {
				if (finish == null)
					bloC.onLoadImageFinished(
							response: image, rec_id: rec_id, message: _OK);
				else {
					final event = IJLoadImageFinishedEvent(rec_id: rec_id, image: image, message: e.toString());
					loadImageFinished(event);
					finish(null);
				}
			}
		} catch (e) {
			throw Exception(
					'loadImage failed: \n${StackTrace.fromString(e.toString())}');
		}
		
		return result;
	}
	
	static BaseIJState
	loadImageFinished(IJLoadImageFinishedEvent event) {
		final rec_id = event.rec_id,
				message = event.message,
				image = event.image;
		return guard<BaseIJState>(() {
			final state = states[rec_id];
			final result = saveState(IJStateLoadImageFinished(
					message == _OK
							? _OK
							: Msg.onLoadImageFailed(message), state, image), 'loadImageFinished');
			print('loadImageFinished:');
			logState(rec_id);
			
			return result;
		}, 'completing load image: $rec_id failed', error: 'ImageLoadCompleteError');
	}
	
	static edit(BaseIJState state, {String description, Image image}) {
		final prevmodel = state.model;
		final path = prevmodel.path;
		final prevdesc = prevmodel.description;
		if (image == null) {
			prevmodel.description = description;
		} else {
			ImageModel;
		}
	}
	
	static BaseIJState
	addRecord(IJAddEvent event) {
		final
		rec_id = event.rec_id,
				model = event.model,
				desc = event.description,
				id = event.id;
		final result = saveState(IJStateAdd(rec_id, desc ?? model?.description, id: id), 'addRecord');
		states[rec_id] = result;
		if (model == null)
			return result;
		// 1) preload a resized image
		// 2) preload a non-resized image
		result.model = model;
		if (result.model.path != null)
			bloC.onLoadImage(
					result.rec_id,
					path: model.path,
					image: model.resized_image);
		return result;
	}
	
	static void rearrangeRecId() {
		int counter = -1;
		final result = <int, BaseIJState>{};
		states.forEach((i, state) {
			counter ++;
			state.rec_id = state.model.rec_id = counter;
			result[counter] = state;
		});
		states = result;
	}
	
	static BaseIJState
	delRecord(IJDelEvent event) {
		final rec_id = event.rec_id;
		final state = states[rec_id];
		final result = saveState(IJStateDel(state), 'delRecord');
		states.remove(state.rec_id);
		rearrangeRecId();
		return result;
	}
	
	static Future<List<String>>
	filterExistingIMFromDB(List<String> _idents) async {
		List<String> existing_imageRecords;
		const JSON = JsonCodec();
		if (_idents.isEmpty)
			return [];
		final idents = JSON.encode(_idents);
		final request_url = ROUTE.imagejournal
				.toString()
				.split(".")
				.last;
		await Http().dioGet(request_url, qparam: {'idents': idents}).then((response) {
			existing_imageRecords = List<String>.from(response.data as List);
		}).whenComplete(() {
			existing_imageRecords ??= [];
		});
		return List<String>.from(existing_imageRecords);
	}
	
	
	static Future <ImageJournalModel>
	genCustomJournalModel({
		@required int machine_id, @required Set<int> selected_ids, String title,
		int device_id, bool write = false, bool forUpload = false,
		int thumbsize = 128, String path,
	}) async {
		try {
			print('genCustomJournalModel');
			final completer = Completer<ImageJournalModel>();
			final journalModel = ImageJournalModel(
				title: title,
				user_id: UserState.currentUser?.id,
				summary: "",
				conclusion: "",
				imagejournal_id: imagejournal_id,
				device_id: device_id,
				machine_id: machine_id,
				selected_options: selected_ids?.toList() ?? <int>[],
				patrol: selectedPatrol,
			);
			
			print("dumpImage 0");
			await journalModel.addRecords(states.values.toList(), forUpload: forUpload);
			if (write == true) {
				// dumpImages into disk
				states.values.forEach((BaseIJState state) {
					AppState.bytestotal += state?.model?.filesize ?? 0;
					print("dumpImage 1");
					if (state.model.isNotEmpty) {
						state.model.dumpImage(thumbSize: 128).then((f) {
							AppState.bytesloaded += state?.model?.filesize ?? 0;
						});
					}
				});
			}
			
			try {
				if (write == true) {
					print('write path: ${UserState.manager.file(path).getPath()}');
					
					final json_tobe_saved = journalModel.asMap();
					await UserState.manager.file(path)
							.writeAsync(jsonEncode(json_tobe_saved)).then((file) {
						print('save complete');
						completer.complete(journalModel);
						bloC.onSaveFinished(file: file, message: _OK);
					}).catchError((e) {
						print('save failed');
						completer.complete(journalModel);
						bloC.onSaveFinished(message: e);
					});
					return completer.future;
				} else {
					return Future.value(journalModel);
				};
			} catch (e) {
				print('onFileSavingFailed');
				PatrolState.manager.msg.bloC.onFileSavingFailed(savingId);
				throw Exception('genJournalModel failed: \n${StackTrace.fromString(
						e.toString())}');
			}
		} catch (e) {
			print('genCustomJournalModel failed');
			throw Exception(
					'genCustomJournalModel failed: \n${StackTrace.fromString(
							e.toString())}');
		}
	}
	
	static Future <ImageJournalModel>
	genJournalModel({ bool write = false, bool forUpload = false }) async {
		debug('genJournalModel');
		final completer = Completer<ImageJournalModel>();
		final journalModel = ImageJournalModel(
			title: title,
			user_id: UserState.currentUser?.id,
			summary: summary,
			conclusion: conclusion,
			imagejournal_id: imagejournal_id,
			device_id: device_id,
			machine_id: selectedPatrol.patrol.getDevid1(),
			// untested
			selected_options: selected_ids?.toList() ?? <int>[],
			patrol: selectedPatrol,
		);
		
		debug("dumpImage");
		await journalModel.addRecords(states.values.toList(), forUpload: forUpload);
		if (write == true) {
			// dumpImages into disk
			states.values.forEach((BaseIJState state) {
				AppState.bytestotal += state?.model?.filesize ?? 0;
				debug("dumpImage");
				if (state.model.isNotEmpty) {
					state.model.dumpImage().then((f) {
						AppState.bytesloaded += state?.model?.filesize ?? 0;
					});
				}
			});
		}
		
		try {
			debug('filter existing img from db');
			final List<String> existing_im = await filterExistingIMFromDB(
					states.values.where((s) => s.model.isNotEmpty).map((s) => s.model.ident).toList());
			
			// remove resized image
			final recs = journalModel.recs;
			if (existing_im.isNotEmpty) {
				recs.forEach((rec) {
					if (existing_im.contains(rec['ident'])) {
						rec.remove('resized_image');
					}
				});
			}
			
			if (write == true) {
				final json_tobe_saved = journalModel.asMap();
				debug('write path: ${UserState.manager.file(file_path).getPath()}');
				await UserState.manager.file(file_path).writeAsync(
						jsonEncode(json_tobe_saved)).then((file) {
					print('save complete');
					completer.complete(journalModel);
					bloC.onSaveFinished(file: file, message: _OK);
				}).catchError((e) {
					print('save failed');
					completer.complete(journalModel);
					bloC.onSaveFinished(message: e);
				});
				return completer.future;
			} else {
				return Future.value(journalModel);
			};
		} catch (e) {
			throw Exception('genJournalModel failed: \n${StackTrace.fromString(
					e.toString())}');
		}
	}
	
	static BaseIJState
	saveToDisk(IJSaveEvent event) {
		try {
			// if event.file_path is null, a generated path would be provided
			file_path = getJournalPath(event.file_path);
			final result = IJStateSave(file_path, bloC); //saveState(IJStateSave(file_path, bloC));
			if (changed == false)
				return result;
			//startLoadingTimer();
			genJournalModel(write: true);
			//fixme: notifier here...
			return result;;
		} catch (e) {
			throw Exception(
					'saveToDisk failed: \n${StackTrace.fromString(e.toString())}');
		}
	}
	
	static BaseIJState
	saveFinished(IJSaveFinishedEvent event) {
		final message = event.message;
		final result = saveState(IJStateSaveFinished(
			message == _OK
				? _OK
				: Msg.onSavingFailed, bloC), 'saveFinished');
		return result;
	}
	
	static BaseIJState
	upload() {
		final path = ROUTE.imagejournal
				.toString()
				.split('.')
				.last;
		final result = saveState(IJStateUpload(bloC), 'upload');
//      startLoadingTimer();
		genJournalModel(write: false, forUpload: true).then((data) async {
			final formData = data.asMultipartForm();
			final fields = formData.fields;
			final files = formData.files.where((f) => f != null);
			final raw_list = [utf8.encode(jsonEncode(fields))]
				..addAll(files.map((f) => f.bytes));
			final binary_data = TwoDBytes(raw_list);
			await Http().dioMultiPost(
					path, binary_data: binary_data,
					onSend: (int send, int total) {
						AppState.bytesloaded = send;
						AppState.bytestotal = total;
//                IJState.processing = BgProc.onUpload;
						onLoadProgressOutput(AppState.bytesloaded, AppState.bytestotal);
					}).then((response) {
//               Http().log('respones:', ELevel.info);
//               Http().log('${FN.stringPrettier(response.data)}', ELevel.warning);
				print('respones:');
				print('${FN.stringPrettier(response.data)}');
				bloC.onUploadFinished(response: response, message: _OK);
			}).catchError((e) {
				Http().log('${StackTrace.fromString(e.toString())}', ELevel.error);
				throw Exception('${StackTrace.fromString(e.toString())}');
				bloC.onUploadFinished(message: e);
			});
		});
		return result;
	}
	
	static BaseIJState
	uploadFinished(IJUploadFinishedEvent event) {
		final message = event.message;
		final response = event.response;
		final result = saveState(IJStateUploadFinished(
				message == _OK
						? _OK
						: Msg.onUploadFailed(message), bloC), 'uploadFinished');
		_updateStatesByResponse(response);
		return result;
	}
	
	static String getImagePath(String path) {
		// untested:
		return Path.join(ImageModel.RESIZED_PATH, Path.basename(path));
//      return Path.join(config.assets.resized_path, Path.basename(path));
	}
	
	static String getJournalFilename({String basepath, bool exists(String path)}) {
		if (basepath != null) {
			String getPath(String filename) {
				if (exists(Path.join(basepath, filename))) {
					final ver = int.parse(filename
							.split('-')
							.last
							.split('.json')
							.first
							.substring(1));
					final filename_noVer = filename
							.split('V$ver.json')
							.first;
					return getPath('${filename_noVer}V${ver + 1}.json');
				} else {
					return filename;
				}
			}
			final filename = _jsonPath(
					path: null,
					imagejournal_id: selectedPatrol?.patrol
							?.getDevId()
							?.first, // untested:
					device_id: device_id
			);
			return getPath(filename);
		} else {
			return _jsonPath(
					path: null,
					imagejournal_id: selectedPatrol?.patrol
							?.getDevId()
							?.first, // untested:
					device_id: device_id
			);
		}
	}
	
	static String getJournalPath([String path]) {
		final result = _jsonPath(
				path: path,
				imagejournal_id: imagejournal_id,
				device_id: device_id
		);
		final finalpath = Path.join(config.assets.journal_path, Path.basename(result));
		debug('finalpath: $finalpath');
		return finalpath;
	}
	
	static void _updateStatesByResponse(Response response) {
		final responseBody = response.data as Map<String, dynamic>;
		final patrol = PatrolRecordModel.fromMap(
				responseBody['content']['patrol'] as Map<String, dynamic>);
		
		selectDevice(
				responseBody['content']['device_id'] as int, patrol);
		
		imagejournal_id = responseBody['id'] as int;
		file_path = getJournalPath();
	}
	
	/*static void _onLoadProgress(Timer t) {
      if (IJState.processing == BgProc.onIdle)
         t.cancel();
      onLoadProgressOutput(AppState.bytesloaded, AppState.bytestotal);
   }*/
	
	static selectDescOptions(List<int> ids, {bool replace = true}) {
		if (_option_data?.isEmpty ?? true) {
			return replace
					? _selected_ids = ids.toSet()
					: _selected_ids ??= ids.toSet();
		}
		for (var i = 0; i < ids.length; ++i) {
			final id = ids[i];
			if (!_option_data.any((model) => model.id == id)) {
				throw Exception("selected id:$id not exists!"
						"\noption_data: ${_option_data.map((m) => m.id)}");
			}
		}
		replace
				? _selected_ids = ids.toSet()
				: _selected_ids ??= ids.toSet();
	}
	
	
	static BaseIJState
	queryIJByDevice(IJQueryDevEvent event) {
	
	}
	
	static Future<BaseIJState>
	loadFromDisk(IJLoadEvent event, {void finished(BaseIJState state)}) async {
		file_path = getJournalPath(event.file_path);
		final result = saveState(IJStateLoad(event.file_path, bloC), 'loadFromDisk');
		try {
//         startLoadingTimer();
			final json_text = await UserState.manager.file(file_path).readAsync();
			print('[loadFromDisk] load journal on disk:');
			print(json_text);
			
			final json = jsonDecode(json_text);
			final recs = json["recs"] as List;
			final response = <int, ImageModel>{};
			final patrolmap = json["patrol"] as Map<String, dynamic>;
			final patrol = PatrolRecordModel.fromMap(patrolmap);
			
			title = json['title'] as String;
			summary = json['summary'] as String;
			conclusion = json['conclusion'] as String;
			
			selectDevice(json['device_id'] as int, patrol);
			selectDescOptions(List<int>.from(json['selected_options'] as List).toList());
			
			var img_loaded = 0;
			for (var i = 0; i < recs.length; ++i) {
				final rec = recs[i] as Map<String, dynamic>;
				response[rec["rec_id"] as int] = ImageModel.fromMap(rec, (image) {
					img_loaded ++;
					AppState.bytesloaded += response[rec["rec_id"] as int].filesize;
					print('[loadFromDisk] content:${response}');
					if (img_loaded == recs.length) {
						if (finished == null)
							bloC.onLoadFinished(
									response: response, message: _OK, file_path: file_path);
						else {
							final event = IJLoadFinishedEvent(file_path: file_path, content: response, message: _OK);
							finished(loadFinished(event));
						}
					}
				}, (error) {
					if (finished == null)
						bloC.onLoadFinished(message: error, file_path: file_path);
					else {
						final event = IJLoadFinishedEvent(file_path: file_path, content: response, message: error.toString());
						finished(loadFinished(event));
					}
					PatrolState.manager.msg.bloC.onFileUploadingFailed("", uploadingId);
					throw Exception('load wjournal failed:\n${StackTrace.fromString(error.toString())}');
				});
				final filesize = ImageModel.getFileSizeByIdent(
						rec['ident'] as String);
				AppState.bytestotal += filesize;
			}
		} catch (e) {
			PatrolState.manager.msg.bloC.onFileUploadingFailed("", uploadingId);
			throw Exception(
					'loadFromDisk failed: \n${StackTrace.fromString(e.toString())}');
		}
		return result;
	}
	
	/* static void startLoadingTimer() {
      if (AppState.loadingTimer != null)
         AppState.loadingTimer.cancel();
      AppState.loadingTimer = Timer.periodic(Duration(milliseconds: 1000), _onLoadProgress);
   }*/
	
	static logState(int rec_id) {
		if (states[rec_id] == null)
			return;
		print('> state: $rec_id');
		print('  model.ident    : ${states[rec_id].model?.ident}');
		print('  model.orig_name: ${states[rec_id].model?.orig_name}');
		print('  model.resize   : ${states[rec_id].model?.resize}');
		print('  model.desc     : ${states[rec_id].model?.description}\n');
	}
	
	static BaseIJState
	loadFinished(IJLoadFinishedEvent event) {
		return guard<BaseIJState>(() {
			final result = saveState(IJStateLoadFinished(
					event.message == _OK
							? _OK
							: Msg.onLoadJournalFailed(event.message),
					bloC), 'loadFinished'
			);
			states = {};
			print('load wjournal finished: ${event.content}');
			event.content.forEach((rec_id, model) {
				states[rec_id] = IJState.addRecord(IJAddEvent(rec_id: rec_id, model: model));
				logState(rec_id);
			});
			return result;
		},
				'completing json loading failed',
				error: 'ComopleteJsonError');
	}
}
/*
*
*
*
*              B l o C ( Business logic )
*
*
*
* */

final TEMP_PATH_PTN = RegExp('[D][0-9]+-[J][0-9]+-');

class IJBloC extends Bloc<IJEvents, BaseIJState> {
	IJEvents last_event;
	BaseIJState last_state;
	
	static bool isDbPath(String path) {
		return path.startsWith(TEMP_PATH_PTN);
	}
	
	@override
	void onError(Object error, StackTrace stacktrace) {
		// TODO: implement onError
		super.onError(error, stacktrace);
		throw Exception('$error, \n$stacktrace');
	}
	
	@override
	BaseIJState get initialState {
		IJState.bloC = this;
		return IJStateDefault();
	}
	
	/*
     >| transform
      |
     >| yield
      |IJStateLoadImageFinished
     >| transition
   */
	@override
	void onTransition(Transition<IJEvents, BaseIJState> transition) {
		super.onTransition(transition);
	}
	
	bool isDuplicatedEvent(IJEvents event) {
		final ret = last_event != null &&
				last_event.rec_id == event.rec_id &&
				last_event.event == event.event;
		if (ret == true)
			throw Exception('duddddddddddd');
		print('pass, $event');
		return ret;
	}
	
	@override
	Stream<BaseIJState> mapEventToState(IJEvents event) async* {
		if (currentState == last_state)
			yield null;
		
		last_state = currentState;
		BaseIJState new_state;
		
		switch (event.event) {
			case EIJEvents.newsheet:
				new_state = await IJState.newJournal(event as IJNewSheetEvent);
				break;
			case EIJEvents.add:
				new_state = IJState.addRecord(event as IJAddEvent);
				break;
			case EIJEvents.del:
				new_state = IJState.delRecord(event as IJDelEvent) as IJStateDel;
				break;
			case EIJEvents.load:
				new_state = await IJState.loadFromDisk(event as IJLoadEvent) as IJStateLoad;
				break;
			case EIJEvents.save:
				new_state = IJState.saveToDisk(event as IJSaveEvent) as IJStateSave;
				break;
			case EIJEvents.upload:
				new_state = IJState.upload() as IJStateUpload;
				break;
			case EIJEvents.loadImage:
				new_state = await IJState.loadImage(event as IJLoadImageEvent) as IJStateLoadImage;
				break;
			case EIJEvents.loadImageFinished:
				new_state = IJState.loadImageFinished(event as IJLoadImageFinishedEvent) as IJStateLoadImageFinished;
				break;
			case EIJEvents.loadFinished:
				new_state = IJState.loadFinished(event as IJLoadFinishedEvent) as IJStateLoadFinished;
				break;
			case EIJEvents.saveFinished:
				new_state = IJState.saveFinished(event as IJSaveFinishedEvent) as IJStateSaveFinished;
				break;
			case EIJEvents.uploadFinished:
				new_state = IJState.uploadFinished(event as IJUploadFinishedEvent) as IJStateUploadFinished;
				break;
			case EIJEvents.setState:
				new_state = IJSetState();
				break;
			case EIJEvents.browse:
				new_state = IJBrowseState();
				break;
			default:
				throw Exception('Uncuahgt exception');
		}
		print('yield state: ${new_state}');
		yield new_state;
	}
	
	void onNewSheet() {
		dispatch(IJNewSheetEvent());
	}
	
	void onAdd(int rec_id, String description, {ImageModel model, int id}) {
		dispatch(IJAddEvent(rec_id: rec_id, description: description, model: model, id: id));
	}
	
	void onDel(int rec_id) {
		dispatch(IJDelEvent(rec_id: rec_id));
	}
	
	void onSave([String name]) {
		dispatch(IJSaveEvent(file_path: name));
	}
	
	void onSaveFinished({StoreInf file, Object message}) {
		dispatch(IJSaveFinishedEvent(file: file, message: message.toString()));
	}
	
	void onUpload() {
		dispatch(IJUploadEvent());
	}
	
	void onUploadFinished({Response response, Object message}) {
		dispatch(IJUploadFinishedEvent(message: message.toString(), response: response));
	}
	
	void onLoad(String name) {
		dispatch(IJLoadEvent(file_path: name));
	}
	
	void onLoadFinished({Map<int, ImageModel> response, Object message, String file_path}) {
		dispatch(IJLoadFinishedEvent(
				message: message.toString(),
				file_path: file_path, content: response));
	}
	
	void onLoadImage(int rec_id, {String path, Image image}) {
		dispatch(IJLoadImageEvent(rec_id: rec_id, file_path: path, image: image));
	}
	
	void onLoadImageFinished({Image response, Object message, int rec_id}) {
		dispatch(IJLoadImageFinishedEvent(rec_id: rec_id, image: response,
				message: message.toString()));
	}
	
	void onSetState() {
		dispatch(IJSetStateEvent());
	}
	
	void onBrowse() {
		dispatch(IJBrowseEvent());
	}
	
}


String _jsonPath({String path, int imagejournal_id, int device_id, bool reversion = false}) {
	// reversion
	if (path != null && reversion == true)
		return _versionPath(path, ij_id: imagejournal_id, device_id: device_id);
	// save to a specific path or for overriding existing file;
	if (path != null) {
		return path;
	}
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
	return 'D${device_id ?? ""}-J${imagejournal_id ?? ""}-$time-V1.json';
}

String _versionPath(String path, {int device_id, int ij_id}) {
	final dir = Path.dirname(path);
	final file_vname = Path.basenameWithoutExtension(path);
	
	if (!file_vname
			.split('-')
			.last
			.startsWith(RegExp('[V][0-9]+')))
		throw Exception('Uncaught Exception, invalid json filename');
	
	final file_name = file_vname.substring(0, file_vname.lastIndexOf('-'));
	final version = int.parse(file_vname.substring(file_vname.lastIndexOf('-') + 2));
	if (UserState.manager.file(path).existsSync()) {
		return Path.join(dir, '${file_name}-V${version + 1}');
	}
	return path;
}














