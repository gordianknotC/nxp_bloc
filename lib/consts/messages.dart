import 'package:ansiCodec/ansiCodec.dart';
import 'package:common/common.dart';
import 'package:nxp_bloc/mediators/controllers/user_bloc.dart';

enum LANGUAGES {
	english,
	traditionalChinese,
	simplifiedChinese,
}

class UI<T extends String> {
	static String get lanEnglish 	=> "English";
	static String get langTW 			=> "繁體中文";
	static String get langCN 			=> "简体中文";
	
	
	
	static String get transceiveFailed => index([
		"NFC Transceive Failed","NFC Transceive Failed","NFC Transceive Failed"
	]);
	static String get transceiveFailedDescription => index([
		"sorry for interupting your task, this error indicates a nfc restart process is under going on your nfc device. If afterward your nfc device is not in response, please reactivate your app.",
		'報歉, 此錯誤訊息暗示著NFC裝置於背景作業重啓中, 如果之後您的NFC無回應, 請將APP縮至最小再放大.',
		'報歉, 此錯誤訊息暗示著NFC裝置於背景作業重啓中, 如果之後您的NFC無回應, 請將APP縮至最小再放大.',
	]);
	
	
	static String get imageRecordDescription => index([
		"Description", "影像描述", "影像描述"
	]);
	
	static String get imageRecordDescriptionHint => index([
		"add description here...", "編寫影像描述, 最多五行...", "編寫影像描述, 最多五行..."
	]);
	
	static String get imageRecordDelDescription => index([
		"delete", "刪除", "刪除"
	]);
	
	
	/*
	*
	* 			P a t r o l W i d g et
	*
	* */
	static String get patrolWTypeDialogTitle => index([
		"Grease cup Type", "油杯型號", "油杯型號"
	]);
	static String get patrolWTypeDialogDescription => index([
		"select existing type or create a new one", "請選擇油杯型號", "請選擇油杯型號"
	]);
	static String get patrolWMaintainDialogTitle => index([
		"Grease cup Type", "油杯型號", "油杯型號"
	]);
	static String get patrolWMaintainDialogDescription => index([
		"select existing type or create a new one", "請選擇油杯型號", "請選擇油杯型號"
	]);
	
	
	/*
	*
	*
	* */
	static String get getAuthDescription => index([
		"fill out following fields to login or press auth to get authorization token",
		"請填妥以下欄位以取得登入授權",
		""
	]);
	
	static String get permissionLabel => index([
		'permissions', '設定授權', '設定授權'
	]);
	static String get permissionAdmin => index([
		'administrator', 'administrator', 'administrator'
	]);
	static String get permissionEngineer => index([
		'engineer', 'engineer', 'engineer'
	]);
	static String get permissionUser => index([
		'user', 'user', 'user'
	]);
	
	static String get hintTextEmail => index([
		"Email", "郵件 Email", "邮件 Email"
	]);
	
	static String get hintTextPassword => index([
		"Password", "密碼 Password", "密码 Password"
	]);
	
	static String get hintTextDisplay => index([
		"Nickname", "顯示名稱 Nickname", "显示名称 Nickname"
	]);
	
	static String get userLogin => index([
		'login', '登入' , '登入'
	]);
	static String get userSignup => index([
		'signup', '註冊' , '注册'
	]);
	static String get userSwitchToLogin => index([
		'switch to login page', '切換至登入頁面' , '切换至登入页面'
	]);
	static String get userSwitchToSignup => index([
		'switch to signup page', '切換至註冊頁面', '切换至注册页面'
	]);
	
	static String get userLogout => index([
		"Lougout", "登出"
	]);

	
	static String userHello (String username) => index([
		"Hello $username", "歡迎 $username", "欢迎 $username"
	]);
	
	static String get userPWDFilloutDesc => index([
		'please fillout following password to perform login', '請輸入密碼以進行登入作業!',
	]);
	
	static String get upload => index([
		'upload', '上傳', '上传'
	]);
	
	static String get uploadUnsaved => index([
		'upload\n(unsaved)', '上傳(未儲存)', '上传(未储存)'
	]);
	
	static String get save => index([
		'save', '儲存', '储存'
	]);
	
	static String get saveUnsaved => index([
		'save\n(unsaved)', '未儲存', '未储存'
	]);
	
	static String get saveAlreadySaved => index([
		'already saved', '己儲存', '己储存'
	]);
	
	static String get ijEmptyDescription => index([
		"no description", "無內容描述", "无内容描述"
	]);
	
	static String get ijDescription => index([
		"Description", "影像描述", "影像描述"
	]);
	
	static String get ijAttachNtagTile => index([
		"Attach Ntag to Journal", "指定Ntag", "指定Ntag"
	]);
	
	static String get ijAttachNtagB => index([
		"attach ntag\nrecord to journal", "指定Ntag", "指定Ntag"
	]);
	
	
	/*
	*
	*
	*/
	static String get createOptionTitle => index([
		"create new\noptions", "新增事項", "新增事项"
	]);
	
	static String batchMergeBtTitle(int len) => index([
		"batch merge", "合併", "合併"
	]);
	
	static String batchMergeBtDesc (List<int> ids){
		final result = ids.isNotEmpty
				? index(["#${FN.head(ids)}->#${ids.last}", "#$ids->#${ids.last}"])
				: index(["", ""]);
		return result;
	}
	
	static String get batchEditBtTitle => index([
		"batch edit", "批次編輯", "批次编辑"
	]);
	
	static String batchEditBtDesc (List<int> ids) => index([
		ids.toString(), ids.toString()
	]);
	
	static String get batchDeleteBtTitle => index([
		"batch delete", "批次刪除", "批次删除"
	]);
	
	static String batchDeleteBtDesc (List<int> ids) => index([
		ids.toString(), ids.toString()
	]);
	
	/*
	*
	*
	*
	* */
	
