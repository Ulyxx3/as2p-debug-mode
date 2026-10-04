extends Node

signal open_main

signal paused_handled
signal unpause_handled

signal drag_started
signal drag_ended

signal health_collected(amount: int)
signal experience_vial_collected(number: float)
signal magnet_collected()
signal coin_magnet_collected()
signal currency_collected(type: String, amount: float, count_toward_total: bool, apply_gain: bool)
signal currency_spent(type: String, amount: float)
signal wallet_session_started
signal wallet_session_ended
signal reroll
signal folder_hovered
signal folder_unhovered
signal folder_clicked()
signal folder_double_clicked
signal objective_file_opened(kind: String)
signal side_task_completed
signal battle_folder_opened
signal safe_folder_opened
signal safe_folder_spawned
signal zip_file_opened_succ(at: Vector2)
signal big_wave_opened
signal ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary)
signal ability_weapon_added(weapon: Ability, current_weapons: Array)
signal weapon_picked(weapon: Ability)
signal weapon_selection_cleared
signal admin_mouse_mode_changed(enabled: bool)
signal plugin_added(plugin_def: PluginDefinition, current_plugins: Dictionary)
signal weapon_leveled(weapon_id: String, level: int)
signal driver_added(driver_def: DriverDefinition, weapon_id: String)
signal restart_weapons
signal evo_picked
signal diff_picked(picked_protocol: ProtocolSettings)
signal class_picked(picked_class: PlayerClass)
signal player_damaged(damage: float)
signal player_dodged
signal player_healed
signal player_status_updated(lag_stacks: float, slow_factor: float, infect_stacks: float, armor_penalty: float)
signal crit_hit_landed(hit_position: Vector2, damage: float, is_megacrit: bool)
signal enemy_killed(weapon_id: String, death_position: Vector2, victim_name: String)
signal widget_depleted


var fullscreen_queue: Array[FullScreen] = []
var processing_fullscreen: bool = false
var persistent_fullscreens: Dictionary = {}
var abort_queue: bool = false
var protocol_settings: ProtocolSettings
var picked_class: PlayerClass
var picked_weapon: Ability

signal fullscreen_closed()

var main_scene: PackedScene
var menu_scene: PackedScene
var main: Node
var foreground_layer: Node
var background_layer: Node

const WEAPON_EFFECT_GROUP: StringName = &"weapon_effect"
const EXP_PICKUP_GROUP: StringName = &"exp_pickup"
const COIN_PICKUP_GROUP: StringName = &"coin_pickup"
var active_cursor: Cursor
var active_widget: WidgetRuntime
var previous_cursor: Cursor
var something_dragging: bool = false

@onready var click_down: AudioStreamPlayer = $ClickDown
@onready var click_up: AudioStreamPlayer = $ClickUp

var pausing: bool
var click_grace_left: float = 0.0
var weapons_armed: bool = true
var debug_god_mode: bool = false
var debug_round_scale: float = 1.0
var returning_to_menu: bool = false
var menu_return_started: bool = false
var mouse_confined: bool = true
var flow_tween: Tween
var gameplay_time_scale: float = 1.0
var gameplay_music_pitch: float = 1.0
var player_time_compensation: float = 1.0
var last_kill_icon: Texture2D
var last_kill_max_health: float = 0.0

const MENU_PACKED: PackedScene = preload("res://scenes/ui/main_menu.tscn")


func _init() -> void :
	ResourceLoader.load("res://scenes/component/hurtbox_component.tscn")


func _process(delta: float) -> void :
	if click_grace_left > 0.0:
		click_grace_left = maxf(click_grace_left - delta, 0.0)
	if Input.is_action_just_pressed("left_click"):
		click_down.play()
	if Input.is_action_just_released("left_click"):
		click_up.play()


func begin_click_grace() -> void :
	click_grace_left = 0.5


func click_grace_active() -> bool:
	return click_grace_left > 0.0


func get_windows_layer() -> Control:
	return get_tree().get_first_node_in_group("windows_layer") as Control


func get_overlays() -> CanvasLayer:
	return get_tree().get_first_node_in_group("overlays") as CanvasLayer


var active_debug_menu: Control = null
var last_toggle_time: int = 0

