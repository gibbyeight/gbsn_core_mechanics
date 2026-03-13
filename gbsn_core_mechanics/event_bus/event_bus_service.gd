class_name EventBusService
extends Node
## Autoload: EventBus
## The service that is responsible for tracking subscriptions
## to events and broadcasting them out.
## Follows a basic publisher/subscriber pattern

# HACK: ** EVENTBUS DEBUGGER PLUGIN **
const MAX_RECENT_EMITS: int = 100

var debug_subscriptions: Dictionary = {}:
	get:
		return debug_subscriptions

var recent_emits: Array = []

## Dictionary of event_id to dynamic signal
@onready var signal_registry: Dictionary = {}

func _ensure_signal(event_id: String) -> void:
	if not signal_registry.has(event_id):
		# Define a new dynamic signal
		add_user_signal(event_id, ["event"])
		signal_registry[event_id] = true
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
	var signal_aready_connected = is_connected(event_id, callable)

	if not signal_aready_connected:
		connect(event_id, callable)
		Log.debug("[EventBus] Connected '%s' -> %s.%s()" % [
				event_id, subscriber.get_class(), method_name
			])

		# HACK: ** EVENTBUS DEBUGGER PLUGIN **
		if not debug_subscriptions.has(event_id):
			debug_subscriptions[event_id] = []
			debug_subscriptions[event_id].append({
				"callable": callable,
				"subscriber_name": str(subscriber),
				"method": method_name,
				"connected_at": Time.get_ticks_msec()
			})


func unsubscribe(event_id: String, subscriber: Object, method_name: String) -> void:
	if not signal_registry.has(event_id):
		return

	var callable = Callable(subscriber, method_name)
	if is_connected(event_id, callable):
		disconnect(event_id, callable)
		Log.debug("[EventBus] Disconnected '%s' -> %s.%s()" % [
			event_id, subscriber.get_class(), method_name
		])

		# Update debug info
		if debug_subscriptions.has(event_id):
			debug_subscriptions[event_id] = debug_subscriptions[event_id].filter(
				func(sub): return sub.callable != callable
			)


## Broadcast: emits signal with event object
func broadcast(event: Event) -> void:
	var event_id = event.event_id
	if not signal_registry.has(event_id):
		Log.warning("[EventBus] No subscribers for event: %s" % event_id)
		return # No one subscribed

	Log.debug("[EventBus] Emitting '%s' with event: %s" % [event_id, event])
	emit_signal(event_id, event)

	# HACK: ** EVENTBUS DEBUGGER PLUGIN **
	recent_emits.append({
		"event_id": event_id,
		"time": Time.get_ticks_msec(),
		"event": event,
		"subscriber_count": debug_subscriptions.get(event_id, []).size()
	})

	# Keep recetn emits list manageable
	if recent_emits.size() > MAX_RECENT_EMITS:
		recent_emits = recent_emits.slice(-MAX_RECENT_EMITS)


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

## Debug methods
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