	static String get confirmDeletion => index([
		"Confirm Deletion", "請確認是否刪除", "请确认是否删除"
	]);
	
	static String get delThumbsOfWholeRecord => index([
		"Confirm Deletion", "刪除所有影像將一併刪除整筆資料,是否刪除?", "删除所有影像将一併删除整笔资料,是否删除?"
	]);
	
	static String get pickDuplicatedImageDialogTitle => index([
		'Image Already Exists', '影像已存在', '影像已存在'
	]);
	static String get pickDuplicatedImageDialogSubtitle => index([
		'image you picked up already exists, please tap confirm to exists', '選取之影像已存在,請點選確認!', '选取之影像已存在,请点选确认!'
	]);
	
	
	static String get imageRecordRenderFailed => index([
		'render image failed', '影像讀取失敗', '影像读取失败'
	]);
	static String get imageRecordRendering => index([
		'rendering image...', '影像讀讀中...', '影像读读中...'
	]);
	
	static String get recreateNewTakeshotRecord => index([
		"create new record", "重新創建新記錄", "重新创建新记录"
	]);
	
	static String get takeshotDialogNtagUnattached => index([
		"unattached", "尚未指定NTAG", "尚未指定NTAG"
	]);
	
	static String get takeShotWaysOfAddImagesTitle => index([
		'Please opt either way to add image',
		'請選擇新增影像的方式',
		'请选择新增影像的方式'
	]);

  static String get thumbPreviewTitle => index([
  	'Images and Descriptions', '編輯影像描述', '编辑影像描述'
	]);
	
	
	static String get thumbPreviewSubtitle => index([
		'Images and Descriptions', '編輯影像及描述', '编辑影像及描述'
	]);

  static String get pickupDuplicatedImageTitle => index([
  	'Duplicated Image', '所選取之影像己重複', '所选取之影像己重複'
	]);

  static String get pickupFailedTitle => index([
  	'Internal Error', '選取影像時發生內部錯誤', '选取影像时发生内部错误'
	]);

  static String get defectsTitle => index([
  	"Defects and Irregularities", "缺失及異常事項", "缺失及异常事项"
	]);
	
	static String get defectsSubtitle => index([
		"Multiiple Selection", "選單可複選", "选单可複选"
	]);
	
	static String get batchProcessTitle => index([
		'Select Batch Command', '請選擇欲執行的批次命令', '请选择欲执行的批次命令'
	]);
	static String get batchProcessSubtitle => index([
		'',
		''
	]);

  
	
  static Map<int, String> numberSymbols = {
  	0: "⓿",
  	1: "➊",
		2: "➋",
		3: "➌",
		4: "➍",
		5: "➎",
		6: "➏",
		7: "➐",
		8: "➑",
		9: "➒",
	};
	static String get symbol1 => index([
		"➊", "➊"
	]);
	static String get symbol2 => index([
		"➋", "➋"
	]);
	static String get symbol3 => index([
		"➌", "➌"
	]);
	static String get symbol4 => index([
		"➍", "➍"
	]);
	
  static String get thumbPreviewNoImageTitle => index([
  	'', '請先選取影像', '请先选取影像'
	]);

  static String get thumbPreviewNoImageSubtitle => index([
  	'', '', ''
	]);

 


 /*
 *
 * 			W O R K     J O U R N A L
 *
 */
	static String get wjournalBrwosingListEndofList => index([
		"end of data list", "資 料 未 端", "資 料 未 端"
	]);
	
	static String get wjournalBrwosingListNoContent => index([
		"no content...", "無內容", "無內容"
	]);
	
	static String get wjournalBrowsingListLoading => index([
		'loading images please wait...', '載入資料中, 情稍後...', '載入資料中, 情稍後...'
	]);
	
	static String get wjournalBrowsingListPrevBack => index([
		"back", "返迴", "返迴"
	]);
	static String get workjournalHelp1 => index([
		"", "選擇巡檢影像記錄", "选择巡检影像记录"
	]);
	static String get workjournalHelp2 => index([
		"", "編緒日誌", "编绪日誌"
	]);
	static String get workjournalHelp3 => index([
		"", "儲存/上傳日誌", "储存/上传日誌"
	]);
	static String get journalImageListTitle => index([
		'', '日誌影像列表', '日誌影像列表'
	]);
	static String get workJournalBrowsingTitle => index([
		"Select Work Journal",  '選擇日誌', '选择日誌'
	]);
	static String get workJournalBrowsingSubtitle => index([
		"", '', ''
	]);
	static String get workjournalTitle => index([
		'Work Journal Upload', '上傳工作日誌', '上传工作日誌'
	]);
	
	/*
	* 		N T A G    B R O W S I N G
	*
	*
	* */
	static String get date => index([
		'date','日期','日期'
	]);
	static String get description => index([
		'description','描述','描述'
	]);
	static String get device => index([
		'device',	'油杯',	'油杯'
	]);
	static String get tagId => index([
		'tagId', 'Tag編號', 'Tag编号'
	]);
	static String get tagName => index([
		'tag name',	'裝置名',	'装置名'
	]);
	static String get tagPlace => index([
		'tag area', '地區名', '地区名'
	]);
	
	static String takeShotAddImage(int i) => index([
		'add image($i)','新增影像($i)', '新增影像($i)'
	]);
	
	static String get takeShotBrowsingTitle => index([
		'Select Edit pre-saved images', '編輯影像綁定', '编辑影像绑定'
	]);
	
	static String get takeShotBrowsingSubTitle => index([
		'Select Edit pre-saved images', '選取影像以進行綁定編輯', '选取影像以进行绑定编辑'
	]);
	
	static String get takeShotPickCamera => index([
		"takeshot", "拍照", "拍照"
	]);
	static String get takeShotPickImage => index([
		"pickImage", "載入影像", "载入影像"
	]);
	
