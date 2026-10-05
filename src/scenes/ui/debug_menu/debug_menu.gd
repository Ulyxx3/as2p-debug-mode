extends Control
class_name DebugMenu

enum TabType {
	STATS = 0,
	ITEMS = 1,
	PROGRESS = 2,
	CHEATS = 3
}

var current_tab: TabType = TabType.STATS
var is_closing: bool = false
var items_subtab: String = "weapons" # "weapons", "drivers", "plugins"
var current_lang: String = "en"

# Les 18 statistiques du joueur
const STAT_DEFINITIONS: Array[Dictionary] = [
	{"id": "upgrade_player_max_health", "en": "Max HP", "fr": "PV Maxi", "step": 1.0, "is_mult": false},
	{"id": "upgrade_player_health_regen", "en": "Health Regen", "fr": "Regen PV", "step": 0.05, "is_mult": false},
	{"id": "upgrade_player_damage_multi", "en": "Damage Multi", "fr": "Force Attaque", "step": 0.25, "is_mult": true},
	{"id": "upgrade_player_power_multi", "en": "Power Multi", "fr": "Puissance", "step": 0.25, "is_mult": true},
	{"id": "upgrade_player_refresh_multi", "en": "Attack Cooldown", "fr": "Cadence Tir", "step": 0.1, "is_mult": true},
	{"id": "upgrade_player_weap_speed", "en": "Weapon Speed", "fr": "Vitesse Armes", "step": 0.2, "is_mult": true},
	{"id": "upgrade_player_weap_size", "en": "Weapon Size", "fr": "Taille Armes", "step": 0.2, "is_mult": true},
	{"id": "upgrade_player_weap_amount", "en": "Weapon Amount", "fr": "Nombre Tirs", "step": 1.0, "is_mult": false},
	{"id": "upgrade_player_speed", "en": "Move Speed", "fr": "Vitesse Depl.", "step": 0.2, "is_mult": true},
	{"id": "upgrade_player_armor", "en": "Armor", "fr": "Protection", "step": 1.0, "is_mult": false},
	{"id": "upgrade_player_dodge", "en": "Dodge", "fr": "Perte Paquets", "step": 0.1, "is_mult": false},
	{"id": "upgrade_player_crit_chance", "en": "Crit Chance", "fr": "Chance Critique", "step": 0.05, "is_mult": true},
	{"id": "upgrade_player_crit_damage_multi", "en": "Crit Damage", "fr": "Degats Crit.", "step": 0.5, "is_mult": true},
	{"id": "upgrade_player_luck", "en": "Luck", "fr": "Chance", "step": 0.25, "is_mult": true},
	{"id": "upgrade_player_magnetism_multi", "en": "Pickup Radius", "fr": "Magnetisme", "step": 0.25, "is_mult": true},
	{"id": "upgrade_player_proc_speed", "en": "Proc Speed", "fr": "Vitesse CPU", "step": 0.2, "is_mult": true},
	{"id": "upgrade_player_exp_gain", "en": "Exp Multi", "fr": "Gain EXP", "step": 0.25, "is_mult": true},
	{"id": "upgrade_player_coin_gain", "en": "Coin Multi", "fr": "Gain Pieces", "step": 0.25, "is_mult": true}
]

# Les 24 armes officielles du jeu
const ALL_WEAPONS: Array[Dictionary] = [
	{"id": "weapon_avd", "name": "AVD"},
	{"id": "weapon_avn", "name": "AVN Buddy"},
	{"id": "weapon_blatand", "name": "Blåtand"},
	{"id": "weapon_bubbles", "name": "Bubbles"},
	{"id": "weapon_cdrive", "name": "C-Drive"},
	{"id": "weapon_cone", "name": "Cone"},
	{"id": "weapon_cruiser", "name": "Cruiser"},
	{"id": "weapon_cut", "name": "Cut"},
	{"id": "weapon_email", "name": "Email"},
	{"id": "weapon_firewall", "name": "Firewall"},
	{"id": "weapon_fontart", "name": "FontArt"},
	{"id": "weapon_fraps", "name": "Fraps"},
	{"id": "weapon_hitmarkers", "name": "Hitmarkers"},
	{"id": "weapon_minesweeper", "name": "Minesweeper"},
	{"id": "weapon_modem", "name": "Modem 56k"},
	{"id": "weapon_orchestra", "name": "Orchestra"},
	{"id": "weapon_paint", "name": "MS Paint"},
	{"id": "weapon_pinball", "name": "Pinball"},
	{"id": "weapon_quarantine", "name": "Quarantine"},
	{"id": "weapon_satellite", "name": "Satellite"},
	{"id": "weapon_scimitar", "name": "Scimitar"},
	{"id": "weapon_search", "name": "Search Dog"},
	{"id": "weapon_sniper", "name": "Sniper"},
	{"id": "weapon_solitaire", "name": "Solitaire"}
]

# Fichiers cliquables à faire spawn
const CLICKABLE_FILE_PATHS: Array[Dictionary] = [
	{"name": "Cracked Installer", "path": "res://scenes/game_object/clickables/cracked_installer/cracked_installer_file.tscn"},
	{"name": "Download RAM", "path": "res://scenes/game_object/clickables/download_ram/download_ram_file.tscn"},
	{"name": "Defrag File", "path": "res://scenes/game_object/clickables/defrag/defrag.tscn"},
	{"name": "Health Check", "path": "res://scenes/game_object/clickables/health_check/health_check.tscn"},
	{"name": "Coin Magnet", "path": "res://scenes/game_object/clickables/coin_mag/coin_magnet.tscn"},
	{"name": "Zip File", "path": "res://scenes/game_object/clickables/zipfile/zip_file.tscn"},
	{"name": "Keygen", "path": "res://scenes/game_object/clickables/keygen_file/keygen_file.tscn"},
	{"name": "Torrent", "path": "res://scenes/game_object/clickables/torrent_file/torrent_file.tscn"},
	{"name": "Legendary Installer", "path": "res://scenes/game_object/clickables/legendary_installer/legendary_installer_file.tscn"}
]

