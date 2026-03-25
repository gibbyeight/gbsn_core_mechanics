# GdUnit generated TestSuite
class_name LoggerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://addons/gbsn_core_mechanics/logger/logger.gd'
const test_message: String = "testing testing"
const test_log_folder_path: String = "res://gbsn_core_mechanics/test/logs"


func test_debug() -> void:
	assert_str(Log.debug(test_message)).contains("[DEBUG] %s" % test_message)


func test_info() -> void:
	assert_str(Log.info(test_message)).contains("[INFO] %s" % test_message)


func test_warning() -> void:
	assert_str(Log.warning(test_message)).contains("[WARNING] %s" % test_message)


func test_error() -> void:
	assert_str(Log.error(test_message)).contains("[ERROR] %s" % test_message)


func test_logs_folder() -> void:
	Log.set_logs_folder(test_log_folder_path)
	assert_str(Log.logs_folder).is_equal(test_log_folder_path)


func test_logging_level_default() -> void:
	assert_int(Log.logging_level).is_equal(0)


func test_logging_level_set_to_debug() -> void:
	Log.set_logging_level(Log.EMessageSeverity.DEBUG)
	assert_int(Log.logging_level).is_equal(0)


func test_logging_level_set_to_info() -> void:
	Log.set_logging_level(Log.EMessageSeverity.INFO)
	assert_int(Log.logging_level).is_equal(1)


func test_logging_level_set_to_warning() -> void:
	Log.set_logging_level(Log.EMessageSeverity.WARNING)
	assert_int(Log.logging_level).is_equal(2)


func test_logging_level_set_to_error() -> void:
	Log.set_logging_level(Log.EMessageSeverity.ERROR)
	assert_int(Log.logging_level).is_equal(3)