	static String get ntagBrwTitle => index([
		"Select Ntag","請選擇NTAG","请选择NTAG"
	]);
	static String get ntagBrwSubTitle => index([
		"assign ntag to image previously snapshoot", "請為先前頁拍攝的影像指定NTAG,","请为先前页拍摄的影像指定NTAG,"
	]);
	static String get ntagSortBy => index([
		"Sort by", "排序方式",
		"排序方式"
	]);
	static String get ThumbDescription => index([
		'description ...',
		'描述 ...',
		'描述 ...'
	]);
	
	
	/*
	* 		T A K E S H O T
	*
	* */
	static String get shotsaveBtAlreadSaved =>
			index([
				"save image\n(alread saved)",
				"己儲存"
				"己储存"
			]);
	static String get shotsaveBtUnsaved =>
			index([
				"save image\n(unsaved)",
				"未儲存",
			  "未储存"
			]);
	static String get shotsaveBtStepIncompleted =>
			index([
				"save image\n(complete step1 first)",
				"請先指定NTAG",
				"请先指定NTAG"
			]);
	static String get shotPatrolBtUnattached =>
			index([
			  "assign ntag\nto current imaeg",
				"指定NTAG",
				"指定NTAG"
			]);

	static String shotPatrolBtAttached(int id) =>
			index([
				"ntagId: $id",
				"ntagId: $id",
				"ntagId: $id"
			]);
	
	/*
	*
	* 			M E N U
	*
	* */
	static String get MenuHome => index([
		'home', '首頁', '首頁'
	]);
	static String get MenuAccount =>
			index([
				'account', '帳戶', '帳戶'
			]);
	static String get MenuSetting =>
			index([
				'settings', '設定', '設定'
			]);
	static String get MenuPatrol =>
		index([
			'patrol', '巡檢', '巡检'
		]);
	static String get MenuUserOption =>
			index([
				'user option', '使用者設定', '使用者设定'
			]);
	static String get MenuUserReset =>
			index([
				'user reset', '工程師重設', '工程师重设'
			]);
	static String get MenuInitialReset =>
			index([
				'initial reset', '管理員初始化', '管理员初始化'
			]);
	static String get MenuWJournal =>
			index([
				'takeshot', '日誌拍照', '日誌拍照'
			]);
	static String get MenuWJournalBrowse =>
			index([
				'browse journal', '日誌檢視', '日誌检视'
			]);
	static String get onWJournalUpload =>
		index([
				'journal upload', '日誌上傳', '日誌上传'
		]);
	static String get MenuBoot => index([
		'boot', '開機', '開機']);
	
	static String get MenuShutdown => index([
		'shutdown', '關機', '關機']);
	/*
	*
	* 		S E T T I N G   P A G E
	*
	* */
	
	static String get SettingMockIOTitle =>
		index([
			'Mock NFC IO results',
			'虛擬 IO 測試'
			'虚拟 IO 测试',
		]);
	static String get SettingIOTitle =>
		index([
			'NFC read/write IO setting',
			'NFC 讀寫設定',
			'NFC 读写设定',
		]);
	
	
	/*
	*
	* 		M E S S E N G E R S
	*
	* */
	static String get msgNFCommunicating =>
			index([
				'nfc communicating...',
				'讀寫通訊命令中...',
				'读写通讯命令中...'
			]);
	
	static String get msgNFCPatrolStart =>
			index([
				'start patrol mode...',
				'巡檢開始...',
				'巡检开始...'
			]);
	
	static String get msgNFCBootStart =>
			index([
				'booting...',
				'裝置開機...',
				'裝置開機...'
			]);
	
	static String get msgNFCShutdownStart =>
			index([
				'shutdown...',
				'裝置關機...',
				'裝置關機...'
			]);
	static String get msgNFCUserOptStart =>
			index([
				'start user-config mode...',
				'設定開始...',
				'设定开始...'
			]);
	
	static String get msgNFCEngineerResetStart =>
			index([
				'start reset mode...',
				'重置開始...',
				'重置开始...'
			]);
	
	static String get msgNFCAdminInitialStart =>
			index([
				'start initialization mode...',
				'初始化開始...',
				'初始化开始...'
			]);
	
	static String get btConfirmIdWritten => index([
		'confirm', '確認寫入', '確認寫入'
	]);
	static String get btReport => index([
		'report', '傳送報告', '传送报告'
	]);
	
	static String get btCancel =>
			index([
				"cancel",
				"取消",
				"取消"
			]);
	
	static String get btConfirm =>
			index([
				"submit",
				"確認",
				"确认"
			]);
	
	static String get btAdminMode =>
			index([
				"login as administrator",
				"以管理者權限登入",
				"以管理者权限登入"
			]);
	
	static String get btEngineerMode =>
			index([
				"login as engineer",
				"以工程師權限登入",
				"以工程师权限登入"
			]);
	
	static String get btUserMode =>
			index([
				"login as user",
				"以使用者權限登入",
				"以使用者权限登入"
			]);
	
	static String get staticPatrolTitle =>
			index([
				"Ntag Content",
				"己讀取之Ntag內容",
				"己读取之Ntag内容"
			]);
	
	static String get staticPatrolWriteIdButton =>
			index([
				"confirm id written",
				"確認寫入ID",
				"确认写入ID"
			]);
	
	static String get backText =>
			index([
				"back",
				"返回上一頁",
				"返回上一页"
			]);
	
	static String get msgCustomConfigNeedRestart =>
			index([
				'app need restart to take effect for customizing configuration path',
				'應用程序需重啓\n以進行初客制設定',
				'应用程序需重啓\n以进行初客制设定'
			]);
	
	static String get msgAppLockedForCycleProcessing =>
			index([
				'App locked, since some important tasks are currently processing',
				'重要程序當未完成\n應用程序上鎖',
				'重要程序当未完成\n应用程序上锁'
			]);
	
