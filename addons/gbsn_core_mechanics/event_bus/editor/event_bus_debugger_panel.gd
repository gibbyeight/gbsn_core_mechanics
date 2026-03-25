@tool
extends MarginContainer
## The UI panel displayed in the Godot debugger session tab.
## Shows a live table of EventBus subscriptions (left) and an
## event-emit log (right)

const MAX_LOG_ENTRIES: int = 500

var subscription_tree: Tree
var event_log_tree: Tree
var total_events_label: Label
var total_subscribers_label: Label
var total_emits_label: Label
var pause_button: Button
var clear_log_button: Button
var filter_label: Label
var filter_input: LineEdit

var is_paused: bool = false
var emit_counter: int = 0
var subscription_data: Dictionary = {}
var _log_entries: Array[Dictionary] = []

func _ready() -> void:
	name = "EventBus"
	_build_ui()

#region UI Contstruction
func _build_ui() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	_build_header(vbox)
	_build_tables(vbox)


func _build_header(parent: VBoxContainer) -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_color_override("seperation", 12)
	parent.add_child(header)
	
	total_events_label = Label.new()
	total_events_label.text = "Events: 0"
	header.add_child(total_events_label)
	
	total_subscribers_label = Label.new()
	total_subscribers_label.text = "Subscribers: 0"
	
	total_emits_label = Label.new()
	total_emits_label.text = "Emits: 0"
	header.add_child(total_emits_label)
	
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	filter_label = Label.new()
	filter_label.text = "Filter:"
	header.add_child(filter_label)
	
	filter_input = LineEdit.new()
	filter_input.placeholder_text = "Event ID..."
	filter_input.custom_minimum_size = Vector2(320, 0)
	filter_input.text_changed.connect(_on_filter_changed)
	header.add_child(filter_input)
	
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.toggle_mode = true
	pause_button.toggled.connect(_on_pause_toggled)
	header.add_child(pause_button)
	
	clear_log_button = Button.new()
	clear_log_button.text = "Clear Log"
	clear_log_button.pressed.connect(_on_clear_log_pressed)
	header.add_child(clear_log_button)


func _build_tables(parent: VBoxContainer) -> void:
	var hsplit: HSplitContainer = HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.split_offset = 420
	parent.add_child(hsplit)
	
	_build_subscriptions_table(hsplit)
	_build_event_log_table(hsplit)


func _build_subscriptions_table(parent: HSplitContainer) -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)
	
	var header: Label = Label.new()
	header.text = "Subscriptions"
	header.add_theme_color_override("font_size", 14)
	vbox.add_child(header)
	
	subscription_tree = Tree.new()
	subscription_tree.columns = 3
	subscription_tree.set_column_title(0, "Event / Subscriber")
	subscription_tree.set_column_title(1, "Method")
	subscription_tree.set_column_title(2, "Connected At")
	subscription_tree.column_titles_visible = true
	subscription_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subscription_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	subscription_tree.set_column_expand_ratio(0, 3)
	subscription_tree.set_column_expand_ratio(1, 2)
	subscription_tree.set_column_expand_ratio(2, 1)
	subscription_tree.hide_root = true
	vbox.add_child(subscription_tree)


func _build_event_log_table(parent: HSplitContainer) -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)
	
	var header: Label = Label.new()
	header.text = "Event Log"
	header.add_theme_color_override("font_size", 14)
	vbox.add_child(header)
	
	event_log_tree = Tree.new()
	event_log_tree.columns = 4
	event_log_tree.set_column_title(0, "Time")
	event_log_tree.set_column_title(1, "Event ID")
	event_log_tree.set_column_title(2, "Source")
	event_log_tree.set_column_title(3, "Subs")
	event_log_tree.column_titles_visible = true
	event_log_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_log_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log_tree.set_column_expand(0, false)
	event_log_tree.set_column_custom_minimum_width(0, 80)
	event_log_tree.set_column_expand_ratio(1, 2)
	event_log_tree.set_column_expand_ratio(2, 2)
	event_log_tree.set_column_expand(3, false)
	event_log_tree.set_column_custom_minimum_width(3, 50)
	event_log_tree.hide_root = true
	vbox.add_child(event_log_tree)
#endregion

#region Public API - called by EventBusDebuggerPlugin
func add_subscription(
	event_id: String,
	subscriber_name: String,
	subscriber_class: String,
	method: String,
	connected_at: int
) -> void:
	if not subscription_data.has(event_id):
		subscription_data[event_id] = []
	subscription_data[event_id].append({
		"subscriber": subscriber_name,
		"class": subscriber_class,
		"method": method,
		"connected_at": connected_at
	})
	_refresh_subscription_tree()
	_update_stats()


func remove_subscription(
	event_id: String,
	subscriber_name: String,
	method: String,
) -> void:
	if not subscription_data.has(event_id):
		return
	subscription_data[event_id] = subscription_data[event_id].filter(
		func(sub: Dictionary) -> bool:
			return sub.subscriber != subscriber_name or sub.method != method
	)
	if subscription_data[event_id].is_empty():
		subscription_data.erase(event_id)
	_refresh_subscription_tree()
	_update_stats()


