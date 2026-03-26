@tool
extends Node
## Autoload: Log

## Enumeration of message severity
enum EMessageSeverity {DEBUG, INFO, WARNING, ERROR}

## Default log file name prefix
const LOG_FILE_NAME_PREFIX: String = "Log"

## Message severity names
var m_message_severity_name: Array[String] = ["DEBUG", "INFO", "WARNING", "ERROR"]

## Log file object to output messages
var m_log_file: FileAccess = null

## Minimal logging level
var logging_level: EMessageSeverity = EMessageSeverity.INFO

## Base folder of log files
var logs_folder: String = ""

func _ready():
	# Load severity from project settings, fallback to Info if undefined
	var severity_value = \
		ProjectSettings.get_setting(
			"logging/severity",
			EMessageSeverity.DEBUG
		)
	# Clamp value to valid range
	severity_value = clamp(severity_value, 0, m_message_severity_name.size() - 1)
	set_logging_level(severity_value)


## Description: Returns the current time as a formatted string for the log
## Return: Current time as a formatted string for the log
func _get_time_for_log() -> String:
	var current_time = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d:" % [current_time.hour, current_time.minute, current_time.second]

## Descrition: Returns the current time as a formatted string for the log file name
## Return: Current time as a formatted string for the log file name
func _get_time_for_log_file_name() -> String:
	var current_time = Time.get_time_dict_from_system()
	return "%02d_%02d_%02d" % [current_time.hour, current_time.minute, current_time.second]

## Description: Returns the current date as a formatted string for the log
## Return: Current date as a formatted string for the log
func _get_date_for_log() -> String:
	var current_date = Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [current_date.day, current_date.month, current_date.year]

## Description: Returns the current date as a formatted string for the log file name
## Return: Current date as a formatted string for the log file name
func _get_date_for_log_file_name() -> String:
	var current_date = Time.get_date_dict_from_system()
	return "%02d_%02d_%04d" % [current_date.day, current_date.month, current_date.year]

## Description: Sets the base folder for all logs
## Parameter folder: The base folder to put all logs in
func set_logs_folder(folder: String) -> void:
	logs_folder = folder

## Description: Creates a log file in the assigned folder
## Parameter filename: Name of the log file (including extension)
func create_log_file(filename: String = "") -> int:
	# Create the requested folder if it doesn't exist
	if not DirAccess.dir_exists_absolute(logs_folder):
		DirAccess.make_dir_absolute(logs_folder)

	# Open the target log file
	var log_file_full_path = logs_folder + "/" + (_get_log_file_name() if filename == "" else filename)
	m_log_file = FileAccess.open(log_file_full_path, FileAccess.WRITE)

	# Returns ok if the file was opened successfully, otherwise returns the error
	return FileAccess.get_open_error()

## Description: Returns the default name of the log file
## Return: The default name of the log file
func _get_log_file_name() -> String:
	return "%s_%s_%s.log" % \
		[
			LOG_FILE_NAME_PREFIX,
			_get_date_for_log_file_name(),
			_get_time_for_log_file_name()
		]

## Description: Logs a message with the severity of Debug
## Parameter message: The message string to output
func debug(message: Variant) -> Variant:
	return _log_message(message, EMessageSeverity.DEBUG)

## Description: Logs a message with the severity of Info
## Parameter message: The message string to output
func info(message: Variant) -> Variant:
	return _log_message(message, EMessageSeverity.INFO)

## Description: Logs a message with the severity of Warning
## Parameter message: The message string to output
func warning(message: Variant) -> Variant:
	return _log_message(message, EMessageSeverity.WARNING)

## Description: Logs a message with the severity of Error
## Parameter message: The message string to output
func error(message: Variant) -> Variant:
	return _log_message(message, EMessageSeverity.ERROR)

## Description: Sets the current logging level
## Parameter level: Required logging level
func set_logging_level(level: EMessageSeverity) -> void:
	logging_level = level

## Description: Internal logging function for all message severities
## Parameter message: The message string to output
## Parameter severity: The severity of the message to output
func _log_message(message: Variant, severity: EMessageSeverity) -> Variant:
	var formatted_message: String
	if (logging_level <= severity):
		var stack = get_stack()
		var caller = stack.back() if stack.size() > 1 else null
		var location = ""
		if caller:
			location = "%s:%d" % [caller.source, caller.line]
		else:
			location = "Called from editor (tool mode)"

		formatted_message = "%s %s [%s] %s \n - At: [%s] \n" % \
			[
				_get_date_for_log(),
				_get_time_for_log(),
				_get_severity_name(severity),
				message,
				location
			]

		# Write the message to the Godot output window
		_log_message_output(formatted_message, severity)

		if (m_log_file):
			# Write the message to the log file
			_log_message_file(formatted_message)
		
	return formatted_message

## Description: Internal logging function to standard output
## Parameter message: The message string output
func _log_message_output(message: String, severity) -> void:
	if severity == EMessageSeverity.ERROR:
		push_error(message)
	elif severity == EMessageSeverity.WARNING:
		push_warning(message)
	else:
		print(message)

## Description: Internal logging function to a file
## Parameter message: The message string to output
func _log_message_file(message: String) -> void:
	m_log_file.store_string(message + "\n")
	m_log_file.flush()

## Description: Returns the name of the message severity as a string
## Parameter message_severity: Severity enum of the message
func _get_severity_name(message_severity: EMessageSeverity) -> String:
	return m_message_severity_name[message_severity]