	static String index(List<String> data) => data[Msg.lan.index] ?? data[0];
	
	
	/*
	*
	* 			N F C   C Y C L E   I O
	*
	*/
	static String get cyclePerformSuccessTitle => index([
		'Task Done!', '執行操作成功!','执行操作成功!'
	]);
	static String get cyclePerformSuccessSubTitle => index([
		'content as follows','讀取內容如下', '读取内容如下'
	]);
	// ----------------------
	static String get cyclePatrolStart => index([
		'perform patrol task', '執行巡檢','执行巡检'
	]);
	static String get cyclePatrolCancel => index([
		'cancel task', '取消', '取消'
	]);
	// ----------------------
	static String get cycleBootStart => index([
		'boot', '執行開機','執行開機'
	]);
	static String get cycleShutdownStart => index([
		'shutdown', '執行關機','執行關機'
	]);
 
	// ----------------------
	static String get cycleUopStart => index([
		'perform user config task', '寫入使用者設定', '写入使用者设定'
	]);
	static String get cycleUopCancel => index([
		'cancel task', '取消', '取消'
	]);
	// ----------------------
	static String get cycleUrstStart => index([
		'perform engineer reset task', '寫入重設', '写入重设'
	]);
	static String get cycleUrstCancel => index([
		'cancel task', '取消', '取消'
	]);
	// ----------------------
	static String get cycleInitialStart => index([
		'perform initial reset task', '寫入重設', '写入重设'
	]);
	static String get cycleInitialCancel => index([
		'cancel task', '取消', '取消'
	]);
	// ----------------------
	static String get cycleUrstLoad => index([
		'load config', '載入設定檔', '载入设定档'
	]);
	static String get cycleInitialLoad => index([
		'load config', '載入設定檔', '载入设定档'
	]);
	
	/*
	*
	* 			N F C  R e c o r d
	*
	*/
	static String get patrolRecordUnattached => index([
		'Unattached', '尚未指定', '尚未指定'
	]);
	
	
	static String get patrolId =>
			index([
				"id",
				"id",
				"id"
			]);
	
	static String get patrolName =>
			index([
				'name',
				'裝置名',
				'装置名'
			]);
	
	static String get patrolNameDesc =>
			index([
				'give it a name for your device',
				'請為該裝置命名',
				'请为该装置命名'
			]);
	
	static String get patrolNameHint =>
			index([
				'',
				'中英混合字元(不支援簡體)',
				'中英溷合字元(不支援繁体)'
			]);
	
	static String get patrolArea =>
			index([
				'area',
				'所在區域',
				'所在区域'
			]);
	
	static String get patrolAreaDesc =>
			index([
				'where this device located',
				'該裝置所在區域',
				'该装置所在区域'
			]);
	
	static String get patrolAreaHint =>
			index([
				'',
				'中英混合字元(不支援簡體)',
				'中英溷合字元(不支援繁体)'
			]);
	
	static String get patrolTimestamp =>
			index([
				'timestamp',
				'時間碼',
				'时间码'
			]);
	
	static String get patrolSetup =>
			index([
				'setup',
				'更換週期',
				'更换週期'
			]);
	
	static String get patrolType =>
			index([
				'type',
				'油杯型號',
				'油杯型号'
			]);
	
	static String get patrolTypeDesc =>
			index([
				'type',
				'輸入油杯型號代碼',
				'输入油杯型号代码'
			]);
	
	static String get patrolTypeHint =>
			index([
				'type',
				'請輸入整數',
				'请输入整数'
			]);
	
	static String get patrolInject =>
			index([
				'inject',
				'inject',
				'inject'
			]);
	
	
	static String get patrolPatrol =>
			index([
				'patrol',
				'巡檢次數',
				'巡检次数'
			]);
	
	static String get patrolTemp =>
			index([
				'temperature',
				'溫度',
				'温度'
			]);
	
	static String get patrolVoltage =>
			index([
				'voltage',
				'電壓',
				'电压'
			]);
	
	static String get patrolPressure =>
			index([
				'pressure',
				'壓力',
				'压力'
			]);
	
	static String get patrolMotor =>
			index([
				'motor',
				'motor',
				'motor'
			]);
	
	static String get patrolCommand =>
			index([
				'command',
				'command',
				'command'
			]);
	
	static String get patrolDev1 =>
			index([
				'device_id1',
				'裝置id1',
				'装置id1'
			]);
	
	static String get patrolDev2 =>
			index([
				'device_id2',
				'裝置id2',
				'装置id2'
			]);
	
	static String get patrolDev3 =>
			index([
				'device_id3',
				'裝置id3',
				'装置id3'
			]);
	
	static String get patrolPressureSt =>
			index([
				'pressureStatus',
				'壓力狀態',
				'压力状态'
			]);
	
	static String get patrolTempSt =>
			index([
				'temperatureStatus',
				'溫度狀態',
				'温度状态'
			]);
	
	static String get patrolCapacitySt =>
			index([
				'capacity',
				'油杯狀態',
				'油杯状态'
			]);
	
	static String get patrolBatterySt =>
			index([
				'batteryStatus',
				'電池狀態',
				'电池状态'
			]);
	
	static String get patrolTitleHiddenFields =>
			index([
				'hidden fields',
				'隱藏欄位',
				'隐藏栏位'
			]);
	
	static String get patrolTitleStatus =>
			index([
				'Status',
				'狀態列',
				'状态列'
			]);
	
	static String get patrolCFGNoConfig =>
			index([
				'no config files found, \ncreate a new one',
				'查無設定檔。',
				'查无设定档。'
			]);
	
	static String get patrolCFGNoConfigDesc =>
			index([
				'please tap following button to create a new one',
				'請點擊新增!',
				'请点击新增!'
			]);
	
	static String get patrolCFGLoadBtTitle =>
			index([
				'Load Config',
				'載入設定檔',
				'载入设定档'
			]);
	
	static String get patrolCFGLoadBtDesc =>
			index([
				'select preload\nconfig file',
				''
			]);
	
	static String get patrolCFGCreateBtTitle =>
			index([
				'Create Config',
				'創建設定檔',
				'创建设定档'
			]);
	
