extends Node

func _ready() -> void:
	var ev: Event = Event.new("TestEvent")
	EventBus.broadcast(ev)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var ev: Event = Event.new("TestInputEvent")
		EventBus.broadcast(ev)