var basic_window: PanelContainer = null
var content: VBoxContainer = null
var status_label: Label = null
var tab_bar: HBoxContainer = null
var menu_cursor: Cursor = null

func init_language() -> void:
	var loc: String = TranslationServer.get_locale().to_lower()
	if loc.begins_with("fr"):
		current_lang = "fr"
	else:
		current_lang = "en"

func t(en_txt: String, fr_txt: String) -> String:
	return fr_txt if current_lang == "fr" else en_txt

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("debug_menu_instance")
	
	init_language()
	
	# 1. Éliminer immédiatement tout ancien curseur parasite
	for c in get_children():
		if c.name == "Cursor" or c is Cursor:
			c.free()
	
	# 2. Bloquer les clics au travers (MOUSE_FILTER_STOP) et passer au premier plan
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	
	var bg = get_node_or_null("ColorRect") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "ColorRect"
		add_child(bg)
		move_child(bg, 0)
	
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	if not bg.gui_input.is_connected(on_bg_gui_input):
		bg.gui_input.connect(on_bg_gui_input)
	
	# 3. Récupérer ou créer la fenêtre rétro
	basic_window = get_node_or_null("BasicWindow") as PanelContainer
	if basic_window == null:
		var win_scene = load("res://scenes/ui/Window/basic_window.tscn") as PackedScene
		if win_scene != null:
			basic_window = win_scene.instantiate() as PanelContainer
			add_child(basic_window)
	
	if basic_window != null:
		basic_window.mouse_filter = Control.MOUSE_FILTER_STOP
		basic_window.set_anchors_preset(Control.PRESET_CENTER)
		basic_window.custom_minimum_size = Vector2(470, 275)
		basic_window.custom_maximum_size = Vector2(470, 275)
		basic_window.offset_left = -235.0
		basic_window.offset_right = 235.0
		basic_window.offset_top = -130.0
		basic_window.offset_bottom = 145.0
		
		# Masquer barre d'outils Windows standard
		var win_toolbar = basic_window.get_node_or_null("PanelContainer")
		if win_toolbar != null:
			win_toolbar.visible = false
		
		var win_footer = basic_window.get_node_or_null("VBoxContainer")
		if win_footer != null:
			win_footer.visible = false
		
		# Titre rétro
		var title_label = basic_window.get_node_or_null("MarginContainer2/Label") as Label
		if title_label != null:
			title_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			title_label.text = "Antivirus Survivors 2003 - Debug Trainer [F1 / F3]"
		
		# Connecter la croix rouge
		var close_btn = basic_window.get_node_or_null("MarginContainer/HBoxContainer/Close") as Control
		if close_btn != null:
			close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			if not close_btn.gui_input.is_connected(on_close_icon_gui_input):
				close_btn.gui_input.connect(on_close_icon_gui_input)
		
		# Construction de la hiérarchie de contenu
		var margin_container = basic_window.get_node_or_null("Content") as MarginContainer
		if margin_container == null:
			margin_container = MarginContainer.new()
			margin_container.name = "Content"
			basic_window.add_child(margin_container)
		
		margin_container.add_theme_constant_override("margin_left", 8)
		margin_container.add_theme_constant_override("margin_top", 22)
		margin_container.add_theme_constant_override("margin_right", 8)
		margin_container.add_theme_constant_override("margin_bottom", 8)
		
		var root_col = margin_container.get_node_or_null("RootCol") as VBoxContainer
		if root_col == null:
			root_col = VBoxContainer.new()
			root_col.name = "RootCol"
			margin_container.add_child(root_col)
		root_col.add_theme_constant_override("separation", 2)
		
		# Nettoyer root_col pour reconstruire une interface propre
		for child in root_col.get_children():
			child.queue_free()
		
		# A. Barre d'onglets
		tab_bar = HBoxContainer.new()
		tab_bar.name = "TabBar"
		tab_bar.add_theme_constant_override("separation", 3)
		root_col.add_child(tab_bar)
		setup_tab_bar_buttons()
		
		# B. Label de statut
		status_label = Label.new()
		status_label.name = "StatusLabel"
		status_label.theme_type_variation = &"FuzzyType"
		status_label.text = t("Ready", "Pret")
		root_col.add_child(status_label)
		
		# C. ScrollContainer
		var scroll = ScrollContainer.new()
		scroll.name = "ScrollContainer"
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root_col.add_child(scroll)
		
		# D. Content VBoxContainer
		content = VBoxContainer.new()
		content.name = "ContentBox"
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 2)
		scroll.add_child(content)
	
	# 4. Activer le curseur de menu in-game dédié (comme dans le menu pause)
	var cursor_scene = load("res://scenes/game_object/cursor/cursor.tscn") as PackedScene
	if cursor_scene != null:
		menu_cursor = cursor_scene.instantiate() as Cursor
		if menu_cursor != null:
			menu_cursor.name = "DebugMenuCursor"
			menu_cursor.mouse_mode = true
			menu_cursor.process_mode = Node.PROCESS_MODE_ALWAYS
			menu_cursor.z_index = 4096
			add_child(menu_cursor)
			if GameEvents != null and GameEvents.has_method("set_active_cursor"):
				GameEvents.set_active_cursor(menu_cursor)
	
	# 5. Mettre le jeu en pause officielle propre
	if GameEvents != null and GameEvents.has_method("pause_game"):
		GameEvents.pause_game(0.0)
	else:
		get_tree().paused = true
	
	# Écouter les mises à jour des stats pour rafraîchir en direct
	if StatsManager != null and not StatsManager.stats_updated.is_connected(on_stats_updated_refresh):
		StatsManager.stats_updated.connect(on_stats_updated_refresh)
	
	# Rendu initial
	render_current_tab()

