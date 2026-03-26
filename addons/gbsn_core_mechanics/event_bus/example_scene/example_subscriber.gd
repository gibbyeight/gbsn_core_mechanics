extends Node

func _ready() -> void:
	EventBus.subscribe("TestEvent", self, "_on_test")
	EventBus.subscribe("TestInputEvent", self, "_on_test")


func _on_test(event: Event) -> void:
	Log.debug("Recieved: %s" % event)
