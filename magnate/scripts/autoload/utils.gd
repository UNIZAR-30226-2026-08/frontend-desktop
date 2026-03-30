class_name Utils
extends RefCounted

static func debug(msg: String) -> void:
	if Globals.BUILD_TYPE == Globals.BuildType.DEV:
		var time: Dictionary = Time.get_time_dict_from_system()
		print("%d:%d:%d - LOG: " % [time.hour, time.minute, time.second] + msg)


static func to_currency_text(value: int) -> String:
	return str(value) + Globals.SYMBOL_CURRENCY
