class_name StateMachine
extends Node

enum UPDATE_MODE {
	DISABLED,
	IDLE,
	PHYSICS,
	BOTH,
	MANUAL
}

@export var update_mode: UPDATE_MODE = UPDATE_MODE.PHYSICS:
	set(value):
		update_mode = value
		_set_process_modes()

@export var needs_input: bool:
	set(value):
		needs_input = value
		_set_input_mode()

var owned_states: Dictionary = {}

@export var initial_state: State
var initial_state_id: StringName:
	get:
		return _get_initial_state_id()

var active_state: State
var active_state_id: StringName:
	get:
		return _get_active_state_id()

var previous_state: State
var next_state: State

func _ready() -> void:
	_set_input_mode()
	_set_process_modes()
	_setup_states()
	_set_initial_state(initial_state)


# ----------------------------------------------------------
# Public functions
# ----------------------------------------------------------

func change_active_state(_state_id: StringName) -> void:
	if active_state:
		active_state.exit()
		previous_state = active_state
	
	if !owned_states.get(_state_id):
		Log.error("State [%s] is not owned by State Machine" % _state_id)
	
	active_state = owned_states[_state_id]
	active_state.enter()

	var active_state_changed_event: ActiveStateChangedEvent = ActiveStateChangedEvent.new(
		active_state,
		previous_state
	)
	EventBus.broadcast(active_state_changed_event)


# ----------------------------------------------------------
# State Machine set up functions
# ----------------------------------------------------------

func _set_input_mode() -> void:
	set_process_unhandled_input(false)

	if needs_input:
		set_process_unhandled_input(true)


func _set_process_modes() -> void:
	set_process(false)
	set_physics_process(false)

	match update_mode:
		UPDATE_MODE.IDLE:
			set_process(true)
		UPDATE_MODE.PHYSICS:
			set_physics_process(true)
		UPDATE_MODE.BOTH:
			set_process(true)
			set_physics_process(true)
		UPDATE_MODE.DISABLED, UPDATE_MODE.MANUAL:
			pass # caller will call update() / physics_update manually


func _setup_states() -> void:
	for child_state in get_children():
		owned_states[child_state.ID] = child_state


func _set_initial_state(_initial_state: State) -> void:
	if !initial_state:
		Log.error("Initial State is NULL: Initial State must be set")
	change_active_state(_initial_state.ID)


# ----------------------------------------------------------
# State input and process functions
# ----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if active_state and active_state.has_method("handle_input"):
		active_state.handle_input(event)

func _process(_delta: float) -> void:
	if active_state and active_state.has_method("update"):
		active_state.update(_delta)

func _physics_process(_delta: float) -> void:
	if active_state and active_state.has_method("physics_update"):
		active_state.physics_update(_delta)


# ----------------------------------------------------------
# Properties getters and setters
# ----------------------------------------------------------

func _get_initial_state_id() -> StringName:
	return initial_state.ID

func _get_active_state_id() -> StringName:
	return active_state.ID