	static String get patrolCFGCreateBtDesc =>
			index([
				'from a completely\nnew sheet',
				'由空白檔案\n新增設定檔',
				'由空白档案\n新增设定档'
			]);
	
	static String get patrolCFGCreateBtDescB =>
			index([
				'from a completely\nnew sheet',
				'由log檔新增',
				'由log档新增'
			]);
	
	static String get patrolCFGCreateOrLoadTitle =>
			index([
				'Create config file or open an existing one',
				'載入現存設定檔\n或創建新的設定檔',
				'载入现存设定档\n或创建新的设定档'
			]);
	
	/*
	* 				N F C   new configuration
	*
	* */
	static String get patrolNewCFGFieldIdError =>
			index([
				"Invalid id format, only allowed for digits less than 16777216",
				"ID格式錯誤\n(只允許數字,必須小於16777216)",
				"ID格式错误\n(只允许数字,必须小于16777216)"
			]);
	
	
	static String get patrolNewCFGConfigIdTitle =>
			index([
				"config ntag id",
				"設定Ntag ID",
				"设定Ntag ID"
			]);
	
	static String get patrolNewCFGConfigIdDesc =>
			index([
				"please config ntag id in maximum length of 8 digits",
				"請設定NtagID, 最大8位數.",
				"请设定NtagID, 最大8位数."
			]);
	
	static String get patrolNewCFGTitle =>
			index([
				"Ntag Configuration",
				"Ntag 使用者設定檔",
				"Ntag 使用者设定档"
			]);
	
	static String get patrolNewCFGFieldHint =>
			index([
				"configuration name",
				"請輸入檔名",
				"请输入档名"
			]);
	
	static String get patrolNewCFGFieldIdLabel =>
			index([
				"Device Id Field",
				"裝置ID欄位",
				"装置ID栏位"
			]);
	
	static String get patrolNewCFGFieldIdHint =>
			index([
				"field id in maximun length of 8 digits",
				"最大8位數",
				"最大8位数"
			]);
	
	static String get patrolNewCFGFieldEmptyError =>
			index([
				"empty name is not allowed",
				"不允許空白",
				"不允许空白"
			]);
	
	static String get patrolNewCFGFieldAreadyExistsError =>
			index([
				"file already exists, please confirm to override",
				"檔案己存在, 請確認覆寫",
				"档案己存在, 请确认复写"
			]);
	
	static String get patrolNewCFGFieldSuffix =>
			index([
				"device name prefix",
				"前綴裝置名",
				"前缀装置名"
			]);
	
	static String get patrolNewCFGFieldPrefix =>
			index([
				"prefixed with device code and location code",
				"前綴區碼及裝置碼",
				"前缀区码及装置码"
			]);
	
	static String get patrolNewCFGAutoId =>
			index([
				"generate id by timecode + areacode",
				"自動生成ID (時間碼+地區碼)",
				"自动生成ID (时间码+地区码)"
			]);
	
	static String get takeshotBrowsingAttachedNtag => index([
		'Attached Ntags', "Ntag 附件", "Ntag 附件"
	]);
	
	static String get takeshotBrowsingAttachedNtagSubtitle => index([
		'select ntag to replace', "選取Ntag附件以進行取代", "選取Ntag附件以進行取代"
	]);
	
	static String get takeshotRelatedThumbs => index([
		'Related Images', '影像附件', '影像附件'
	]);
	
	static String get takeshotRelatedThumbsSubtitle => index([
		'Related Images', '', ''
	]);
	
	static String takeshotBrowsingReplace(int i){
		return index([
			"replace($i)", "取代Ntag($i)", "取代Ntag($i)"
		]);
	}
	
	static String takeshotBrowsingThumbAdd(int i){
		return index([
			"add\nimage($i)", "新增\n影像($i)", "新增\n影像($i)"
		]);
	}
	
	static String takeshotBrowsingThumbEdit(int i){
		return index([
			"edit($i)", "編輯($i)", "編輯($i)"
		]);
	}
	static String takeshotBrowsingThumbRemove(int i){
		return index([
			"remove\nimage($i)", "移除影像($i)", "移除影像($i)"
		]);
	}
	
	static String get takeshotDiscardChangesTitle => index([
		'Discard Chagnes?', "是否清除?", "是否清除?"
	]);
	
	static String get takeshotDiscardChangesSubtitle => index([
		'Tap confirm to discard previous changes, cancel to leave',
		'點選確認以進行清除',
		'點選確認以進行清除',
	]);
}

class Msg {
	static void setLang(int v){
		lan = LANGUAGES.values.firstWhere((l) => l.index == v);
	}
	static LANGUAGES lan = LANGUAGES.traditionalChinese;
	
	static AnsiCodecs get codec {
		AnsiCodecs ret = AnsiCodecs.cp1250();
		switch (lan) {
			case LANGUAGES.english:
				ret = AnsiCodecs.cp1250();
				break;
			case LANGUAGES.traditionalChinese:
				ret = AnsiCodecs.cp950();
				break;
			case LANGUAGES.simplifiedChinese:
				ret = AnsiCodecs.cp936();
				break;
		}
		return ret;
	}
	
	static String get onDescAdding => index([
		"adding option, please wait...", "新增中, 請稍候...", "新增中, 请稍候..."
	]);
	static String get onDescAddingSuccess => index([
		"option successfully added!", "己成功新增!"
	]);
	static String onDescAddingFailed([String code]) => index([
		"adding option failed!", "新增失敗(code:$code)!!", "新增失败(code:$code)!!"
	]);
	static String get onDescSaving => index([
		"", "", ""
	]);
	static String get onDescSavingSuccess => index([
		"", "", ""
	]);
	static String get onDescSavingFailed => index([
		"", "", ""
	]);
	
	
	static String validationLengthInRange(int L, int R, int current){
		return index([
			"expect minimum length of $L to maximun length of $R, got ${current}",
			"長度限制, 最大$R字元, 最小$L字元, 目前$current字元",
			"长度限制, 最大$R字元, 最小$L字元, 目前$current字元",
		]);
	}
	
