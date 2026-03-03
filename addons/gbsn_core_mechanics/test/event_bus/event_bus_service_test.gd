# GdUnit generated TestSuite
class_name EventBusServiceTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://addons/gbsn_core_mechanics/event_bus/event_bus_service.gd'

func test_ensure_signal_new_signal() -> void:
	# Given: I have an new empty EventBusService
	var mock_event_bus := auto_free(EventBusService.new())
	assert_dict(mock_event_bus.signal_registry).is_empty()
	
	# When: I ensure signal is not present 
	mock_event_bus._ensure_signal(TestEventLibrary.TEST_EVENTS.TEST_EVENT)
	
	# Then: I assert the signal has been added to the registry
	assert_dict(mock_event_bus.signal_registry).is_not_empty()
	assert_dict(mock_event_bus.signal_registry).contains_key_value(TestEventLibrary.TEST_EVENTS.TEST_EVENT, true)


func test_ensure_signal_existing_signal() -> void:
	# Given: I have an EventBusService with the existing signal
	var mock_event_bus := auto_free(EventBusService.new())
	mock_event_bus._ensure_signal(TestEventLibrary.TEST_EVENTS.TEST_EVENT)
	assert_dict(mock_event_bus.signal_registry).has_size(1)
	
	# When: I ensure signal when it is already present 
	mock_event_bus._ensure_signal(TestEventLibrary.TEST_EVENTS.TEST_EVENT)
	
	# Then: I assert the signal hasn't duplicated in the registry
	assert_dict(mock_event_bus.signal_registry).has_size(1)
	assert_dict(mock_event_bus.signal_registry).contains_key_value(TestEventLibrary.TEST_EVENTS.TEST_EVENT, true)


func test_subscribe() -> void:
	# Given: I have an EventBusService and an Object
	var mock_event_bus := auto_free(EventBusService.new())
	var mock_object := auto_free(Object.new())
	var method_name: String = "get"
	
	# When: I subscribe the test event to the Object
	mock_event_bus.subscribe(TestEventLibrary.TEST_EVENTS.TEST_EVENT, mock_object, method_name)
	
	var ds = (mock_event_bus.debug_subscriptions[TestEventLibrary.TEST_EVENTS.TEST_EVENT]).get(0)
	var ds_callable = ds.get("callable")
	var ds_connected_at = ds.get("connected_at")
	var mock_sub: Array[Dictionary] = [
		{
			"callable": ds_callable,
			"subscriber_name": str(mock_object),
			"method": method_name,
			"connected_at": ds_connected_at
		}
	]
	
	# Then: I assert that the signal exists on the emitter and the event is added to the subs in the EBS
	assert_signal(mock_event_bus).is_signal_exists(str(TestEventLibrary.TEST_EVENTS.TEST_EVENT))
	assert_dict(mock_event_bus.debug_subscriptions).contains_key_value(TestEventLibrary.TEST_EVENTS.TEST_EVENT, mock_sub)


func test_subscribe_instance_invalid() -> void:
	# Given: I have an invalid object
	var mock_event_bus := auto_free(EventBusService.new())
	var mock_object := Object.new()
	var method_name: String = "get"
	mock_object.free()
	
	# When: I try to subscribe the object to the event
	mock_event_bus.subscribe(TestEventLibrary.TEST_EVENTS.TEST_EVENT, mock_object, method_name)
	
	# Then: I assert the no event has been subscribed
	assert_array(mock_event_bus.debug_subscriptions).is_empty()
	
