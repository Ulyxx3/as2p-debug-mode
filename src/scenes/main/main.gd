extends Node

class_name MainLevel

const BLUE_SCREEN_UID: String = "uid://ccrqllopuays2"
const PAUSE_MENU_UID: String = "uid://o2u7g05bqs4x"
const DEBUG_MENU_SCENE: PackedScene = preload("res://scenes/ui/debug_menu/debug_menu.tscn")
@onready var game_camera: Camera2D = $GameCamera
@onready var hori_bar_nine: NinePatchRect = $Frame / Scrollbars / ColorRect / HoriBarNine
@onready var vert_bar_nine: NinePatchRect = $Frame / Scrollbars / ColorRect2 / VertBarNine
@onready var safety_bounds: ColorRect = $Frame / SafetyBounds
@onready var canvas_layer: CanvasLayer = $Frame
@onready var fake_window_bounds: ColorRect = $Frame / FakeWindowBounds
@onready var gen_level: GenLevel = $GenLevel
@onready var blank_level: TileMapLayer = $BlankLevel
@onready var entities: Node2D = $Entities
@onready var scrollbars: Control = $Frame / Scrollbars
@onready var round_manager: RoundManager = $RoundManager
@onready var upgrade_manager: UpgradeManager = $UpgradeManager
@onready var arena_time_manager: ArenaTimeManager = $ArenaTimeManager
@onready var enemy_manager: EnemyManager = $EnemyManager
@onready var experience_manager: ExperienceManager = $ExperienceManager
@onready var game_currency_manager: GameCurrencyManager = $GameCurrencyManager


var vp_rect: Vector2
var game_rect: Vector2
var play_area: Rect2
var x_bar_size: float
var y_bar_size: float
var x_clamp_min: float
var x_clamp_max: float
var y_clamp_min: float
var y_clamp_max: float

var bounds: Vector2

var window_offset_start: Vector2
var window_offset_end: Vector2

var blank: bool = false

@onready var walls: Node2D = $Walls
@onready var foreground: Node2D = $Foreground
@onready var windows: Control = %Windows
@onready var stat_list: StatList = %StatList


func _ready() -> void :
	$ %Player.health_component.died.connect(on_player_died)
	get_window().size_changed.connect(adjust_limits)
	ExpandIntScaler.zoom_changed.connect(adjust_limits)
	adjust_window_limits()
	scrollbars.visible = false
	Input.joy_connection_changed.connect(on_joy_connection_changed)
	PlatformServices.overlay_toggled.connect(on_overlay_toggled)


func _physics_process(delta: float) -> void :
	if scrollbars.visible:
		hori_bar_nine.position.x = clamp(remap(game_camera.position.x, x_clamp_min, x_clamp_max, 0.0, (vp_rect.x - x_bar_size)), 0.0, (vp_rect.x - x_bar_size))
		vert_bar_nine.position.y = clamp(remap(game_camera.position.y, y_clamp_min, y_clamp_max, 0.0, (vp_rect.y - y_bar_size)), 0.0, (vp_rect.y - y_bar_size))
	walls.position = game_camera.get_screen_center_position()
	if Input.is_action_pressed("tab"):
		if not $ %StatList.visible:
			$ %StatList.refresh_stats()
			$ %StatList.refresh_run_stats()
			$ %StatList.show()
	else:
		$ %StatList.hide()


func _unhandled_input(event: InputEvent) -> void :
	if GameEvents.returning_to_menu:
		return
	if is_instance_valid(GameEvents.active_debug_menu):
		return
	var is_debug_key: bool = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_F3 or event.physical_keycode == 96:
			is_debug_key = true
	if is_debug_key or event.is_action_pressed("debug_menu"):
		GameEvents.toggle_debug_menu()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("pause") and !GameEvents.pausing:
		var pause_menu_scene: PackedScene = load(PAUSE_MENU_UID) as PackedScene
		GameEvents.spawn_overlay(pause_menu_scene.instantiate())
		get_viewport().set_input_as_handled()


