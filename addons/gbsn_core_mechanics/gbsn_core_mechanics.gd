@tool
extends EditorPlugin

const LOG = "Log"
const EVENT_BUS = "EventBus"

var _debugger_plugin: EditorDebuggerPlugin

func _enable_plugin() -> void:
	var base_dir: String = get_script().resource_path.get_base_dir()
	var setting_dir: String = "gbsn_logger/settings"
	add_autoload_singleton(LOG, base_dir + "/logger/logger.gd")
	add_autoload_singleton(EVENT_BUS, base_dir + "/event_bus/event_bus_service.gd")
	ProjectSettings.set_setting(setting_dir + "/state_logs", true)
	ProjectSettings.set_setting(setting_dir + "/event_logs", true)


func _disable_plugin() -> void:
	remove_autoload_singleton(LOG)
	remove_autoload_singleton(EVENT_BUS)


func _enter_tree() -> void:
	var base_dir: String = get_script().resource_path.get_base_dir()
	var path: String = base_dir + "/event_bus/editor/event_bus_debugger_plugin.gd"
	if not ResourceLoader.exists(path):
		push_warning("[GBSN] Debugger plugin not found at: %s" % path)
		return
	var debugger_script: GDScript = load(path)
	print("PATH: %s" % debugger_script.resource_name)
	if not debugger_script:
		push_warning("[GBSN] Failed to load debugger plugin script")
		return
	_debugger_plugin = debugger_script.new()
	add_debugger_plugin(_debugger_plugin)


func _exit_tree() -> void:
	if _debugger_plugin:
		remove_debugger_plugin(_debugger_plugin)
		_debugger_plugin = null
