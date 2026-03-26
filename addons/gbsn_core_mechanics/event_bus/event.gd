class_name Event
extends RefCounted
## An Object representing information about an event
## By extending RefCounted we can make sure it is automatically
## cleaned up when nothing else has a reference to it

## HACK: This is intentionally untyped
## as you may want to use a string or int or something else?
var event_id

# Timestamp for debugging and analytics
var timestamp: int

# Source information for 
var source: String = ""

func _init(_event_id, _event_source: String = "") -> void:
	self.event_id = _event_id
	self.source = _event_source
	self.timestamp = Time.get_ticks_msec()
	
	var stack = get_stack()
	var caller = stack.back() if stack.size() > 1 else null
	if caller and _event_source == "":
		self.source = "%s:%d" % [caller.source, caller.line]

func _to_string() -> String:
	return "Event(%s, source=%s)" % [event_id, source]