func on_bg_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()

func on_close_icon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_F3 or event.physical_keycode == 96:
			close()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
			return

func close() -> void:
	if is_closing:
		return
	is_closing = true
	
	if GameEvents != null and GameEvents.get("active_debug_menu") == self:
		GameEvents.set("active_debug_menu", null)
	
	if is_instance_valid(menu_cursor):
		if GameEvents != null and GameEvents.active_cursor == menu_cursor:
			GameEvents.restore_cursor()
		menu_cursor.queue_free()
	
	if GameEvents != null and GameEvents.has_method("unpause_game"):
		GameEvents.unpause_game(0.0)
	else:
		get_tree().paused = false
	
	# Garantir que la vitesse choisie reste active en jeu
	if GameEvents != null and GameEvents.get("gameplay_time_scale") != null:
		Engine.time_scale = GameEvents.gameplay_time_scale
		
	queue_free()

func _exit_tree() -> void:
	if is_instance_valid(menu_cursor) and GameEvents != null and GameEvents.active_cursor == menu_cursor:
		GameEvents.restore_cursor()

func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func clear_content() -> void:
	if content == null:
		return
	for child in content.get_children():
		child.queue_free()

func on_stats_updated_refresh() -> void:
	if current_tab == TabType.STATS and is_instance_valid(content) and not is_closing:
		render_current_tab()

# ==============================================================================
# BARRE D'ONGLETS
# ==============================================================================
func setup_tab_bar_buttons() -> void:
	if tab_bar == null:
		return
	
	for child in tab_bar.get_children():
		child.queue_free()
	
	create_tab_button("📊 " + t("Stats", "Stats"), TabType.STATS, 65)
	create_tab_button("⚔️ " + t("Items", "Items"), TabType.ITEMS, 65)
	create_tab_button("📈 " + t("Progr.", "Progr."), TabType.PROGRESS, 65)
	create_tab_button("⚡ " + t("Cheats", "Triche"), TabType.CHEATS, 65)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.add_child(spacer)
	
	# Bouton de bascule de langue instantanée
	var btn_lang = Button.new()
	btn_lang.text = "🌐 " + ("FR" if current_lang == "en" else "EN")
	btn_lang.tooltip_text = t("Switch to French", "Passer en anglais")
	btn_lang.custom_minimum_size = Vector2(46, 20)
	btn_lang.pressed.connect(func():
		current_lang = "fr" if current_lang == "en" else "en"
		setup_tab_bar_buttons()
		render_current_tab()
	)
	tab_bar.add_child(btn_lang)
	
	var btn_close = Button.new()
	btn_close.text = "✖ " + t("Close", "Fermer")
	btn_close.custom_minimum_size = Vector2(60, 20)
	btn_close.pressed.connect(close)
	tab_bar.add_child(btn_close)

func create_tab_button(text: String, tab_id: TabType, min_w: int = 65) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_w, 20)
	btn.pressed.connect(func():
		current_tab = tab_id
		render_current_tab()
	)
	tab_bar.add_child(btn)

func render_current_tab() -> void:
	clear_content()
	match current_tab:
		TabType.STATS:
			render_stats_tab()
		TabType.ITEMS:
			render_items_tab()
		TabType.PROGRESS:
			render_progress_tab()
		TabType.CHEATS:
			render_cheats_tab()

