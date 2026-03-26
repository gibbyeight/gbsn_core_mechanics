extends Node
## Game-side bridge between EventBusService and the editor's
## EventBus debugger panel
##
## Added as a child of EventBusService at runtime (debug builds only)
## Listens to EventBusService.debug_* signals and forwards data to
## the editor via EngineDebugger. Also handles incoming messages
## from the editor (sync requests, celar history)

var _event_bus: EventBusService

func _ready() -> void:
	_event_bus = get_parent() as EventBusService
	if not _event_bus:
		Log.warning("[EventBusDebuggerBridge] Parent is not EventBusService - removing")
		queue_free()
		return
	_event_bus.debug_subscription_added.connect(_on_subscription_added)
	_event_bus.debug_subscription_removed.connect(_on_subscription_removed)
	_event_bus.debug_event_broadcast.connect(_on_event_broadcast)
	
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture(
			"event_bus", _on_editor_message
		)

#region EventBusService signal handlers -> EngineDebugger messages
func _on_subscription_added(
	event_id: String,
	subscriber_name: String,
	subsriber_class: String,
	method: String,
	connected_at: int
) -> void:
	_send("event_bus:subscription_added", [
		event_id, subscriber_name, subsriber_class, method, connected_at
	])


func _on_subscription_removed(
	event_id: String,
	subsriber_name: String,
	method: String
) -> void:
	_send("event_bus:subscription_removed", [
		event_id, subsriber_name, method
	])


func _on_event_broadcast(
	event_id: String,
	source: String,
	timestamp: int,
	subscriber_count: int
) -> void:
	_send("event_bus:broadcast", [
		event_id, source, timestamp, subscriber_count
	])
#endregion

#region Editor -> Game messages
func _on_editor_message(message: String, _data: Array) -> bool:
	match message:
		"event_bus:request_sync":
			_send_full_sync()
			return true
		"event_bus:clear_history":
			_event_bus.clear_debug_history()
			return true
	return false


func _send_full_sync() -> void:
	var serialized: Dictionary = {}
	for event_id: String in _event_bus.debug_subscriptions.keys():
		serialized[event_id] = []
		for sub: Dictionary in _event_bus.debug_subscriptions[event_id]:
			serialized[event_id].append({
				"subscriber_name": sub.get("subscriber_name", "key not found"),
				"subsriber_class": sub.get("subscriber_class", "key not found"),
				"method": sub.get("method", "key not found"),
				"connected_at": sub.get("connected_at", "key not found")
			})
	_send("event_bus:sync", [serialized])


func _send(message: String, data: Array) -> void:
	if EngineDebugger.is_active():
		EngineDebugger.send_message(message, data)
#endregion
