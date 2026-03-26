class_name ActiveStateChangedEvent
extends Event

const ID: StringName = EventIdLibrary.GLOBAL_EVENTS.ACTIVE_STATE_CHANGED

var active_state: State
var previous_state: State

func _init(_active_state: State, _previous_state: State) -> void:
	super (ID)
	active_state = _active_state
	previous_state = _previous_state
