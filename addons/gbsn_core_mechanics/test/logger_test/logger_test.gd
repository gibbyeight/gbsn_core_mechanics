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


func test_logging_level() -> void:
	assert_str(Log.logging_level).is_empty("")
