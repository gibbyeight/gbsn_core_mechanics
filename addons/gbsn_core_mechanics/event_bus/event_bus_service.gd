class_name EventBusService
extends Node
## Autoload: EventBus
## The service that is responsible for tracking subscriptions
## to events and broadcasting them out.
## Follows a basic publisher/subscriber pattern

## Emits debug_* signals at key lifecycle points so external
## observers (e.g the debugger bridge) can react without
## coupling this class to any editor debugger API.

# HACK: ** EVENTBUS DEBUGGER PLUGIN **
const MAX_RECENT_EMITS: int = 100

signal debug_subscription_added(
	event_id: String,
	subscriber_name: String,
	subscriber_class: String,
	method: String,
	connected_at: int
)

signal debug_subscription_removed(
	event_id: String,
	subscriber_name: String,
	method: String
)

signal debug_event_broadcast(
	event_id: String,
	source: String,
	timestamp: int,
	subscriber_count: int
)
var debug_subscriptions: Dictionary = {}:
	get:
		return debug_subscriptions

var recent_emits: Array = []

## Dictionary of event_id to dynamic signal
@onready var signal_registry: Dictionary = {}


func _ready() -> void:
	_try_attach_debugger_bridge()

#region EventBus core functions
func _ensure_signal(event_id: String) -> void:
	if not signal_registry.has(event_id):
		# Define a new dynamic signal
		add_user_signal(event_id, ["event"])
		signal_registry[event_id] = true
		if ProjectSettings.get_setting("gbsn_logger/settings/event_logs") == true:
			Log.debug("[EventBus] Created dynamic signal: %s" % event_id)


## Subscribe: uses Godot signal system internally
func subscribe(event_id: String, subscriber: Object, method_name: String) -> void:
	_ensure_signal(event_id)

	if not is_instance_valid(subscriber):
		Log.warning("[EventBus] Invalid subscriber for event: %s" % event_id)
		return

	if not subscriber.has_method(method_name):
		Log.error("Subscriber doesn't have method: %s" % method_name)
		return

	var callable = Callable(subscriber, method_name)

	# Connect using built-in signal system
	if is_connected(event_id, callable):
		return

	connect(event_id, callable)
	if ProjectSettings.get_setting("gbsn_logger/settings/event_logs") == true:
		Log.debug("[EventBus] Connected '%s' -> %s.%s()" % [
				event_id, subscriber.get_class(), method_name
			])

	var subscriber_name: String = str(subscriber)
	var subscriber_class: String = subscriber.get_class()
	var connected_at: int = Time.get_ticks_msec()
	
	if not debug_subscriptions.has(event_id):
		debug_subscriptions[event_id] = []
	debug_subscriptions[event_id].append({
		"callable": callable,
		"subscriber_name": str(subscriber),
		"subscriber_class": subscriber_class,
		"method": method_name,
		"connected_at": connected_at
	})
	
	debug_subscription_added.emit(
		event_id, subscriber_name, subscriber_class, method_name, connected_at
	)


func unsubscribe(event_id: String, subscriber: Object, method_name: String) -> void:
	if not signal_registry.has(event_id):
		return
	var callable = Callable(subscriber, method_name)
	if not is_connected(event_id, callable):
		return
	disconnect(event_id, callable)
	if ProjectSettings.get_setting("gbsn_logger/settings/event_logs") == true:
		Log.debug("[EventBus] Disconnected '%s' -> %s.%s()" % [
			event_id, subscriber.get_class(), method_name
		])
	var subscriber_name: String = str(subscriber)
	if debug_subscriptions.has(event_id):
		debug_subscriptions[event_id] = debug_subscriptions[event_id].filter(
			func(sub: Dictionary) -> bool: return sub.callable != callable
		)
	debug_subscription_removed.emit(event_id, subscriber_name, method_name)


## Broadcast: emits signal with event object
func broadcast(event: Event) -> void:
	var event_id = event.event_id
	if not signal_registry.has(event_id):
		Log.warning("[EventBus] No subscribers for event: %s" % event_id)
		return # No one subscribed
	
	if ProjectSettings.get_setting("gbsn_logger/settings/event_logs") == true:
		Log.debug("[EventBus] Emitting '%s' with event: %s" % [event_id, event])
	emit_signal(event_id, event)
	
	var sub_count: int = debug_subscriptions.get(event_id, []).size()
	var timestamp: int = Time.get_ticks_msec()
	
	recent_emits.append({
		"event_id": event_id,
		"time": timestamp,
		"event": event,
		"subscriber_count": sub_count
	})

	# Keep recetn emits list manageable
	if recent_emits.size() > MAX_RECENT_EMITS:
		recent_emits = recent_emits.slice(-MAX_RECENT_EMITS)
	
	debug_event_broadcast.emit(event_id, event.source, timestamp, sub_count)


# func emit_state_changed(
# 	old_state: String,
# 	new_state: String,
# 	source: String = "StateMachine"
# 	) -> void:
# 		_emit_event(EventIdRepository.STATE_MANAGEMENT.STATE_CHANGED, source)


## Convenience method - create and broadcast in one call
func _emit_event(event_id: String, source: String = "") -> void:
	var event = Event.new(event_id, source)
	broadcast(event)
#endregion

#region Debug helpers
func get_subscriber_count(event_id: String) -> int:
	return debug_subscriptions.get(event_id, []).size()


func get_all_event_stats() -> Dictionary:
	var stats = {}
	for event_id in debug_subscriptions.keys():
		stats[event_id] = {
			"subscriber_count": debug_subscriptions[event_id].size(),
			"recent_emits": recent_emits.filter(func(emit): return emit.event_id == event_id).size()
		}
	return stats


func clear_debug_history() -> void:
	recent_emits.clear()

## Dynamically loads the debugger bridge as a child node when running
## in a debug build. If the bridge script doesn't exist on disk
## (e.g editor tools were stripped for a release), this is a no-op
func _try_attach_debugger_bridge() -> void:
	if not OS.has_feature("debug"):
		return
	var base: String = get_script().resource_path.get_base_dir()
	var bridge_path: String = base + "/editor/event_bus_debugger_bridge.gd"
	if not ResourceLoader.exists(bridge_path):
		return
	var bridge_script: GDScript = load(bridge_path)
	if not bridge_script:
		return
	var bridge: Node = bridge_script.new()
	if not bridge:
		push_warning("[EventBus] Failed to instantiate debugger bridge")
		return
	add_child(bridge)
#endregion