# ==============================================================================
# ONGLET 1 : STATISTIQUES (18 STATS + POINTS DE VIE)
# ==============================================================================
func render_stats_tab() -> void:
	add_header_row(t("=== 📊 PLAYER STATS (REAL TIME) ===", "=== 📊 STATISTIQUES DU JOUEUR (TEMPS REEL) ==="))
	
	var player = get_player()
	var hp_info = t("Player not detected (Not in run)", "Joueur non detecte (Hors partie)")
	if player != null and player.health_component != null:
		var cur_hp = player.health_component.current_health
		var max_hp = player.health_component.max_health
		hp_info = t("Health : %d / %d HP", "Points de Vie : %d / %d HP") % [roundi(cur_hp), roundi(max_hp)]
	
	var hp_row = HBoxContainer.new()
	var hp_label = Label.new()
	hp_label.text = hp_info
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_label)
	
	var btn_heal = Button.new()
	btn_heal.text = t("Full Heal", "Soin Complet")
	btn_heal.pressed.connect(func():
		heal_player_full()
		render_current_tab()
	)
	hp_row.add_child(btn_heal)
	
	var btn_hp50 = Button.new()
	btn_hp50.text = "+50 HP"
	btn_hp50.pressed.connect(func():
		modify_player_current_hp(50.0)
		render_current_tab()
	)
	hp_row.add_child(btn_hp50)
	
	var btn_hurt = Button.new()
	btn_hurt.text = "-20 HP"
	btn_hurt.pressed.connect(func():
		modify_player_current_hp(-20.0)
		render_current_tab()
	)
	hp_row.add_child(btn_hurt)
	content.add_child(hp_row)
	
	# Boutons d'ajustement global
	var fast_row = HBoxContainer.new()
	var btn_buff_all = Button.new()
	btn_buff_all.text = t("⚡ +20% ALL STATS", "⚡ +20% TOUTES STATS")
	btn_buff_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_buff_all.pressed.connect(func():
		buff_all_stats(0.2)
		set_status(t("+20% applied to all player stats!", "+20% applique a toutes les statistiques !"))
		render_current_tab()
	)
	fast_row.add_child(btn_buff_all)
	
	var btn_godly = Button.new()
	btn_godly.text = "🔥 GODLY STATS (x10)"
	btn_godly.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_godly.pressed.connect(func():
		buff_all_stats(9.0)
		set_status(t("Godly stats x10 applied!", "Statistiques divines x10 appliquees !"))
		render_current_tab()
	)
	fast_row.add_child(btn_godly)
	
	var btn_reset_all = Button.new()
	btn_reset_all.text = t("🔄 Reset Stats", "🔄 Reset Stats")
	btn_reset_all.pressed.connect(func():
		reset_all_stats()
		set_status(t("Default stats restored.", "Stats de base restaurees."))
		render_current_tab()
	)
	fast_row.add_child(btn_reset_all)
	content.add_child(fast_row)
	
	add_separator()
	
	# Les 18 statistiques du joueur
	for item in STAT_DEFINITIONS:
		var stat_id: String = item["id"]
		var stat_name: String = item["fr"] if current_lang == "fr" else item["en"]
		var step: float = item["step"]
		var is_mult: bool = item["is_mult"]
		
		var cur_val: float = 0.0
		if StatsManager != null and StatsManager.final_stats.has(stat_id):
			cur_val = StatsManager.final_stats[stat_id]
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		
		var name_lbl = Label.new()
		name_lbl.text = stat_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = "%.2f" % cur_val
		val_lbl.custom_minimum_size = Vector2(42, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_lbl)
		
		var btn_minus = Button.new()
		btn_minus.text = " - "
		btn_minus.custom_minimum_size = Vector2(24, 20)
		btn_minus.pressed.connect(func():
			adjust_stat(stat_id, -step)
			if StatsManager != null:
				val_lbl.text = "%.2f" % StatsManager.final_stats.get(stat_id, 0.0)
		)
		row.add_child(btn_minus)
		
		var btn_plus = Button.new()
		btn_plus.text = " + "
		btn_plus.custom_minimum_size = Vector2(24, 20)
		btn_plus.pressed.connect(func():
			adjust_stat(stat_id, step)
			if StatsManager != null:
				val_lbl.text = "%.2f" % StatsManager.final_stats.get(stat_id, 0.0)
		)
		row.add_child(btn_plus)
		
		var btn_plus5 = Button.new()
		btn_plus5.text = "+5x"
		btn_plus5.custom_minimum_size = Vector2(30, 20)
		btn_plus5.pressed.connect(func():
			adjust_stat(stat_id, step * 5.0)
			if StatsManager != null:
				val_lbl.text = "%.2f" % StatsManager.final_stats.get(stat_id, 0.0)
		)
		row.add_child(btn_plus5)
		
		var btn_rst = Button.new()
		btn_rst.text = " 0 "
		btn_rst.custom_minimum_size = Vector2(24, 20)
		btn_rst.pressed.connect(func():
			reset_stat(stat_id)
			if StatsManager != null:
				val_lbl.text = "%.2f" % StatsManager.final_stats.get(stat_id, 0.0)
		)
		row.add_child(btn_rst)
		
		var margin_pad = Control.new()
		margin_pad.custom_minimum_size = Vector2(12, 0)
		row.add_child(margin_pad)
		
		content.add_child(row)

# ==============================================================================
# ONGLET 2 : ITEMS & EQUIPEMENT (ARMES, DRIVERS, PLUGINS)
# ==============================================================================
func render_items_tab() -> void:
	add_header_row(t("=== ⚔️ INVENTORY & EQUIPMENT ===", "=== ⚔️ INVENTAIRE & EQUIPEMENT ==="))
	
	var subtab_row = HBoxContainer.new()
	var btn_w = Button.new()
	btn_w.text = t(" Weapons (24) ", " Armes (24) ")
	btn_w.pressed.connect(func():
		items_subtab = "weapons"
		render_current_tab()
	)
	subtab_row.add_child(btn_w)
	
	var btn_d = Button.new()
	btn_d.text = t(" Drivers ", " Pilotes (Drivers) ")
	btn_d.pressed.connect(func():
		items_subtab = "drivers"
		render_current_tab()
	)
	subtab_row.add_child(btn_d)
	
	var btn_p = Button.new()
	btn_p.text = " Plugins "
	btn_p.pressed.connect(func():
		items_subtab = "plugins"
		render_current_tab()
	)
	subtab_row.add_child(btn_p)
	content.add_child(subtab_row)
	
	add_separator()
	
	var um = get_upgrade_manager()
	if um == null:
		add_label(t("Please start a run to equip and test weapons in real time.", "Veuillez lancer une partie pour équiper et tester des armes en direct."))
		return
	
	match items_subtab:
		"weapons":
			render_weapons_subtab(um)
		"drivers":
			render_drivers_subtab(um)
		"plugins":
			render_plugins_subtab(um)

func render_weapons_subtab(um: Node) -> void:
	add_label(t("Available weapons (Click to equip or level up):", "Armes disponibles (Cliquer pour équiper ou monter de niveau) :"))
	var grid = GridContainer.new()
	grid.columns = 2
	
	var weapons_list: Array = um.all_weapons if (um != null and um.get("all_weapons") != null) else []
	if weapons_list.is_empty():
		for w in ALL_WEAPONS:
			var btn = Button.new()
			btn.text = "+ %s" % w["name"]
			btn.custom_minimum_size = Vector2(215, 20)
			btn.pressed.connect(func():
				equip_weapon_by_id(w["id"])
				render_current_tab()
			)
			grid.add_child(btn)
	else:
		for w in weapons_list:
			var is_equipped: bool = (w in um.current_weapons)
			var w_name: String = str(w.name) if w.get("name") != null else str(w.id)
			var label_txt: String = ("⭐ %s [Lv+1]" % w_name) if is_equipped else ("+ %s" % w_name)
			var btn = Button.new()
			btn.text = label_txt
			btn.custom_minimum_size = Vector2(215, 20)
			btn.pressed.connect(func():
				if is_equipped:
					um.apply_silent_weapon_levels(w, 1)
					set_status(t("Level of %s increased!", "Niveau de %s augmente !") % w_name)
				else:
					um.apply_weapon(w)
					set_status(t("Weapon %s equipped!", "Arme %s equipee !") % w_name)
				render_current_tab()
			)
			grid.add_child(btn)
	content.add_child(grid)