func spawn_overlay(overlay: Control) -> void :
	if returning_to_menu or overlay == null:
		if overlay != null:
			overlay.queue_free()
		return
	var ov: CanvasLayer = get_overlays()
	if ov != null:
		ov.add_child(overlay)
	else:
		get_tree().root.add_child(overlay)


func toggle_debug_menu() -> void :
	var now: int = Time.get_ticks_msec()
	if now - last_toggle_time < 200:
		return
	last_toggle_time = now

	if is_instance_valid(active_debug_menu):
		if active_debug_menu.has_method("close"):
			active_debug_menu.close()
		else:
			active_debug_menu.queue_free()
		active_debug_menu = null
		return
	var existing: Array[Node] = get_tree().get_nodes_in_group("debug_menu_instance")
	if not existing.is_empty():
		for inst: Node in existing:
			if is_instance_valid(inst):
				if inst.has_method("close"):
					inst.close()
				else:
					inst.queue_free()
		active_debug_menu = null
		return

	# Fermer tout menu pause officiel préexistant pour éviter toute superposition
	var ov: CanvasLayer = get_overlays()
	if ov != null:
		for child: Node in ov.get_children():
			var c_name: String = child.name.to_lower()
			if "pause" in c_name:
				child.queue_free()

	var menu_scene: PackedScene = load("res://scenes/ui/debug_menu/debug_menu.tscn") as PackedScene
	if menu_scene == null:
		return
	active_debug_menu = menu_scene.instantiate() as Control
	spawn_overlay(active_debug_menu)


func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_F3 or event.physical_keycode == 96:
			toggle_debug_menu()
			get_viewport().set_input_as_handled()


const CORNER_WINDOW_JITTER: float = 20.0
const CORNER_WINDOW_JITTER_WIDE: float = 80.0
const CORNER_WINDOW_FAR_OUTSET: float = 20.0
var corner_window_counts: Array[int] = [0, 0, 0, 0]


func corner_window_area() -> Rect2:
	var safety_bounds: Control = get_tree().get_first_node_in_group("safety_bounds") as Control
	var size: Vector2 = safety_bounds.size
	if size.x < 1.0:
		size = Vector2(614.0, 356.0)
	var windows_layer: Control = get_windows_layer()
	if windows_layer != null:
		var chrome: Control = windows_layer.get_parent().get_node_or_null("Window") as Control
		if chrome != null:
			return Rect2(Vector2(chrome.position.x, chrome.position.y + chrome.size.y - size.y), size)
	return Rect2(safety_bounds.position, size)


func pick_corner_index(avoid_from: Node2D = null, far_from_cursor: bool = false) -> int:
	var from: Node2D = active_cursor if (far_from_cursor and active_cursor != null) else avoid_from
	if from == null:
		var all: Array[int] = [0, 1, 2, 3]
		return all.pick_random()
	var safety_bounds: Control = get_tree().get_first_node_in_group("safety_bounds") as Control
	var area: Rect2 = safety_bounds.get_global_rect()
	var pos: Vector2 = from.get_global_transform_with_canvas().origin
	var center: Vector2 = area.get_center()
	var left: bool = pos.x < center.x
	var top: bool = pos.y < center.y
	if far_from_cursor:
		if top:
			return 3 if left else 2
		return 1 if left else 0
	var skip: int = (0 if left else 1) if top else (2 if left else 3)
	var choices: Array[int] = []
	for i: int in 4:
		if i != skip:
			choices.append(i)
	return choices.pick_random()