func on_joy_connection_changed(device: int, connected: bool) -> void :
	if connected:
		pass
	elif !GameEvents.pausing and !GameEvents.returning_to_menu:
		var pause_menu_scene: PackedScene = load(PAUSE_MENU_UID) as PackedScene
		GameEvents.spawn_overlay(pause_menu_scene.instantiate())


func on_overlay_toggled(active: bool, user_initiated: bool, app_id: int) -> void :
	if !active:
		pass
	elif !GameEvents.pausing and !GameEvents.returning_to_menu:
		var pause_menu_scene: PackedScene = load(PAUSE_MENU_UID) as PackedScene
		GameEvents.spawn_overlay(pause_menu_scene.instantiate())


func on_player_died() -> void :
	StatTracker.bump("deaths")
	var blue_screen_scene: PackedScene = load(BLUE_SCREEN_UID) as PackedScene
	var blue_screen_instance: BlueScreen = blue_screen_scene.instantiate()
	GameEvents.spawn_overlay(blue_screen_instance)


func adjust_limits() -> void :
	if blank:
		adjust_window_limits_static()
	else:
		adjust_window_limits()
	var player: Cursor = $ %Player as Cursor
	if player != null:
		player.clamp_to_screen()
		game_camera.global_position = player.global_position
		game_camera.reset_smoothing()
		game_camera.force_update_scroll()
		game_camera.reset_physics_interpolation()


func adjust_window_limits() -> void :
	scrollbars.visible = true

	game_rect = gen_level.noise_generator.settings.world_size * 16
	window_offset_start = fake_window_bounds.global_position
	window_offset_end = fake_window_bounds.get_rect().end

	play_area.position = Vector2.ZERO
	play_area.size = game_rect

	var view_size: Vector2 = Vector2(get_viewport().size) / float(ExpandIntScaler.chosen_scale)
	game_camera.limit_left = int(0.0 - window_offset_start.x)
	game_camera.limit_top = int(0.0 - window_offset_start.y)
	game_camera.limit_right = int(game_rect.x + view_size.x - window_offset_end.x)
	game_camera.limit_bottom = int(game_rect.y + view_size.y - window_offset_end.y)


	bounds = safety_bounds.global_position
	canvas_layer.offset.y = bounds.y - 2
	canvas_layer.offset.x = bounds.x - 13


	vp_rect = fake_window_bounds.size
	x_bar_size = (vp_rect.x / game_rect.x) * vp_rect.x
	y_bar_size = (vp_rect.y / game_rect.y) * vp_rect.y

	var half_window: Vector2 = ExpandIntScaler.window.size / (float(ExpandIntScaler.chosen_scale) * 2.0)
	x_clamp_min = game_camera.limit_left + int(half_window.x)
	x_clamp_max = game_camera.limit_right - int(half_window.x)
	y_clamp_min = game_camera.limit_top + int(half_window.y)
	y_clamp_max = game_camera.limit_bottom - int(half_window.y)

	hori_bar_nine.size.x = x_bar_size
	vert_bar_nine.size.y = y_bar_size
	game_camera.reset_smoothing()
	game_camera.force_update_scroll()
	game_camera.reset_physics_interpolation()


func adjust_window_limits_static() -> void :
	game_camera.freeze_view()
	scrollbars.visible = false
	window_offset_start = fake_window_bounds.global_position
	window_offset_end = fake_window_bounds.get_rect().end + Vector2(8, 8)
	var poly: PackedVector2Array = blank_level.collision_polygon_2d.polygon
	var view_size: Vector2 = Vector2(get_viewport().size) / float(ExpandIntScaler.chosen_scale)
	game_camera.limit_left = int(poly[0].x - window_offset_start.x)
	game_camera.limit_top = int(poly[0].y - window_offset_start.y)
	game_camera.limit_right = int(poly[2].x + view_size.x - window_offset_end.x)
	game_camera.limit_bottom = int(poly[2].y + view_size.y - window_offset_end.y)
	play_area = Rect2(poly[0], poly[2] - poly[0]).abs()
	game_camera.reset_smoothing()
	game_camera.force_update_scroll()
	game_camera.reset_physics_interpolation()