func render_drivers_subtab(um: Node) -> void:
	add_label(t("Available drivers:", "Pilotes (Drivers) disponibles :"))
	var drivers_list: Array = um.all_drivers if (um != null and um.get("all_drivers") != null) else []
	if drivers_list.is_empty():
		add_label(t("No drivers detected in active run.", "Aucun pilote detecte dans la partie active."))
		return
	
	var grid = GridContainer.new()
	grid.columns = 2
	for d in drivers_list:
		var d_name: String = str(d.name) if d.get("name") != null else str(d.id)
		var btn = Button.new()
		btn.text = "+ %s" % d_name
		btn.custom_minimum_size = Vector2(215, 20)
		btn.pressed.connect(func():
			if d.get("weapon_id") != null:
				um.apply_driver(d, d.weapon_id)
				set_status(t("Driver %s applied!", "Driver %s applique !") % d_name)
			render_current_tab()
		)
		grid.add_child(btn)
	content.add_child(grid)

func render_plugins_subtab(um: Node) -> void:
	add_label(t("Available plugins:", "Plugins disponibles :"))
	var plugins_list: Array = um.all_plugins if (um != null and um.get("all_plugins") != null) else []
	if plugins_list.is_empty():
		add_label(t("No plugins detected in active run.", "Aucun plugin detecte dans la partie active."))
		return
	
	var grid = GridContainer.new()
	grid.columns = 2
	for p in plugins_list:
		var p_name: String = str(p.name) if p.get("name") != null else str(p.id)
		var btn = Button.new()
		btn.text = "+ %s" % p_name
		btn.custom_minimum_size = Vector2(215, 20)
		btn.pressed.connect(func():
			um.apply_plugin(p)
			set_status(t("Plugin %s applied!", "Plugin %s applique !") % p_name)
			render_current_tab()
		)
		grid.add_child(btn)
	content.add_child(grid)

# ==============================================================================
# ONGLET 3 : PROGRESSION & META
# ==============================================================================
func render_progress_tab() -> void:
	add_header_row(t("=== 📈 RUN PROGRESSION & META ===", "=== 📈 PROGRESSION DU RUN & META ==="))
	
	# Section EXP & Niveaux
	var exp_mgr = get_experience_manager()
	var cur_level: int = exp_mgr.current_level if exp_mgr != null else 1
	var cur_exp: float = exp_mgr.current_experience if exp_mgr != null else 0.0
	var tar_exp: float = exp_mgr.target_experience if exp_mgr != null else 100.0
	add_label(t("Current Level: %d  |  EXP: %d / %d", "Niveau actuel : %d  |  EXP : %d / %d") % [cur_level, roundi(cur_exp), roundi(tar_exp)])
	
	var lvl_row = HBoxContainer.new()
	add_quick_btn(lvl_row, t("+1 Level", "+1 Niveau"), func(): level_up_run(1))
	add_quick_btn(lvl_row, t("+5 Levels", "+5 Niveaux"), func(): level_up_run(5))
	add_quick_btn(lvl_row, t("+10 Levels", "+10 Niveaux"), func(): level_up_run(10))
	add_quick_btn(lvl_row, t("+25 Levels", "+25 Niveaux"), func(): level_up_run(25))
	content.add_child(lvl_row)
	
	var exp_row = HBoxContainer.new()
	add_quick_btn(exp_row, t("+100 EXP", "+100 EXP"), func(): give_run_exp(100.0))
	add_quick_btn(exp_row, t("+1,000 EXP", "+1 000 EXP"), func(): give_run_exp(1000.0))
	add_quick_btn(exp_row, t("+5,000 EXP", "+5 000 EXP"), func(): give_run_exp(5000.0))
	content.add_child(exp_row)
	
	add_separator()
	
	# Section Pièces & Clés du Run
	var cm = get_currency_manager()
	var cur_coins: float = cm.currencies.get("Coin", 0.0) if cm != null else 0.0
	var cur_keys: float = cm.currencies.get("Keys", 0.0) if cm != null else 0.0
	add_label(t("Run Resources: %.2f Coins  |  %d Keys", "Ressources du Run : %.2f Pieces  |  %d Cles") % [cur_coins, roundi(cur_keys)])
	
	var coin_row = HBoxContainer.new()
	add_quick_btn(coin_row, t("+100 Coins", "+100 Pieces"), func(): give_run_coins(100.0))
	add_quick_btn(coin_row, t("+1,000 Coins", "+1 000 Pieces"), func(): give_run_coins(1000.0))
	add_quick_btn(coin_row, t("+10,000 Coins", "+10 000 Pieces"), func(): give_run_coins(10000.0))
	content.add_child(coin_row)
	
	var key_row = HBoxContainer.new()
	add_quick_btn(key_row, t("+1 Key", "+1 Cle"), func(): give_run_keys(1.0))
	add_quick_btn(key_row, t("+5 Keys", "+5 Cles"), func(): give_run_keys(5.0))
	add_quick_btn(key_row, t("+10 Keys", "+10 Cles"), func(): give_run_keys(10.0))
	content.add_child(key_row)
	
	add_separator()
	
	# Section Meta-Progression (Beanz & Unlocks)
	var beanz_count: int = MetaProgression.get_currency() if MetaProgression != null else 0
	add_label(t("Profile Beanz (Permanent Currency): %d", "Beanz Profil (Monnaie Permanente) : %d") % beanz_count)
	
	var beanz_row = HBoxContainer.new()
	add_quick_btn(beanz_row, t("+500 Beanz", "+500 Beanz"), func(): give_beanz(500))
	add_quick_btn(beanz_row, t("+5,000 Beanz", "+5 000 Beanz"), func(): give_beanz(5000))
	add_quick_btn(beanz_row, t("+50,000 Beanz", "+50 000 Beanz"), func(): give_beanz(50000))
	content.add_child(beanz_row)
	
	var unlock_row = HBoxContainer.new()
	var btn_unlock = Button.new()
	btn_unlock.text = t("🔓 Unlock All Content (Weapons, Items, Themes)", "🔓 Debloquer Tout le Contenu (Armes, Objets, Thèmes)")
	btn_unlock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_unlock.pressed.connect(func():
		unlock_all_content()
	)
	unlock_row.add_child(btn_unlock)
	content.add_child(unlock_row)

