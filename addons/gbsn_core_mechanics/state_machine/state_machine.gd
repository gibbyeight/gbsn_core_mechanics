## State Machine to manage all states of Node/Object of parent
class_name StateMachine
extends Node

## Update Mode determines what to run during the state is active
enum UPDATE_MODE {
	## Caller will not update any processes at all
	DISABLED,
	## Caller update _process() every frame with no physics simulations etc
	IDLE,
	## Caller update _pyhsics_process every frame for physics simulations
	PHYSICS,
	## Caller update _process() every frame with no physics simulations etc
	BOTH,
	## Call will update manually
	MANUAL
}

## Update mode for this state machine
@export var update_mode: UPDATE_MODE = UPDATE_MODE.PHYSICS:
	set(value):
		update_mode = value
		_set_process_modes()

## Determines whether the state machine will process unhandled inputs
@export var needs_input: bool:
	set(value):
		needs_input = value
		_set_input_mode()

## Initial state the state machine will start in once ready in the scene tree
@export var initial_state: State

## Current state the state machine is in at runtime
var active_state: State
## Holds a reference to the previous state
var previous_state: State
## Holds a reference to the next state
var next_state: State

## Dictionary storing all child states so we can assert against for any unexpected states
var _owned_states: Dictionary = {}

func _ready() -> void:
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(change_active_state)
	_set_input_mode()
	_set_process_modes()
	_setup_states()
	_set_initial_state(initial_state)


# ----------------------------------------------------------
# Public functions
# ----------------------------------------------------------

## This is the main route for changing the active state. Currently we are using the
## [code]finished[/code] signal for signalling up from the state child to determine when to change.
func change_active_state(_state_id: StringName) -> void:
	if active_state:
		active_state.exit()
		active_state.active = false
		previous_state = active_state
	
	if !_owned_states.get(_state_id):
		Log.error("State [%s] is not owned by State Machine" % _state_id)
	
	active_state = _owned_states[_state_id]
	active_state.enter()
	active_state.active = true

#	var active_state_changed_event: ActiveStateChangedEvent = ActiveStateChangedEvent.new(
#		active_state,
#		previous_state
#	)
#	EventBus.broadcast(active_state_changed_event)

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
		_owned_states[child_state.ID] = child_state


func _set_initial_state(_initial_state: State) -> void:
	if !initial_state:
		Log.warning("Initial State is NULL: Initial State must be set")
	else:
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