func corner_window_position(index: int, window_size: Vector2, jitter: float, far_from_cursor: bool = false) -> Vector2:
	var area: Rect2 = corner_window_area()
	var max_x: float = area.end.x - window_size.x
	var max_y: float = area.end.y - window_size.y
	if max_x < area.position.x:
		max_x = area.position.x
	if max_y < area.position.y:
		max_y = area.position.y
	var corners: Array[Vector2] = [
		Vector2(area.position.x, area.position.y), 
		Vector2(max_x, area.position.y), 
		Vector2(area.position.x, max_y), 
		Vector2(max_x, max_y), 
	]
	if not far_from_cursor:
		return corners[index] + Vector2(randf_range( - jitter, jitter), randf_range( - jitter, jitter))
	var out_x: float = -1.0 if index == 0 or index == 2 else 1.0
	var out_y: float = -1.0 if index == 0 or index == 1 else 1.0
	var pos: Vector2 = corners[index] + Vector2(
		out_x * randf_range(0.0, CORNER_WINDOW_FAR_OUTSET), 
		out_y * randf_range(0.0, CORNER_WINDOW_FAR_OUTSET), 
	)
	var outer: Rect2 = area.grow(CORNER_WINDOW_FAR_OUTSET)
	var outer_max_x: float = outer.end.x - window_size.x
	var outer_max_y: float = outer.end.y - window_size.y
	if outer_max_x < outer.position.x:
		outer_max_x = outer.position.x
	if outer_max_y < outer.position.y:
		outer_max_y = outer.position.y
	pos.x = clampf(pos.x, outer.position.x, outer_max_x)
	pos.y = clampf(pos.y, outer.position.y, outer_max_y)
	return pos


func pick_corner_window_position(window_size: Vector2, jitter: float = CORNER_WINDOW_JITTER) -> Vector2:
	return corner_window_position(pick_corner_index(), window_size, jitter)


func spawn_corner_window(window: Control, avoid_from: Node2D = null, jitter: float = CORNER_WINDOW_JITTER, far_from_cursor: bool = false) -> void :
	var windows_layer: Control = get_windows_layer()
	windows_layer.add_child(window)
	window.set_anchors_preset(Control.PRESET_TOP_LEFT)
	window.grow_horizontal = Control.GROW_DIRECTION_END
	window.grow_vertical = Control.GROW_DIRECTION_END
	var index: int = pick_corner_index(avoid_from, far_from_cursor)
	var window_size: Vector2 = window.custom_minimum_size
	if window_size.x < 1.0:
		window_size = window.size
	window.position = corner_window_position(index, window_size, jitter, far_from_cursor)
	var filled_before: int = 0
	for count: int in corner_window_counts:
		if count > 0:
			filled_before += 1
	var was_empty: bool = corner_window_counts[index] == 0
	corner_window_counts[index] += 1
	if was_empty and filled_before == 3:
		StatTracker.bump("corner_windows_full")
	window.tree_exiting.connect(on_corner_window_exiting.bind(index), CONNECT_ONE_SHOT)
	if PolicyManager.spam_on_window_close() and window.has_signal("window_closed"):
		window.window_closed.connect(PolicyManager.on_battle_window_closed, CONNECT_ONE_SHOT)


func on_corner_window_exiting(index: int) -> void :
	corner_window_counts[index] = maxi(corner_window_counts[index] - 1, 0)


func queue_fullscreen(instance: FullScreen, persistent_key: String = "") -> void :
	var inst: FullScreen
	if persistent_key != "":
		if persistent_fullscreens.has(persistent_key):
			inst = persistent_fullscreens[persistent_key]

		else:
			persistent_fullscreens[persistent_key] = instance
			inst = instance
			inst.persistent_key = persistent_key
			get_overlays().add_child(inst)
			inst.is_persistent = true

	else:
		inst = instance

	fullscreen_queue.append(inst)

	if not processing_fullscreen:
		process_next_fullscreen()


func abort_fullscreen_queue(restore_active_cursor: bool = true) -> void :
	abort_queue = true
	fullscreen_queue.clear()
	processing_fullscreen = false
	var overlays: CanvasLayer = get_overlays()
	if overlays != null:
		for child: Node in overlays.get_children():
			var screen: FullScreen = child as FullScreen
			if screen == null:
				continue
			if screen.animation_player != null:
				screen.animation_player.stop()
			if screen.is_persistent:
				screen.hide()
			else:
				screen.queue_free()
	if returning_to_menu:
		active_cursor = null
		previous_cursor = null
	elif restore_active_cursor:
		restore_cursor()
	fullscreen_closed.emit()