# ==============================================================================
# ONGLET 4 : TRICHE & TESTS
# ==============================================================================
func render_cheats_tab() -> void:
	add_header_row(t("=== ⚡ CHEATS & IN-GAME TESTING ===", "=== ⚡ TRICHE & TESTS IN-GAME ==="))
	
	# God Mode
	var is_god: bool = (GameEvents != null and GameEvents.get("debug_god_mode") == true)
	var god_txt: String = t(
		"🛡️ GOD MODE (INVULNERABILITY): ENABLED [ON]" if is_god else "🛡️ GOD MODE (INVULNERABILITY): DISABLED [OFF]",
		"🛡️ INVULNERABILITE (GOD MODE) : ACTIVE [ON]" if is_god else "🛡️ INVULNERABILITE (GOD MODE) : DESACTIVE [OFF]"
	)
	var btn_god = Button.new()
	btn_god.text = god_txt
	btn_god.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_god.pressed.connect(func():
		toggle_god_mode()
		render_current_tab()
	)
	content.add_child(btn_god)
	
	# Kill all enemies
	var btn_nuke = Button.new()
	btn_nuke.text = t("💣 KILL ALL ENEMIES (NUKE)", "💣 NETTOYER TOUS LES ENNEMIS (KILL ALL)")
	btn_nuke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_nuke.pressed.connect(func():
		kill_all_enemies()
		set_status(t("All enemies have been eliminated!", "Tous les ennemis ont ete elimines !"))
	)
	content.add_child(btn_nuke)
	
	add_separator()
	
	# Vitesse du jeu
	var current_spd: float = GameEvents.gameplay_time_scale if (GameEvents != null and GameEvents.get("gameplay_time_scale") != null) else Engine.time_scale
	add_label(t("Game Speed (Time Scale): current = %.2fx", "Vitesse du jeu (Game Time Scale) : actuelle = %.2fx") % current_spd)
	var speed_row = HBoxContainer.new()
	add_quick_btn(speed_row, "x0.25", func(): set_game_speed(0.25))
	add_quick_btn(speed_row, "x0.5", func(): set_game_speed(0.5))
	add_quick_btn(speed_row, "x1.0", func(): set_game_speed(1.0))
	add_quick_btn(speed_row, "x1.5", func(): set_game_speed(1.5))
	add_quick_btn(speed_row, "x2.0", func(): set_game_speed(2.0))
	add_quick_btn(speed_row, "x3.0", func(): set_game_speed(3.0))
	add_quick_btn(speed_row, "x5.0", func(): set_game_speed(5.0))
	content.add_child(speed_row)
	
	add_separator()
	
	# Contrôle des Vagues et Boss
	add_label(t("Wave & Objective Controls:", "Gestion des Vagues & Objectifs :"))
	var wave_row = HBoxContainer.new()
	add_quick_btn(wave_row, t("⏩ Finish Wave Timer", "⏩ Finir Timer Vague"), func(): finish_arena_timer())
	add_quick_btn(wave_row, t("📁 Spawn Safe Folder", "📁 Spawn Safe Folder"), func(): spawn_safe_folder())
	content.add_child(wave_row)
	
	var round_row = HBoxContainer.new()
	for r in range(1, 6):
		add_quick_btn(round_row, "Round %d" % r, func(): set_battle_round(r))
	content.add_child(round_row)
	
	add_label(t("Spawn a Boss:", "Invoquer un Boss :"))
	var boss_row = HBoxContainer.new()
	add_quick_btn(boss_row, "Beach Ball", func(): spawn_boss("res://scenes/game_object/bosses/beachball_boss/beachball_boss.tscn"))
	add_quick_btn(boss_row, "Recycle Bin", func(): spawn_boss("res://scenes/game_object/bosses/recycle_bin_boss/recycle_bin_boss.tscn"))
	add_quick_btn(boss_row, "Caesar Chimp", func(): spawn_boss("res://scenes/game_object/bosses/bonzi_boss/bonzi_boss.tscn"))
	content.add_child(boss_row)
	
	add_separator()
	
	# Faire spawn des fichiers cliquables
	add_label(t("Spawn a File:", "Faire apparaitre un fichier :"))
	var file_grid = GridContainer.new()
	file_grid.columns = 3
	for f in CLICKABLE_FILE_PATHS:
		var btn_f = Button.new()
		btn_f.text = f["name"]
		btn_f.custom_minimum_size = Vector2(135, 20)
		btn_f.pressed.connect(func():
			spawn_clickable_file(f["path"], f["name"])
		)
		file_grid.add_child(btn_f)
	content.add_child(file_grid)

# ==============================================================================
# ACTIONS DU TRAINER
# ==============================================================================
func adjust_stat(stat_id: String, delta: float) -> void:
	if StatsManager == null:
		return
	var current: float = StatsManager.stat_upgrades_flat.get(stat_id, 0.0)
	StatsManager.stat_upgrades_flat[stat_id] = current + delta
	StatsManager.update_stats()
	set_status(t("Stat %s : %.2f", "Stat %s : %.2f") % [stat_id, StatsManager.final_stats.get(stat_id, 0.0)])