	/*
            m e t h o d s
   */
	static String index(List<String> data) => data[lan.index] ?? data[0];
	
	/*
            c o n s t s
   */
	static String get OK => 'ok';
	
	static String get SUCCESS => 'ok';
	
	static String get FAILED => 'failed';
	
	static String get RETRY => 'retry';
	
	static String get ERROR => 'error';
	
	static String get CONFLICT => 'conflict';
	
	static String onUncaughtError(String msg) =>
			index([
				'uncuahgt error: $msg',
				'未知錯誤: $msg',
				'未知错误: $msg'
			]);
	
	static String get GeneralRedirection =>
			index([
				'redirect..',
				'',
				''
			]);
	
	static String get GeneralSendSuccess =>
			index([
				'success...',
				'',
				''
			]);
	
	static String get GeneralServerError =>
			index([
				'GeneralServerError',
				'',
				''
			]);
	
	static String get GeneralClientError =>
			index([
				'GeneralClientError',
				'',
				''
			]);
	
	static String get NetworkAuthRequired =>
			index([
				'NetworkAuthRequired',
				'',
				''
			]);
	
	static String get ServiceNotAvailable =>
			index([
				'ServiceNotAvailable',
				'無法存取網路服務',
				'无法存取网路服务'
			]);
	
	static String get NotImplemented =>
			index([
				'NotImplemented',
				'',
				''
			]);
	
	static String get InteralServerError =>
			index([
				'InteralServerError',
				'',
				''
			]);
	
	static String get RequestTimeout =>
			index([
				'RequestTimeout',
				'',
				''
			]);
	
	static String get TooManyRequests =>
			index([
				'Send too many requests at the same time',
				'請求過於頻煩!',
				'请求过于频烦!'
			]);
	
	static String get MediaTypeUnsupported =>
			index([
				'Unsupported Media Type',
				'不支援上傳該多媒體資料，請點擊確認將報告回傳給我們。',
				'不支援上传该多媒体资料，请点击确认将报告回传给我们。'
			]);
	
	static String get ConflictConfirmation =>
			index([
				'Upload data is conflict with the one on Server, please confirm which version you want to keep',
				'版本衡突，伺服器資料比客戶端資料新，請選擇欲保留的版本',
				'版本衡突，伺服器资料比客户端资料新，请选择欲保留的版本'
			]);
	
	static String get ResourceNotFound =>
			index([
				'Resources requested not found',
				'向伺服器請求資料時,無資料回傳',
				'向伺服器请求资料时,无资料回传'
			]);
	
	static String get PermissionDenied =>
			index([
				'Permission denied.',
				'該請求因權限不足而無法執行, 請碓認您有足夠的權限',
				'该请求因权限不足而无法执行, 请碓认您有足够的权限'
			]);
	
	static String get UnAuthorized =>
			index([
				'Authorized failed, this may caused by misconfig firewall settings or banned ip',
				'處理權限時發生錯誤, 請碓認您的網路是否在防火牆內',
				'处理权限时发生错误, 请碓认您的网路是否在防火牆内'
			]);
	
	static String get BadRequest =>
			index([
				'client error while sending request to server, please send report to use.',
				'向伺服器請求時發生錯誤，請點擊確認將報告回傳給我們。',
				'向伺服器请求时发生错误，请点击确认将报告回传给我们。'
			]);
	
	static String get onSaving =>
			index([
				'saving files please wait...',
				'儲存中，請稍後...',
				'储存中，请稍后...'
			]);
	
	static String get onDelConfirm =>
			index([
				'submit ok to confirm deletion',
				'確認是否刪除?',
				'确认是否删除?'
			]);
	
	static String get onUpload =>
			index([
				'uploading journal, this will takes a few seconds depends on your network status please wait...',
				'工作日誌上傳中，請稍後...',
				'工作日誌上传中，请稍后...'
			]);
	
	static String onUploadFailed(String code) =>
			index([
				'upload failed:\n$code',
				'上傳時發生錯誤:\n$code',
				'上传时发生错误:\n$code',
			]);
	
	static String get onLoadJournal =>
			index([
				'loading journal, please wait...',
				'日誌讀取中，請稍後...',
				'日誌读取中，请稍后...'
			]);
	
	static String onLoadJournalFailed(String code) =>
			index([
				'load journal failed, please check your network connectivity. An error report will be send underground while you are online.:\n$code',
				'日誌載入錯誤，請確任網路連結訊號是否良好',
				'日誌载入错误，请确任网路连结讯号是否良好',
			]);
	
	static String get onLoadImage =>
			index([
				'loading image, please wait...',
				'圖片讀取中，請稍後...',
				'图片读取中，请稍后...'
			]);
	
	static String onLoadImageFailed(String code) =>
			index([
				'load image failed:\n$code',
				'圖片載入發生錯誤',
				'图片载入发生错误'
			]);
	
	static String get onSavingNotFound =>
			index(const [
				'file not found',
				'找不到欲儲存的檔案',
				'找不到欲储存的档案'
			]);
	
	static String get onSavingFailed =>
			index(const [
				'saving files to disk failed!',
				'儲存檔案時發生錯誤!',
				'储存档案时发生错误!'
			]);
	
	static String get onSaveSuccess =>
			index([
				'file saved',
				'儲存成功!',
				'储存成功!'
			]);
	
	static String get onCreatingJournal {
		return index([
			'creating journal, please wait...',
			'建立檔案中,請稍後...',
			'建立档案中,请稍后...'
		]);
	}
	
	static String get onDel =>
			index([
				'on deling file...',
				'刪除檔案中',
				'删除档案中'
			]);
	
	static String get onDelNotFound =>
			index([
				'file not found',
				'找不到欲刪除的檔案',
				'找不到欲删除的档案'
			]);
	