func log_broadcast(
	event_id: String,
	source: String,
	timestamp: int,
	subscriber_count: int
) -> void:
	if is_paused:
		return
	
	emit_counter += 1
	_log_entries.append({
		"event_id": event_id,
		"source": source,
		"timestamp": timestamp,
		"subscriber_count": subscriber_count,
	})
	
	if _log_entries.size() > MAX_LOG_ENTRIES:
		_log_entries.slice(-MAX_LOG_ENTRIES)
	
	if not _matches_filter(event_id):
		_update_stats()
		return
	
	_append_log_tree_item(event_id, source, timestamp, subscriber_count)
	_update_stats()


func sync_full_state(data: Dictionary) -> void:
	subscription_data.clear()
	for event_id: String in data.keys():
		subscription_data[event_id] = []
		for sub_info: Dictionary in data[event_id]:
			subscription_data[event_id].append({
				"subscriber": sub_info.get("subscriber_name", "key not found"),
				"class": sub_info.get("subscriber_class", "key not found"),
				"method": sub_info.get("method", "key not found"),
				"connected_at": sub_info.get("connected_at", "key not found"),
			})
	_refresh_subscription_tree()
	_update_stats()


func clear_all() -> void:
	subscription_data.clear()
	emit_counter = 0
	_refresh_subscription_tree()
	_clear_event_logs()
	_update_stats()
#endregion

#region Internal helpers
func _refresh_subscription_tree() -> void:
	subscription_tree.clear()
	var root: TreeItem = subscription_tree.create_item()
	
	var sorted_events: Array = subscription_data.keys()
	sorted_events.sort()
	
	for event_id: String in sorted_events:
		var subs: Array = subscription_data[event_id]
		var event_item: TreeItem = subscription_tree.create_item(root)
		event_item.set_text(0, event_id)
		event_item.set_text(1, "")
		event_item.set_text(2, "%d sub%s" % [subs.size(), "" if subs.size() == 1 else "s"])
		event_item.set_custom_color(0, Color(0.95, 0.78, 0.35))
		
		for sub: Dictionary in subs:
			var sub_item: TreeItem = subscription_tree.create_item(event_item)
			var label: String = sub["subscriber"] as String
			if sub.get("class", "") != "":
				label = "%s (%s)" % [label, sub["class"]]
			sub_item.set_text(0, label)
			sub_item.set_text(1, sub["method"])
			sub_item.set_text(2, _format_time(sub["connected_at"]))


func _clear_event_logs() -> void:
	event_log_tree.clear()


func _update_stats() -> void:
	var total_events: int = subscription_data.size()
	var total_subs: int = 0
	for event_id: String in subscription_data:
		total_subs += subscription_data[event_id].size()
	
	if total_events_label:
		total_events_label.text = "Events %d" % total_events
	if total_subscribers_label:
		total_subscribers_label.text = "Subscribers: %d" % total_subs
	if total_emits_label:
		total_emits_label.text = "Emits: %d" % emit_counter


func _format_time(ms: int) -> String:
	var seconds: float =  ms / 10000.0
	if seconds < 60.0:
		return "%.2fs" % seconds
	@warning_ignore("integer_division")
	var minutes: int = int(seconds) / 60
	var remaining := fmod(seconds, 60.0)
	return "dm %05.2fs" % [minutes, seconds]


func _event_colour(event_id: String) -> Color:
	var hash_val: int = event_id.hash()
	var hue: int = fmod(absf(float(hash_val)) / 214748367.0, 1.0)
	return Color.from_hsv(hue, 0.25, 0.92)


func _matches_filter(event_id: String) -> bool:
	var f:= filter_input.text.strip_edges().to_lower() if filter_input else ""
	return f == "" or event_id.to_lower().find(f) != -1


func _append_log_tree_item(
	event_id: String,
	source: String,
	timestamp: int,
	subscriber_count: int
) -> void:
	var root: TreeItem = event_log_tree.get_root()
	if not root:
		root = event_log_tree.create_item()
	
	var item: TreeItem = event_log_tree.create_item(root)
	item.set_text(0, _format_time(timestamp))
	item.set_text(1, event_id)
	item.set_text(2, source)
	item.set_text(3, str(subscriber_count))
	
	var colour: Color = _event_colour(event_id)
	for col in 4:
		item.set_custom_color(col, colour)
	
	while root.get_child_count() > MAX_LOG_ENTRIES:
		root.get_first_child().free()
	
	event_log_tree.scroll_to_item(item)


func _rebuild_event_log() -> void:
	event_log_tree.clear()
	for entry: Dictionary in _log_entries:
		if _matches_filter(entry.event_id):
			_append_log_tree_item(
				entry.event_id,
				entry.source,
				entry.timestamp,
				entry.subscriber_count,
			)
#endregion

#region Signal callbacks
func _on_filter_changed(_new_text: String) -> void:
	_rebuild_event_log()


func _on_pause_toggled(pressed: bool) -> void:
	is_paused = pressed
	pause_button.text = "Resume" if pressed else "Pause"


func _on_clear_log_pressed() -> void:
	_log_entries.clear()
	_clear_event_logs()
	emit_counter = 0
	_update_stats()
