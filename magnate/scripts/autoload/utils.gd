class_name Utils
extends RefCounted

static func debug(msg: String) -> void:
	if Globals.BUILD_TYPE == Globals.BuildType.DEV:
		var time: Dictionary = Time.get_time_dict_from_system()
		print("%02d:%02d:%02d - LOG: " % [time.hour, time.minute, time.second] + msg)


static func to_currency_text(value: int) -> String:
	var s = str(abs(value))
	var result = ""
	var count = 0
	
	for i in range(s.length() - 1, -1, -1):
		if count != 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	if value < 0: result = "-" + result
	return result + Globals.SYMBOL_CURRENCY