	static String get onDelSucceed =>
			index([
				'successfully deleted',
				'檔案刪除成功',
				'档案删除成功'
			]);
	
	static String get onDelFailed =>
			index([
				'deling failed',
				'檔案刪除失敗',
				'档案删除失败'
			]);
	
	
	static String onFileNotFound() {
		return index([
			'file not found',
			'檔案路徑解析錯誤',
			'档案路径解析错误'
		]);
	}
	
	static String onFileParsingFailed() {
		return index([
			'file parsing failed!',
			'檔案解析發生錯誤',
			'档案解析发生错误'
		]);
	}
	
	static String onFileLoading() {
		return index([
			'file loading...',
			'檔案載入中...',
			'档案载入中...'
		]);
	}
	
	static String onFileLoadingSuccess() =>
			index([
				'file loaded!',
				'檔案已載入',
				'档案已载入'
			]);
	
	static String onFileLoadingFailed() =>
			index([
				'failed to load file',
				'載入失敗...',
				'载入失败...'
			]);
	
	static String get onFileUploading =>
			index([
				'uploading... this will takes a few seconds depends on your network status...',
				'上傳中，請稍後...',
				'上传中，请稍后...'
			]);
	
	static String onFileUploadingFailed(String code) =>
			index([
				'upload failed:\n$code',
				'上傳時發生錯誤:\n$code',
				'上传时发生错误:\n$code',
			]);
	
	static String get onFileUploadingSuccess =>
			index([
				'Upload success',
				'上傳成功!',
				'上传成功!'
			]);
	
	static String get onInquiryNonUndoableRequest =>
			index([
				'this operation cannot be undoable, click ok to continue!',
				'this operation cannot be undoable, click ok to continue!',
				'this operation cannot be undoable, click ok to continue!',
			]);
	
	static String get onInquiryUploadingRequest =>
			index([
				'submit ok to confirm uploading. note: once uploaded this operaton cannot be undoable.',
				'submit ok to confirm uploading. note: once uploaded this operaton cannot be undoable.',
				'submit ok to confirm uploading. note: once uploaded this operaton cannot be undoable.'
			]);
	
	
	static String get onUploadValidationError =>
			index([
				'data validation error while uploading',
				'資料驗證錯誤',
				'资料验证错误',
			]);
	
	static String get onSyncConflict =>
			index([
				'sync error',
				'資料同步錯誤',
				'资料同步错误',
			]);
	
	static String get onUploadFormValidationError =>
			index([
				'data validation error while uploading, please refine it according to suggestions',
				'發現資料格式錯誤，請依據提式更正錯誤',
				'发现资料格式错误，请依据提式更正错误',
			]);
	
	static String get registerFailed =>
			index([
				'register failed',
				'送交註冊時發生錯誤，請稍後再試',
				'送交注册时发生错误，请稍后再试'
			]);
	
	static String get editProfileFailed =>
			index([
				'edit profile failed',
				'送交變更資料時發生錯誤，請稍後再試',
				'送交变更资料时发生错误，请稍后再试'
			]);
	
	static String onAuthRetry(int retries, int max) =>
			index([
				'authenticate retires: $retries/$max',
				'帳戶授權重試 $retries/$max',
				'帐户授权重试 $retries/$max'
			]);
	
	static String get SendingAuth =>
			index([
				'sending authentication, please wait',
				'取得帳戶授權中...',
				'取得帐户授权中...'
			]);
	
	static String get SendingAuthSuccess =>
			index([
				'send authentication success',
				'傳送授權成功!',
				'传送授权成功!'
			]);
	
	
	static String get RefreshingAuth =>
			index([
				'sending authentication, please wait',
				'取得帳戶授權中...',
				'取得帐户授权中...'
			]);
	
	static String authorizeFailed(String code) =>
			index([
				'authorization failed: $code',
				'無法取得授權:$code',
				'无法取得授权:$code'
			]);
	
	static String get onOfflineMode =>
			index([
				'entering offline mode',
				'切換至離線模式',
				'切换至离线模式'
			]);
	
	static String get onOnlineMode =>
			index([
				'entering online mode',
				'切換至連線模式',
				'切换至连线模式'
			]);
	
	static String get onNetworkUnavailable =>
			index([
				'Network Unavailable',
				'無網路連線'
			]);
	
	static String get onNetworkAvailable =>
			index([
				'Network available',
				'已取得網路連線',
				'已取得网路连线'
			]);
	
	static String get NotRegisteredYet =>
			index([
				'not a registered user, please registered first',
				'用戶尚未註冊，請先行註冊',
				'用户尚未注册，请先行注册'
			]);
	
	static String get LoginFirst =>
			index([
				'please login first, or switch to offline mode',
				'請先登入，若無網路可切換至離線模式',
				'请先登入，若无网路可切换至离线模式'
			]);
	
	static String get onServerError =>
			index([
				'no response from server',
				'伺服器無回應',
				'伺服器无回应'
			]);
	
	/*
   *
   *           V A L I D A T O R S
   *
   *
   * */
	
	
	
	static String onUniqueValidatioError(String fieldname, dynamic value) {
		return index([
			"field ${fieldname}:${value}\nalready exists, pick another one",
			"欄位名 ${fieldname}:${value}\n已存在，請選用其他名稱",
			"栏位名 ${fieldname}:${value}\n已存在，请选用其他名称"
		]);
	}
	
	static String onEmailValidationError(String fieldname, dynamic value) {
		return index([
			"field ${fieldname}:${value}\nis not a valid email format",
			"欄位名 ${fieldname}:${value}\n非email正碓格式",
			"栏位名 ${fieldname}:${value}\n非email正碓格式"
		]);
	}
	
	static String fieldPermissionDenied(String fieldname) {
		return index([
			"permission denied for field:$fieldname",
			"權限不足,無法編輯「$fieldname」}",
			"权限不足,无法编辑「$fieldname」}"
		]);
	}
	
