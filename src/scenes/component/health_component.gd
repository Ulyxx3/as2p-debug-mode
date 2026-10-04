extends Node

class_name HealthComponent

signal died
signal health_changed
signal health_decreased(amt: float)
signal health_increased(amt: float)

@export var max_health: float = 10
var current_health: float
var enemy_manager: EnemyManager
var already_dead: bool = false
var claimed_healing: int = 0
var last_damaging_weapon_id: String = ""
var suppress_damage_number: bool = false


func _ready() -> void :
	current_health = max_health
	enemy_manager = get_tree().get_first_node_in_group("enemy_manager")


func damage(damage_amount: float, weapon_id: String = "", ignore_block: bool = false) -> void :
	var host: Node = get_parent()
	if damage_amount > 0 and host != null and host.is_in_group("player") and GameEvents.debug_god_mode:
		suppress_damage_number = false
		return
	if (
		damage_amount > 0
		and not ignore_block
		and host != null
		and host.has_method("blocks_damage")
		and host.blocks_damage()
	):
		suppress_damage_number = false
		return
	if damage_amount > 0 and host != null and host.has_method("damage_taken_multiplier"):
		damage_amount *= host.damage_taken_multiplier()
	var previous_health: float = current_health
	current_health = clamp(current_health - damage_amount, 0, max_health)
	health_changed.emit()
	if damage_amount > 0:
		last_damaging_weapon_id = weapon_id
		health_decreased.emit(damage_amount)
	elif damage_amount < 0:
		suppress_damage_number = false
		health_increased.emit(damage_amount)
		var healed: int = floori(current_health - previous_health)
		if healed > 0 and get_parent().is_in_group("player"):
			StatTracker.add("hp_healed", healed)
	else:
		suppress_damage_number = false
	Callable(check_death).call_deferred()


func heal(heal_amount: int) -> void :
	damage( - heal_amount)


func set_max_health(new_max: float) -> void :
	var old_max: float = max_health
	var old_current: float = current_health
	max_health = new_max
	if new_max > old_max:
		current_health += new_max - old_max
	current_health = clampf(current_health, 0.0, max_health)
	if is_equal_approx(max_health, old_max) and is_equal_approx(current_health, old_current):
		return
	health_changed.emit()
	if max_health <= 0.0:
		Callable(check_death).call_deferred()


func get_health_percent() -> float:
	if max_health <= 0:
		return 0
	return min(current_health / max_health, 1)


func check_death() -> void :
	if current_health > 0 or already_dead:
		return
	if try_player_revive():
		return
	already_dead = true
	died.emit()


func try_player_revive() -> bool:
	var host: Node = get_parent()
	if host == null or not host.is_in_group("player"):
		return false
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	for node: Node in tree.get_nodes_in_group("system_restore_plugin"):
		if node.try_revive(self):
			return true
	return false


func reset_for_pool() -> void :
	already_dead = false
	claimed_healing = 0
	last_damaging_weapon_id = ""
	suppress_damage_number = false


func prepare_for_spawn(max_hp: float) -> void :
	max_health = max_hp
	current_health = max_hp
	reset_for_pool()
	health_changed.emit()


func get_missing_health() -> int:
	return int(max_health - current_health)


func can_claim_healing() -> bool:
	return current_health + claimed_healing < max_health


func claim_healing() -> bool:
	if can_claim_healing():
		claimed_healing += 1
		return true
	return false


func confirm_healing(amount: int = 1) -> void :
	claimed_healing = max(claimed_healing - amount, 0)
