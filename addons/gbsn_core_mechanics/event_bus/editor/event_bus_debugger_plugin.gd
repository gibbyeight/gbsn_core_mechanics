@tool
extends EditorDebuggerPlugin
## Bridges the running game's EventBusService with the editor-side
## debugger panel via the EngineDebugger message protocol
##
## Message protocol (game -> editor):
##   event_bus:subscription_added    [event_id, name, class, method, connected_at]
##   event_bus:subscription_removed  [event_id, name, method]
##   event_bus:broadcast             [event_id, source, timestamp, subscriber_count]
##   event_bus:sync                  [subscriptions_dict]
##
## Message protocol (editor -> game)
##   event_bus:request_sync          []
##   event_bus:clear_history         []

const DebuggerPanel = preload("event_bus_debugger_panel.gd")

var _panels: Dictionary = {}


func _ready() -> void:
	print("boom")


func _has_capture(prefix: String) -> bool:
	return prefix == "event_bus"


func _capture(message: String, data: Array, session_id: int) -> bool:
	var panel: Control = _panels.get(session_id)
	if not panel:
		return false
	match message:
		"event_bus:subscription_added":
			panel.add_subscription(
				data[0], # event_id
				data[1], # subscriber_name
				data[2], # subscriber_class
				data[3], # method
				data[4], # connected_at
			)
			return true
		"event_bus:subscription_removed":
			panel.remove_subscription(
				data[0], # event_id
				data[1], # subscriber_name
				data[2], # method
			)
			return true
		"event_bus:broadcast":
			panel.log_broadcast(
				data[0], # event_id
				data[1], # source
				data[2], # timestamp
				data[3], # subscriber_count
			)
			return true
		"event_bus:sync":
			panel.sync_full_state(data[0])
			return true
	return false


func _setup_session(session_id: int) -> void:
	var panel: DebuggerPanel = DebuggerPanel.new()
	_panels[session_id] = panel
	
	var session: EditorDebuggerSession = get_session(session_id)
	session.started.connect(_on_session_started.bind(session_id))
	session.stopped.connect(_on_session_stopped.bind(session_id))
	session.add_session_tab(panel)


func _on_session_started(session_id: int) -> void:
	var panel: Control = _panels.get(session_id)
	if panel:
		panel.clear_all()
	
	var session: EditorDebuggerSession = get_session(session_id)
	if session:
		session.send_message("event_bus:request_sync", [])


func _on_session_stopped(_session_id: int) -> void:
	pass