	static String permissionDenied(String eventName) {
		return index([
			"permission denied:$eventName\n${UserState.currentUser?.permission}",
			"權限不足:$eventName\n${UserState.currentUser?.permission}",
			"权限不足:$eventName\n${UserState.currentUser?.permission}"
		]);
	}
	
	static String permissionLogin(String eventName) {
		return index([
			"Please login first:\n${UserState.currentUser?.permission}",
			"權限不足，請先登入:\n${UserState.currentUser?.permission}"				,
			"权限不足，请先登入:\n${UserState.currentUser?.permission}"
		]);
	}
	
	static String onBugReport(StackTrace stacktrace) {
		return index([
			"Oops, an embarrassing bug found. For better user experience, please confirm ok to send report to us",
			"喔喔! 發生未知錯誤，請將報告傳送給我們以提供更佳的服務!",
			"喔喔! 发生未知错误，请将报告传送给我们以提供更佳的服务!",
		]);
	}
	
	static String onUrlCannotLaunch(String link) {
		return index([
			"cannot launch url\n$link",
			"連結無法存取\n$link",
			"连结无法存取\n$link"
		]);
	}
	
	static String onMessage(String msg) {
		return index([
			msg,
			msg,
			msg
		]);
	}
	
	
	static String get onNFCommunicationSuccess =>
			index([
				'successfully communicated, log written!!',
				'讀取通訊成功, 己寫入log',
				'读取通讯成功, 己写入log'
			]);
	
	static String get onReadingNtagSuccess =>
			index([
				'successfully read!',
				'讀取成功!!',
				'读取成功!!'
			]);
	
	static String get onReadingNtagFailed =>
			index([
				'reading ntag failed!!',
				'讀取內容失敗!!',
				'读取内容失败!!'
			]);
	
	static String get onReadingNtag =>
			index([
				'content reading...',
				'讀取內容中...',
				'读取内容中...'
			]);
	
	
	static String onReadNtagCommandError() {
		return index([
			'nfc io error while reading command field, please realign your device and try again',
			'讀取命令欄位時發生錯誤! 請對正裝置後再試',
			'读取命令栏位时发生错误! 请对正装置后再试'
		]);
	}
	
	
	static String get onWritingNtag =>
			index([
				'writing ntag...',
				'正在寫入中...',
				'正在写入中...'
			]);
	
	static String get onNtagSuccessfullyWritten =>
			index([
				'successfully written!!',
				'成功寫入!!',
				'成功写入!!'
			]);
	
	static String get onWriteNtagError {
		return index([
			'nfc io error while writing ntag, please realign your device and try again',
			'寫入Ntag時發生錯誤! 請對正裝置後再試',
			'写入Ntag时发生错误! 请对正装置后再试'
		]);
	}
	
	static String onWriteNtagCommandError([Object err]) {
		return index([
			'nfc io error while writing command field, please realign your device and try again',
			'寫入命令欄位時發生錯誤! 請對正裝置後再試',
			'写入命令栏位时发生错误! 请对正装置后再试'
		]);
	}
	
	static String onWriteNtagCommandSuccess() {
		return index([
			'command code written!',
			'己寫入通訊碼',
			'己写入通讯码'
		]);
	}
	
	static String onNFCommunicationError() {
		return index([
			'NFC communication error',
			'NFC 通訊異常',
			'NFC 通讯异常'
		]);
	}
	
	static String onMalformedNtagContent() {
		return index([
			'Unexpected ntag content, please realign your device and try again',
			'非預期的Ntag內容! 請對正裝置後再試'
		]);
	}
	
	static String onReadNtagError() {
		return index([
			'read failed, please realign your device and try again',
			'讀取Ntag內容時發生錯誤! 請對正裝置後再試',
			'讀取Ntag內容時發生錯誤! 請對正裝置後再試'
		]);
	}
	
	static String onReadNtagInternalError() {
		return index([
			'internal error while reading ntag',
			'讀取Ntag時發生內部錯誤!!',
			'读取Ntag时发生内部错误!!'
		]);
	}
	
	static String retry(int idx, int max) {
		if (idx == 0)
			return index(['', '']);
		return index([
			'retry ($idx/$max)',
			'重試 ($idx/$max)',
			'重试 ($idx/$max)'
		]);
	}
	
	static String elapse(String time) {
		return index([
			'elapse: $time',
			'時間經過 $time',
			'时间经过 $time'
		]);
	}
	
	
	
	/*
	* 		D E F E C T S
	*
	* */
	static String get delDefectsForbid => index([
		"Option cannot be deleted use merge instread (option aready referenced in another work journal).",
		"無法刪除, 請使用合併功能 (該選項在其他工作日誌己使用)",
		"无法删除, 请使用合併功能 (该选项在其他工作日誌己使用)"
	]);
	
	static String get  delDefectsOnCloud => index([
		"del option on clound, please wait...", "刪除雲端資料中, 請稍後...", "删除云端资料中, 请稍后..."
	]);
	
	static String get mergeOptionSending => index([
		"sending merge request", "請求合併中...", "请求合併中..."
	]);
	
	static String get mergeOptionSuccess => index([
		"successfully mereged", "合併成功", "合併成功"
	]);
	
	static String get mergeOptionFailed => index([
		"merge failed", "合併失敗", "合併失败"
	]);
	
	static String delDefectsFailed ([String code]) => index([
		"failed to delete ${code}", "刪除時發生錯誤 ${code}", "删除时发生错误 ${code}"
	]);
	
	static String get  delDefectsSuccess => index([
		"option successfully deleted", "成功刪除!", "成功删除!"
	]);
	
	static String get offlineDefectsOperation => index([
		"any operation in offline mode is not allowed", "離線模式下, 不允許刪除", "离线模式下, 不允许删除"
	]);
	
	static String get mergeOptionsOperationError => index([
		"", "", ""
	]);
	
	
}