func reset_stat(stat_id: String) -> void:
	if StatsManager == null:
		return
	StatsManager.stat_upgrades_flat[stat_id] = 0.0
	StatsManager.stat_upgrades_additive[stat_id] = 0.0
	StatsManager.stat_upgrades_multiplicative[stat_id] = 1.0
	StatsManager.update_stats()
	set_status(t("Stat %s reset!", "Stat %s reinitialisee !") % stat_id)

func buff_all_stats(factor: float) -> void:
	if StatsManager == null:
		return
	for item in STAT_DEFINITIONS:
		var sid: String = item["id"]
		var is_m: bool = item["is_mult"]
		if is_m:
			var cur_m: float = StatsManager.stat_upgrades_multiplicative.get(sid, 1.0)
			StatsManager.stat_upgrades_multiplicative[sid] = cur_m + factor
		else:
			var cur_f: float = StatsManager.stat_upgrades_flat.get(sid, 0.0)
			StatsManager.stat_upgrades_flat[sid] = cur_f + (factor * 10.0)
	StatsManager.update_stats()

func reset_all_stats() -> void:
	if StatsManager == null:
		return
	StatsManager.stat_upgrades_flat.clear()
	StatsManager.stat_upgrades_additive.clear()
	StatsManager.stat_upgrades_multiplicative.clear()
	StatsManager.update_stats()

func get_player() -> Node:
	if GameEvents != null and GameEvents.main != null and is_instance_valid(GameEvents.main.get_node_or_null("%Player")):
		return GameEvents.main.get_node_or_null("%Player")
	return get_tree().get_first_node_in_group("player")

func get_upgrade_manager() -> Node:
	if GameEvents != null and GameEvents.main != null and is_instance_valid(GameEvents.main.upgrade_manager):
		return GameEvents.main.upgrade_manager
	return get_tree().get_first_node_in_group("upgrade_manager")

func get_experience_manager() -> Node:
	if GameEvents != null and GameEvents.main != null and is_instance_valid(GameEvents.main.experience_manager):
		return GameEvents.main.experience_manager
	return get_tree().get_first_node_in_group("experience_manager")

func get_currency_manager() -> Node:
	if GameEvents != null and GameEvents.main != null and is_instance_valid(GameEvents.main.game_currency_manager):
		return GameEvents.main.game_currency_manager
	return get_tree().get_first_node_in_group("game_currency_manager")

func heal_player_full() -> void:
	var player = get_player()
	if player != null and player.health_component != null:
		var missing: float = player.health_component.max_health - player.health_component.current_health
		if missing > 0:
			player.health_component.heal(int(missing))
			set_status(t("Player fully healed (+%d HP)!", "Joueur soigne a 100% (+%d HP) !") % missing)
		else:
			set_status(t("Player already at full health.", "Joueur deja au maximum de points de vie."))

func modify_player_current_hp(delta: float) -> void:
	var player = get_player()
	if player != null and player.health_component != null:
		if delta > 0:
			player.health_component.heal(int(delta))
			set_status("+%d HP" % delta)
		else:
			player.health_component.damage(abs(delta), "debug", true)
			set_status("%d HP" % delta)

func equip_weapon_by_id(weapon_id: String) -> void:
	var um = get_upgrade_manager()
	if um == null:
		set_status(t("Action unavailable: not in a run.", "Action impossible : non en partie."))
		return
	for w in um.all_weapons:
		if w.id == weapon_id:
			if w in um.current_weapons:
				um.apply_silent_weapon_levels(w, 1)
				set_status(t("%s leveled up!", "%s monte au niveau superieur !") % w.name)
			else:
				um.apply_weapon(w)
				set_status(t("%s equipped successfully!", "%s equipe avec succes !") % w.name)
			return
	set_status(t("Weapon not found: %s", "Arme introuvable : %s") % weapon_id)

func level_up_run(levels: int) -> void:
	var exp_mgr = get_experience_manager()
	if exp_mgr == null:
		set_status(t("Action unavailable: not in a run.", "Action impossible : non en partie."))
		return
	if exp_mgr.has_method("grant_levels"):
		exp_mgr.grant_levels(levels)
	else:
		exp_mgr.current_level += levels
		exp_mgr.experience_updated.emit(exp_mgr.current_experience, exp_mgr.target_experience)
	set_status(t("+%d levels granted!", "+%d niveaux accordes !") % levels)
	render_current_tab()

func give_run_exp(amount: float) -> void:
	var exp_mgr = get_experience_manager()
	if exp_mgr == null:
		set_status(t("Action unavailable: not in a run.", "Action impossible : non en partie."))
		return
	if exp_mgr.has_method("increment_experience"):
		exp_mgr.increment_experience(amount)
	elif GameEvents != null and GameEvents.has_signal("experience_vial_collected"):
		GameEvents.experience_vial_collected.emit(amount)
	set_status(t("+%d EXP added!", "+%d EXP ajoutee !") % amount)
	render_current_tab()

func give_run_coins(amount: float) -> void:
	var cm = get_currency_manager()
	if cm != null:
		var cur: float = cm.currencies.get("Coin", 0.0)
		var new_val: float = cur + amount
		cm.currencies["Coin"] = new_val
		cm.total_coins_collected += amount
		cm.currency_collected.emit("Coin", new_val)
	elif GameEvents != null and GameEvents.has_signal("currency_collected"):
		GameEvents.currency_collected.emit("Coin", amount, true, false)
	set_status(t("+%d coins granted!", "+%d pieces accordees !") % amount)
	render_current_tab()

func give_run_keys(amount: float) -> void:
	var cm = get_currency_manager()
	if cm != null:
		var cur: float = cm.currencies.get("Keys", 0.0)
		var new_val: float = cur + amount
		cm.currencies["Keys"] = new_val
		cm.total_keys_collected += int(amount)
		cm.currency_collected.emit("Keys", new_val)
	elif GameEvents != null and GameEvents.has_signal("currency_collected"):
		GameEvents.currency_collected.emit("Keys", amount, true, false)
	set_status(t("+%d keys granted!", "+%d cles accordees !") % amount)
	render_current_tab()

