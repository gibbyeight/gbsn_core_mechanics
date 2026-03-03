@abstract
class_name State
extends Node

## state_machine is a reference to the GameStateMachine that owns this state
## so the state can tell the machine to change states or access shared data
@export var state_machine: StateMachine
## name is just an identifier for logging/debugging/events

var ID: StringName

func _ready() -> void:
	if get_parent() is StateMachine:
		state_machine = get_parent()

# =============================================================================
# OVERIDE FUNCTIONS IN SPECIFIC STATES
# =============================================================================

## This runs whenever the state becomes active
## previous_state is there in case you need to know what you came from
func enter(_previous_state: State = null) -> void:
	Log.debug("Entering state: " + self.ID)

## Runs before the state is left
## next_state is there so you can clean up differently depending on where you’re going
func exit(_next_state: State = null) -> void:
	Log.debug("Exiting state: " + self.ID)


func handle_input(_event: InputEvent) -> void: pass
func update(_delta: float) -> void: pass
func physics_update(_delta: float) -> void: pass


func _report_event(event: ActiveStateChangedEvent) -> void:
	EventBus.broadcast(event)

# ## States get first crack at handling events
# ## If they return true, the event is considered handled and doesn’t propagate further
# func handle_event(_event: Event) -> bool:
# 	# Return true if event was handled. false otherwise
# 	return false


# func handle_input(_event)
