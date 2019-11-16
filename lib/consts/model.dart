enum DESC_OPT {
   id,
   name,
   description,
   certificated,
   imageJournals
}

enum DESC_MAPPING {
   id,
   journal_description,
   description_options
}

enum IMG_REC {
   id,
   ident,
   path,
   description
}

enum IMG_DOC {
   title,
   summary,
   conclusion,
   recs
}

enum IMG_JOURNAL {
   id,
   content,
   image_records,
   journal_description
}

enum JOURNAL_DESC {
   id,
   journal,
   created_date,
   modified_date,
   description_options,
   image_journal
}

enum JOURNAL {
   id,
   device,
   journal_coauthers,
   descriptions
}

enum DEVICE {
   id,
   name,
   journal,
   maintenance,
   device_responsers
}
enum MAINTAIN {
   id,
   device,
   setup,
   tempRange,
   voltageRange,
   pressureRange,
   injectionRange
}

enum NFC_TAG {
   type,
   modified_date,
   created_date,
   setup,
   device_id,
   temperature,
   voltage,
   pressure,
   inject,
   patrols,
   batteryStatus,
   temperatureStatus,
   pressureStatus,
   capacityStatus,
   rest
}

enum USER {
   id,
   password,
   last_login,
   login_name,
   display_name,
   permission,
   working_info,
   device_responsers,
   journal_coauthers
}

enum UJ_MAPPING {
   id,
   journal,
   user
}

enum UD_MAPPING {
   id,
   device,
   user
}