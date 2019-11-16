
import 'dart:async';
import 'dart:io';

import 'package:nxp_bloc/mediators/controllers/nfcio_state.dart';
import 'package:nxp_bloc/mediators/models/image_model.dart';
import "package:common/src/common.log.dart";
import 'package:nxp_bloc/mediators/models/takeshotModel.dart';




class NtagLogger extends TimeStampFileLogger<EIO> {
	static String get SPLITER 			=> TimeStampFileLogger.SPLITER;
	static String get EXTRA_SUFFIX 	=> TimeStampFileLogger.EXTRA_SUFFIX;
	@override final bool storeExtra;
	@override final int  maxrecs;
	@override final bool duplicate;
	String path;
	
	NtagLogger({this.path, this.duplicate = false, this.maxrecs = 200, this.storeExtra = false})
			:super(path: path, duplicate: duplicate, maxrecs: maxrecs, storeExtra:storeExtra
	){
		logData = [];
		logDataExtra = [];
		completer = Completer();
		fileInit();
	}
	
	static String getTime([DateTime time]){
		ImageModel;
		return ImageModel.getTime(time, "/", " ", ":");
	}
	
	@override void log({EIO key, String data, String supplement}){
		final logline = "${getTime()} ${key.toString().split('.').last} $data".trim() + SPLITER;
		if(!duplicate && logData.contains(logline)){
		}else{
			if (!storeExtra){
				logData.add(logline);
				file_sink.write(logline);
			}else{
//				logDataExtra.add(supplement ?? "");
//				extraFile_sink.writeln(supplement ?? "");
				logData.add(logline);
				file_sink.write(logline);
			}
			logDataExtra.add((supplement  ?? "0") + SPLITER);
			extraFile_sink.write((supplement  ?? "0") + SPLITER);
		}
	}
	
	void updateExtra(){
		extraFile_sink.close();
		File(logPath + EXTRA_SUFFIX).writeAsStringSync("");
		extraFile_sink = File(logPath + EXTRA_SUFFIX).openWrite(mode: FileMode.append);
		extraFile_sink.writeAll(logDataExtra, SPLITER);
	}
	
	// unused:
	Iterable<TNtagLogRecord> getFilteredRecords(EIO mode) {
		final key = mode.toString().split('.').last;
		final records = logData.where((e) => e.split(' ')[1] == key).toList();
		if (storeExtra){
			return records.map((l){
				final extra = logDataExtra[logData.indexOf(l)];
				return TNtagLogRecord(l, extra);
			});
		}else{
			return records.map((l) => TNtagLogRecord(l, ""));
		}
	}
}

