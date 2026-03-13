@tool
extends EditorPlugin

const LOG = "Log"
const EVENT_BUS = "EventBus"

func _enable_plugin() -> void:
	add_autoload_singleton(LOG, "res://addons/gbsn_core_mechanics/logger/logger.gd")
	add_autoload_singleton(EVENT_BUS, "res://addons/gbsn_core_mechanics/event_bus/event_bus_service.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton(LOG)
	remove_autoload_singleton(EVENT_BUS)


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