func give_beanz(amount: int) -> void:
	var new_total: int = 0
	if SaveManager != null and SaveManager.profile != null:
		if not SaveManager.profile.has("currency") or not (SaveManager.profile["currency"] is Dictionary):
			SaveManager.profile["currency"] = {}
		var cur: int = int(SaveManager.profile["currency"].get("beanz", 0))
		new_total = cur + amount
		SaveManager.profile["currency"]["beanz"] = new_total
		SaveManager.save_profile()
		if MetaProgression != null and MetaProgression.has_signal("currency_updated"):
			MetaProgression.currency_updated.emit(new_total)
	
	var cm = get_currency_manager()
	if cm != null:
		var run_cur: float = cm.currencies.get("Beanz", 0.0)
		var run_new: float = run_cur + amount
		cm.currencies["Beanz"] = run_new
		cm.total_beanz_collected += amount
		cm.currency_collected.emit("Beanz", run_new)
	
	set_status(t("+%d Beanz added to profile & run!", "+%d Beanz ajoutes au profil & run !") % amount)
	render_current_tab()

func unlock_all_content() -> void:
	if UnlockManager == null or SaveManager == null:
		set_status(t("Manager unavailable.", "Gestionnaire inaccessible."))
		return
	UnlockManager.debug_unlock_all = true
	var u = UnlockManager.unlocks()
	var p = UnlockManager.purchases()
	var d = UnlockManager.disabled_content()
	if UnlockManager.get("by_id") != null:
		for id_key in UnlockManager.by_id.keys():
			u[id_key] = true
			p[id_key] = true
			d.erase(id_key)
			UnlockManager.unlocked.emit(id_key)
	SaveManager.save_profile()
	UnlockManager.purchases_changed.emit("")
	set_status(t("All content (weapons, items, themes) has been unlocked!", "Tout le contenu (armes, objets, themes) a ete debloque !"))
	render_current_tab()

func toggle_god_mode() -> void:
	if GameEvents == null:
		return
	var cur = GameEvents.get("debug_god_mode") == true
	GameEvents.set("debug_god_mode", not cur)
	var player = get_player()
	if player != null and player.health_component != null:
		if not cur:
			player.health_component.current_health = player.health_component.max_health
	set_status(t("God Mode = %s", "God Mode = %s") % str(not cur))

func kill_all_enemies() -> void:
	if GameEvents != null and GameEvents.main != null and GameEvents.main.enemy_manager != null:
		var em = GameEvents.main.enemy_manager
		for agent in em.all_agents.duplicate():
			if is_instance_valid(agent) and agent.has_node("HealthComponent"):
				var hc = agent.get_node("HealthComponent")
				hc.damage(hc.max_health * 100.0, "debug")
		em.clear_elite_tracking()
	for node in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(node):
			var hc = node.get_node_or_null("HealthComponent")
			if hc != null:
				hc.damage(999999.0, "debug")
			else:
				node.queue_free()

func finish_arena_timer() -> void:
	if GameEvents != null and GameEvents.main != null and GameEvents.main.arena_time_manager != null:
		GameEvents.main.arena_time_manager._on_timer_timeout()
		set_status(t("Arena timer finished!", "Timer d'arene termine !"))
		close()

func spawn_safe_folder() -> void:
	if GameEvents != null and GameEvents.main != null and GameEvents.main.round_manager != null:
		var sf = load("res://scenes/game_object/clickables/safe_folder/safe_folder.tscn")
		if sf != null:
			GameEvents.main.round_manager.spawn_end_objective(sf, false)
			set_status(t("Safe Folder spawned on map!", "Safe Folder apparu sur la carte !"))
			close()

func set_battle_round(round_num: int) -> void:
	if GameEvents != null and GameEvents.main != null and GameEvents.main.round_manager != null:
		GameEvents.main.round_manager.current_battle_round = float(round_num)
		set_status(t("Round set to %d!", "Round regle a %d !") % round_num)

func spawn_boss(path: String) -> void:
	if GameEvents != null and GameEvents.main != null and GameEvents.main.round_manager != null:
		var scene: PackedScene = load(path) as PackedScene
		if scene != null:
			GameEvents.main.round_manager.begin_boss_phase(scene)
			set_status(t("Boss phase started!", "Phase de Boss lancee !"))
			close()

func spawn_clickable_file(path: String, fname: String) -> void:
	var icons_layer: Node2D = get_tree().get_first_node_in_group("icons_layer") as Node2D
	var player = get_player()
	if icons_layer == null or player == null:
		set_status(t("Action unavailable: not in a run.", "Action impossible : non en partie."))
		return
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		set_status(t("Scene not found: %s", "Scene introuvable : %s") % path)
		return
	var inst: Node2D = scene.instantiate() as Node2D
	if inst != null:
		inst.global_position = player.global_position + Vector2(randf_range(-70, 70), randf_range(-70, 70))
		icons_layer.add_child(inst)
		set_status(t("File %s spawned nearby!", "Fichier %s genere a proximite !") % fname)

func set_game_speed(scale_val: float) -> void:
	Engine.time_scale = scale_val
	if GameEvents != null:
		GameEvents.gameplay_time_scale = scale_val
	set_status(t("Game Speed = %.2fx", "Vitesse jeu = %.2fx") % scale_val)
	render_current_tab()

# ==============================================================================
# HELPERS UI
# ==============================================================================
func add_header_row(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.theme_type_variation = &"FuzzyType"
	content.add_child(lbl)

func add_label(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	content.add_child(lbl)

func add_separator() -> void:
	var div = HSeparator.new()
	content.add_child(div)

func add_quick_btn(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(callback)
	parent.add_child(btn)