func process_next_fullscreen() -> void :
	if abort_queue or returning_to_menu or fullscreen_queue.is_empty():
		processing_fullscreen = false
		return

	processing_fullscreen = true

	var instance: FullScreen = fullscreen_queue.pop_front()
	if not is_instance_valid(instance):
		process_next_fullscreen()
		return

	if instance.is_persistent:
		if not pausing:
			pause_game(0.0)
	else:
		if not pausing:
			if fullscreen_queue.is_empty():
				pause_game(1.0)
			else:
				pause_game(0.2)
			await paused_handled
			if abort_queue or returning_to_menu:
				processing_fullscreen = false
				return
		get_overlays().add_child(instance)

	await get_tree().process_frame
	if abort_queue or returning_to_menu or not is_instance_valid(instance):
		processing_fullscreen = false
		return
	instance.open()

	await fullscreen_closed
	if abort_queue or returning_to_menu:
		processing_fullscreen = false
		return

	process_next_fullscreen()


func pause_game(slowdown: float) -> void :
	pausing = true
	if is_instance_valid(active_widget):
		active_widget.suspend_for_pause()
	if flow_tween != null and flow_tween.is_valid():
		flow_tween.kill()
	if slowdown > 0.0:
		flow_tween = create_tween().set_loops(1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		flow_tween.set_ignore_time_scale(true)
		flow_tween.tween_property(Engine, "time_scale", 0.0, slowdown / Settings.anim_speed_multi)
		flow_tween.parallel().tween_property(MusicPlayer, "pitch_scale", 0.75, slowdown / Settings.anim_speed_multi)
		await flow_tween.finished
	if returning_to_menu:
		return
	Engine.time_scale = 1.0
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	if main:
		main.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(foreground_layer):
		foreground_layer.process_mode = Node.PROCESS_MODE_DISABLED
	paused_handled.emit()


func unpause_game(speedup: float) -> void :
	if returning_to_menu or abort_queue:
		return
	get_tree().paused = false
	if main:
		main.process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(foreground_layer):
		foreground_layer.process_mode = Node.PROCESS_MODE_INHERIT
	if flow_tween != null and flow_tween.is_valid():
		flow_tween.kill()
	if speedup > 0.0:
		flow_tween = create_tween().set_loops(1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		flow_tween.set_ignore_time_scale(true)
		flow_tween.tween_property(Engine, "time_scale", gameplay_time_scale, speedup / Settings.anim_speed_multi).from(0.0)
		flow_tween.parallel().tween_property(MusicPlayer, "pitch_scale", gameplay_music_pitch, speedup / Settings.anim_speed_multi)
		await flow_tween.finished
	Engine.time_scale = gameplay_time_scale
	MusicPlayer.pitch_scale = gameplay_music_pitch
	pausing = false
	unpause_handled.emit()


func roll_rarity(luck_multiplier: float = 1.0) -> int:
	const BASE_THRESHOLDS: Array[float] = [0.01, 0.05, 0.15, 0.4, 1.0]

	var roll: float = randf()

	for i: int in BASE_THRESHOLDS.size():
		if roll <= BASE_THRESHOLDS[i] * luck_multiplier * StatsManager.final_stats.get("upgrade_player_luck"):
			return i

	return BASE_THRESHOLDS.size() - 1


func set_active_cursor(cursor: Cursor) -> void :
	previous_cursor = active_cursor
	active_cursor = cursor
	if is_instance_valid(active_cursor):
		active_cursor.request_hardware_mouse_sync()
	sync_mouse_confine()


func restore_cursor() -> void :
	if returning_to_menu:
		active_cursor = null
		previous_cursor = null
		return
	active_cursor = previous_cursor if is_instance_valid(previous_cursor) else null
	previous_cursor = null
	if not is_instance_valid(active_cursor) and is_inside_tree():
		active_cursor = get_tree().get_first_node_in_group("player") as Cursor
	sync_mouse_confine()


func set_mouse_confined(confined: bool) -> void :
	mouse_confined = confined
	sync_mouse_confine()


func sync_mouse_confine() -> void :
	if not mouse_confined:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		return
	if is_instance_valid(active_cursor) and not active_cursor.mouse_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func emit_open_main() -> void :
	abort_queue = false
	mouse_confined = true
	open_main.emit()
	if main_scene == null:
		main_scene = load("res://scenes/main/main.tscn") as PackedScene
	get_tree().change_scene_to_packed(main_scene)
	await get_tree().scene_changed
	main = get_tree().get_first_node_in_group("main")
	foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	background_layer = get_tree().get_first_node_in_group("background_layer")


func emit_drag_started() -> void :
	drag_started.emit()


func emit_drag_ended() -> void :
	drag_ended.emit()


func emit_coin_magnet_collected() -> void :
	coin_magnet_collected.emit()


func emit_magnet_collected() -> void :
	magnet_collected.emit()


func emit_experience_vial_collected(number: float) -> void :
	experience_vial_collected.emit(number)


func emit_health_collected(amount: int) -> void :
	health_collected.emit(amount)


func emit_currency_collected(type: String, amount: float, count_toward_total: bool = true, apply_gain: bool = true) -> void :
	currency_collected.emit(type, amount, count_toward_total, apply_gain)


func emit_currency_spent(type: String, amount: float) -> void :
	currency_spent.emit(type, amount)


func emit_wallet_session_started() -> void :
	wallet_session_started.emit()


func emit_wallet_session_ended() -> void :
	wallet_session_ended.emit()


func emit_reroll() -> void :
	reroll.emit()


func emit_folder_hovered() -> void :
	folder_hovered.emit()


func emit_folder_unhovered() -> void :
	folder_unhovered.emit()


func emit_folder_clicked() -> void :
	folder_clicked.emit()


func emit_folder_double_clicked() -> void :
	folder_double_clicked.emit()


func emit_objective_file_opened(kind: String) -> void :
	objective_file_opened.emit(kind)


func emit_side_task_completed() -> void :
	side_task_completed.emit()


func emit_battle_folder_opened() -> void :
	weapons_armed = true
	battle_folder_opened.emit()


func emit_safe_folder_opened() -> void :
	weapons_armed = false
	safe_folder_opened.emit()
	restart_weapons.emit()


func emit_safe_folder_spawned() -> void :
	safe_folder_spawned.emit()


func emit_zip_file_opened_succ(at: Vector2 = Vector2.ZERO) -> void :
	zip_file_opened_succ.emit(at)


func emit_big_wave_opened() -> void :
	big_wave_opened.emit()


func emit_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void :
	ability_upgrade_added.emit(upgrade, current_upgrades)


func emit_ability_weapon_added(weapon: AbilityUpgrade, current_weapons: Array) -> void :
	ability_weapon_added.emit(weapon, current_weapons)


func emit_weapon_picked(weapon: Ability) -> void :
	picked_weapon = weapon
	weapon_picked.emit(weapon)


func emit_weapon_selection_cleared() -> void :
	picked_weapon = null
	weapon_selection_cleared.emit()


func emit_admin_mouse_mode_changed(enabled: bool) -> void :
	admin_mouse_mode_changed.emit(enabled)


func register_weapon_effect(node: Node, parent: Node) -> Node:
	if parent != null and node.get_parent() != parent:
		if node.get_parent() == null:
			parent.add_child(node)
		else:
			node.reparent(parent)
	if not node.is_in_group(WEAPON_EFFECT_GROUP):
		node.add_to_group(WEAPON_EFFECT_GROUP)
	return node


func clear_weapon_effects() -> void :
	WeaponEffectPool.release_active_effects()
	var remaining: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group(WEAPON_EFFECT_GROUP):
		remaining.append(node)
	for node: Node in remaining:
		if not is_instance_valid(node):
			continue
		if node is SolitaireTrails:
			(node as SolitaireTrails).clear_trails()
			continue
		if node.get_parent() == WeaponEffectPool:
			continue
		node.queue_free()


func clear_low_health_fx() -> void :
	AudioServer.set_bus_effect_enabled(0, 0, false)
	CrtFilter.reset_look()
	var vignette: Node = get_tree().get_first_node_in_group("vignette")
	if vignette != null and vignette.has_method("clear_low_health"):
		vignette.clear_low_health()


func end_run() -> void :
	weapons_armed = true
	persistent_fullscreens.clear()
	PolicyManager.clear_protocol()
	clear_low_health_fx()
	clear_weapon_effects()
	WeaponEffectPool.clear_all()
	FloatingTextPool.clear_all()
	EnemyPool.clear_all()
	StatusEffectManager.clear_all()
	PickupPool.clear_all()
	main = null
	foreground_layer = null
	background_layer = null
	active_cursor = null
	previous_cursor = null
	something_dragging = false
	for i: int in 4:
		corner_window_counts[i] = 0


func reset_return_to_menu_state() -> void :
	returning_to_menu = false
	menu_return_started = false
	abort_queue = false
	mouse_confined = true
	pausing = false


func return_to_main_menu(reset_audio_bus: bool = false, blackout_sec: float = 0.0) -> void :
	returning_to_menu = true
	if menu_return_started:
		print("return_to_menu: ignored duplicate")
		return
	menu_return_started = true
	return_to_main_menu_async(reset_audio_bus, blackout_sec)


func return_to_main_menu_async(reset_audio_bus: bool, blackout_sec: float) -> void :
	print("return_to_menu: start")
	if menu_scene == null:
		menu_scene = MENU_PACKED
	StatTracker.finish_run(false)
	MetaProgression.save()
	print("return_to_menu: save done")
	if blackout_sec > 0.0:
		await get_tree().create_timer(blackout_sec, true, false, true).timeout
	abort_fullscreen_queue(false)

	if flow_tween != null and flow_tween.is_valid():
		flow_tween.kill()
	gameplay_time_scale = 1.0
	gameplay_music_pitch = 1.0
	player_time_compensation = 1.0
	Engine.time_scale = 1.0
	MusicPlayer.pitch_scale = 1.0
	if is_instance_valid(main):
		main.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(foreground_layer):
		foreground_layer.process_mode = Node.PROCESS_MODE_DISABLED
	var overlays: CanvasLayer = get_overlays()
	if overlays != null:
		overlays.process_mode = Node.PROCESS_MODE_DISABLED
	PhysicsServer2D.set_active(false)

	await get_tree().process_frame
	end_run()
	await get_tree().process_frame
	StatsManager.initialize_stats()
	MusicPlayer.halt()
	clear_low_health_fx()
	if reset_audio_bus:
		AudioServer.set_bus_effect_enabled(0, 0, false)

	await get_tree().process_frame
	if not is_inside_tree():
		print("return_to_menu: aborted, not in tree")
		return
	print("return_to_menu: change_scene")
	var err: Error = get_tree().change_scene_to_packed(menu_scene)
	if err != OK:
		print("return_to_menu: change_scene failed ", err)
		push_error("return_to_menu: change_scene_to_packed failed: %s" % err)
		return
	await get_tree().scene_changed
	get_tree().paused = false
	PhysicsServer2D.set_active(true)
	pausing = false
	abort_queue = false
	print("return_to_menu: done")


func reset_weapons() -> void :
	clear_weapon_effects()
	restart_weapons.emit()


func emit_restart_weapons() -> void :
	restart_weapons.emit()


func emit_plugin_added(plugin_def: PluginDefinition, current_plugins: Dictionary) -> void :
	plugin_added.emit(plugin_def, current_plugins)


func emit_weapon_leveled(weapon_id: String, level: int) -> void :
	weapon_leveled.emit(weapon_id, level)


func emit_driver_added(driver_def: DriverDefinition, weapon_id: String) -> void :
	driver_added.emit(driver_def, weapon_id)


func emit_evo_picked() -> void :
	evo_picked.emit()


func emit_diff_picked(picked_protocol: ProtocolSettings) -> void :
	diff_picked.emit(picked_protocol)


func emit_class_picked(player_class: PlayerClass) -> void :
	picked_class = player_class
	class_picked.emit(player_class)


func emit_player_damaged(damage: float) -> void :
	player_damaged.emit(damage)


func emit_player_dodged() -> void :
	player_dodged.emit()


func emit_player_healed() -> void :
	player_healed.emit()


func emit_player_status_updated(
	lag_stacks: float, 
	slow_factor: float, 
	infect_stacks: float = 0.0, 
	armor_penalty: float = 0.0
) -> void :
	player_status_updated.emit(lag_stacks, slow_factor, infect_stacks, armor_penalty)


func emit_crit_hit_landed(hit_position: Vector2 = Vector2.ZERO, damage: float = 0.0, is_megacrit: bool = false) -> void :
	crit_hit_landed.emit(hit_position, damage, is_megacrit)


func emit_enemy_killed(weapon_id: String = "", death_position: Vector2 = Vector2.ZERO, victim_name: String = "") -> void :
	enemy_killed.emit(weapon_id, death_position, victim_name)


func emit_widget_depleted() -> void :
	widget_depleted.emit()
