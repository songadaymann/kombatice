extends Node2D

# Debug options
var debug_show_positions: bool = false
var debug_show_beat_info: bool = false  # Set to true to show beat/timing info at top
var debug_placement_mode: bool = false  # Press P to toggle, then click to place ice target

# References to nodes
@onready var intro_video: VideoStreamPlayer = $IntroVideo
@onready var level_background: Sprite2D = $LevelBackground
@onready var agent: AnimatedSprite2D = $Agent
@onready var sub_zero: AnimatedSprite2D = $SubZero
@onready var ice_projectile: AnimatedSprite2D = $IceProjectile
@onready var score_label: Label = $UI/ScoreLabel
@onready var timing_label: Label = $UI/TimingLabel
@onready var position_animator: AnimationPlayer = $PositionAnimator
@onready var beat_indicator: Node2D = $BeatIndicator
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var end_panel: Panel = $UI/EndPanel
@onready var end_label: Label = $UI/EndPanel/EndLabel

# Level textures (loaded at runtime)
var level_textures: Array[Texture2D] = []
var current_level_index: int = 0
const TOTAL_LEVELS: int = 24

# Agent animation
const AGENT_FRAME_START: int = 108958
const AGENT_FRAME_COUNT: int = 100
const AGENT_FPS: float = 30.0

# Game state
var score: int = 0
var is_intro: bool = true  # First playthrough is intro (no gameplay)
var can_shoot: bool = false
var has_shot_this_cycle: bool = false  # Track if player has shot this 8-beat cycle
var game_started: bool = false
var game_over: bool = false
var game_time: float = 0.0  # Track time manually for beat sync
var intro_special_triggered: bool = false  # Track if we've triggered the intro special animation

# Result tracking
var perfect_count: int = 0
var good_count: int = 0
var ok_count: int = 0
var miss_count: int = 0

# Varied feedback messages
const PERFECT_MESSAGES: Array[String] = ["PERFECT!", "FLAWLESS!", "TOASTY!", "EXCELLENT!"]
const GOOD_MESSAGES: Array[String] = ["GOOD!", "NICE!", "SOLID!", "WELL DONE!"]
const OK_MESSAGES: Array[String] = ["OK", "ALMOST!", "CLOSE!", "NOT BAD"]
const MISS_MESSAGES: Array[String] = ["MISS", "TOO SLOW!", "TRY AGAIN!", "NOPE!"]

# Intro SubZero scale (smaller than gameplay)
const SUBZERO_INTRO_SCALE: Vector2 = Vector2(5, 5)
const SUBZERO_GAMEPLAY_SCALE: Vector2 = Vector2(7, 7)

# ===== BEAT TRACKING =====
@export var bpm: float = 144.0
@export var beats_per_cycle: int = 8  # Target beat every 8 beats
@export var first_target_beat: int = 5  # Which beat in the cycle is the target (1-8)
@export var first_beat_offset: float = 0.0  # Time in seconds from audio start to beat 1 (music has no lead-in)
@export var audio_offset: float = 0.0  # Additional calibration offset (for system latency)

var seconds_per_beat: float
var current_beat: int = -1
var current_cycle: int = -1

# Fixed positions for gameplay phase (set these in Inspector or here)
@export var subzero_gameplay_pos: Vector2 = Vector2(200, 1400)
@export var ice_target_pos: Vector2 = Vector2(792, 1750)

# Timing tolerances (in beats)
const PERFECT_WINDOW_BEATS: float = 0.15  # ~62ms at 144 BPM
const GOOD_WINDOW_BEATS: float = 0.3      # ~125ms
const OK_WINDOW_BEATS: float = 0.5        # ~208ms

# Game duration
const GAME_END_TIME: float = 95.0  # Show end screen at 1:35

# Camera shake
var shake_amount: float = 0.0
var shake_decay: float = 0.9
const SHAKE_MISS: float = 15.0
const SHAKE_OK: float = 5.0

func _ready() -> void:
	# Initialize beat tracking
	seconds_per_beat = 60.0 / bpm

	# Load level textures
	for i in range(1, TOTAL_LEVELS + 1):
		var path = "res://assets/levels/level%d.jpeg" % i
		var tex = load(path)
		if tex:
			level_textures.append(tex)
		else:
			print("Warning: Could not load level texture: %s" % path)

	print("Loaded %d level textures" % level_textures.size())

	# Load agent animation frames
	if agent:
		var sprite_frames = SpriteFrames.new()
		sprite_frames.add_animation("default")
		sprite_frames.set_animation_speed("default", AGENT_FPS)
		sprite_frames.set_animation_loop("default", true)

		for i in range(AGENT_FRAME_COUNT):
			var frame_num = AGENT_FRAME_START + i
			var path = "res://assets/agent/agent_%08d.png" % frame_num
			var tex = load(path)
			if tex:
				sprite_frames.add_frame("default", tex)

		agent.sprite_frames = sprite_frames
		print("Loaded %d agent frames" % sprite_frames.get_frame_count("default"))

	# Start Sub-Zero in idle animation
	if sub_zero and sub_zero.sprite_frames:
		sub_zero.play("idle")

	# Hide gameplay elements during intro
	ice_projectile.visible = false

	# Hide beat indicator during intro
	if beat_indicator:
		beat_indicator.visible = false

	# Set initial level background
	if level_textures.size() > 0 and level_background:
		level_background.texture = level_textures[0]

	# Start intro sequence
	_start_intro()

func _start_intro() -> void:
	is_intro = true
	can_shoot = false
	intro_special_triggered = false

	# Set SubZero to smaller intro scale
	if sub_zero:
		sub_zero.scale = SUBZERO_INTRO_SCALE

	# Show intro video, hide gameplay elements
	if intro_video:
		intro_video.visible = true
		intro_video.play()
		intro_video.finished.connect(_on_intro_video_finished, CONNECT_ONE_SHOT)

	if level_background:
		level_background.visible = false

	# Play the Sub-Zero position animation for intro
	if position_animator:
		position_animator.play("subzero_animation")

	# Hide agent during intro
	if agent:
		agent.visible = false

	# Hide debug label during intro
	if score_label:
		score_label.visible = false

func _on_intro_video_finished() -> void:
	print("Intro video finished!")
	_start_gameplay()

func _on_intro_finished(_anim_name: String) -> void:
	print("Intro finished! Starting gameplay...")
	_start_gameplay()

func _start_gameplay() -> void:
	is_intro = false
	can_shoot = true
	game_started = true
	game_time = 0.0

	# Hide intro video, show level background
	if intro_video:
		intro_video.visible = false
		intro_video.stop()

	if level_background:
		level_background.visible = true

	# Stop position animator and move Sub-Zero to fixed gameplay position
	if position_animator:
		position_animator.stop()
	sub_zero.position = subzero_gameplay_pos

	# Restore SubZero to gameplay scale
	if sub_zero:
		sub_zero.scale = SUBZERO_GAMEPLAY_SCALE
		sub_zero.play("idle")

	# Show agent and start its animation
	if agent:
		agent.visible = true
		agent.play("default")

	# Show beat indicator
	if beat_indicator:
		beat_indicator.visible = true
		beat_indicator.reset()

	# Reset beat tracking
	current_beat = -1
	current_cycle = -1
	current_level_index = 0

	# Set first level
	if level_textures.size() > 0 and level_background:
		level_background.texture = level_textures[0]

	# Start music
	if audio_player and audio_player.stream:
		audio_player.play()

# Frame 44 at 30fps = ~1.47 seconds
const INTRO_SPECIAL_TRIGGER_TIME: float = 1.47

# Store original position for camera shake
var original_position: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	# Apply camera shake
	if shake_amount > 0.1:
		position = original_position + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount *= shake_decay
	elif shake_amount > 0:
		shake_amount = 0
		position = original_position
	# Handle intro video special animation trigger
	if is_intro and intro_video and intro_video.is_playing():
		var current_time = intro_video.stream_position
		if not intro_special_triggered and current_time >= INTRO_SPECIAL_TRIGGER_TIME:
			intro_special_triggered = true
			if sub_zero:
				sub_zero.play("attack")
				# Return to idle after attack animation
				await sub_zero.animation_finished
				if is_intro:  # Only if still in intro
					sub_zero.play("idle")

	if not game_started or game_over:
		return

	# Update game time (use audio position if available, otherwise track manually)
	if audio_player and audio_player.playing:
		game_time = audio_player.get_playback_position() + audio_offset
	else:
		game_time += delta

	# Check if we've reached the end time (music keeps playing)
	if game_time >= GAME_END_TIME and not game_over:
		_show_end_screen()
		return

	# Adjust for first beat offset (time from audio start to beat 1)
	var adjusted_time = game_time - first_beat_offset
	if adjusted_time < 0:
		return  # Haven't reached beat 1 yet

	# Calculate current beat (0-indexed)
	var beat_float = adjusted_time / seconds_per_beat
	var new_beat = int(beat_float)

	# Calculate position within the 8-beat cycle (1-8)
	var beat_in_cycle = (new_beat % beats_per_cycle) + 1
	var new_cycle = int(new_beat / beats_per_cycle)

	# Detect beat change
	if new_beat != current_beat:
		current_beat = new_beat
		_on_beat(current_beat, beat_in_cycle)

	# Detect new cycle (change level, reset shot availability)
	if new_cycle != current_cycle:
		current_cycle = new_cycle
		has_shot_this_cycle = false
		_on_new_cycle(new_cycle)

	# Update beat indicator ring animation
	# Ring should be flush (progress=1) exactly ON the target beat
	if beat_indicator:
		var beat_in_cycle_float = fmod(beat_float, float(beats_per_cycle))
		var target_beat_0indexed = float(first_target_beat - 1)
		var beats_until_target = fmod(target_beat_0indexed - beat_in_cycle_float + float(beats_per_cycle), float(beats_per_cycle))
		var progress = 1.0 - (beats_until_target / float(beats_per_cycle))
		beat_indicator.set_ring_progress(progress)

	# Debug info
	if debug_show_beat_info:
		var beats_until_target = first_target_beat - beat_in_cycle
		if beats_until_target <= 0:
			beats_until_target += beats_per_cycle
		score_label.text = "Beat: %d | Cycle: %d/8 | Level: %d | Target in: %d" % [current_beat, beat_in_cycle, current_level_index + 1, beats_until_target]

func _on_beat(_beat: int, beat_in_cycle: int) -> void:
	# Pulse the inner circle on every beat
	if beat_indicator:
		beat_indicator.pulse()

	# Check if this is a target beat
	if beat_in_cycle == first_target_beat:
		_on_target_beat(_beat)

func _on_target_beat(_beat: int) -> void:
	if debug_show_beat_info:
		print("TARGET BEAT! Beat #%d" % _beat)

func _on_new_cycle(cycle: int) -> void:
	# Reset ice projectile for new cycle
	if ice_projectile:
		ice_projectile.visible = false

	# Change to next level background
	if level_textures.size() > 0 and level_background:
		current_level_index = cycle % level_textures.size()
		level_background.texture = level_textures[current_level_index]
		if debug_show_beat_info:
			print("Level changed to: %d" % (current_level_index + 1))

var placing_subzero: bool = false

func _input(event: InputEvent) -> void:
	# Toggle placement mode with P key
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		debug_placement_mode = !debug_placement_mode
		placing_subzero = false
		print("Placement mode: %s" % ("ON - click to place ICE TARGET (red)" if debug_placement_mode else "OFF"))
		queue_redraw()

	# Toggle debug beat info with D key
	if event is InputEventKey and event.pressed and event.keycode == KEY_D:
		debug_show_beat_info = !debug_show_beat_info
		if score_label:
			score_label.visible = debug_show_beat_info
		print("Debug beat info: %s" % ("ON" if debug_show_beat_info else "OFF"))

	# Print current timing info with T key (for calibration)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and game_started:
		var adjusted_time = game_time - first_beat_offset
		var beat_float = adjusted_time / seconds_per_beat
		print("=== TIMING DEBUG ===")
		print("Raw audio time: %.3f" % game_time)
		print("Adjusted time: %.3f" % adjusted_time)
		print("Beat (float): %.3f" % beat_float)
		print("Beat (int): %d" % int(beat_float))
		print("Position in cycle: %d/8" % ((int(beat_float) % beats_per_cycle) + 1))
		print("first_beat_offset: %.3f" % first_beat_offset)
		print("====================")

	# Toggle what we're placing with S key
	if event is InputEventKey and event.pressed and event.keycode == KEY_S and debug_placement_mode:
		placing_subzero = !placing_subzero
		print("Now placing: %s" % ("SUB-ZERO position (cyan)" if placing_subzero else "ICE TARGET (red)"))

	# In placement mode, click to set position
	if debug_placement_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		if placing_subzero:
			subzero_gameplay_pos = click_pos
			sub_zero.position = subzero_gameplay_pos
			print("Sub-Zero position set to: Vector2(%d, %d)" % [int(subzero_gameplay_pos.x), int(subzero_gameplay_pos.y)])
		else:
			ice_target_pos = click_pos
			print("Ice target position set to: Vector2(%d, %d)" % [int(ice_target_pos.x), int(ice_target_pos.y)])
		queue_redraw()

	# Shoot ice
	if event.is_action_pressed("shoot_ice") and can_shoot and not has_shot_this_cycle and not debug_placement_mode:
		shoot_ice()

	# Skip intro with spacebar
	if event.is_action_pressed("shoot_ice") and is_intro:
		if position_animator:
			position_animator.stop()
		if intro_video:
			intro_video.stop()
		_start_gameplay()

	# Restart game from end screen
	if event.is_action_pressed("shoot_ice") and game_over:
		_reset_game()

func _draw() -> void:
	if debug_placement_mode or debug_show_positions:
		var target_thickness = 5 if (debug_placement_mode and not placing_subzero) else 2
		var target_color = Color.RED
		draw_line(ice_target_pos + Vector2(-40, 0), ice_target_pos + Vector2(40, 0), target_color, target_thickness)
		draw_line(ice_target_pos + Vector2(0, -40), ice_target_pos + Vector2(0, 40), target_color, target_thickness)
		draw_circle(ice_target_pos, 25, Color(1, 0, 0, 0.3))

		var sz_thickness = 5 if (debug_placement_mode and placing_subzero) else 2
		var sz_color = Color.CYAN
		draw_line(subzero_gameplay_pos + Vector2(-40, 0), subzero_gameplay_pos + Vector2(40, 0), sz_color, sz_thickness)
		draw_line(subzero_gameplay_pos + Vector2(0, -40), subzero_gameplay_pos + Vector2(0, 40), sz_color, sz_thickness)
		draw_circle(subzero_gameplay_pos, 25, Color(0, 1, 1, 0.3))

func shoot_ice() -> void:
	has_shot_this_cycle = true

	# Use adjusted time for beat calculation
	var adjusted_time = game_time - first_beat_offset
	var beat_float = adjusted_time / seconds_per_beat

	sub_zero.play("attack")
	fire_projectile()

	var timing_result = check_timing_beats(beat_float)
	display_timing_feedback(timing_result)

	await sub_zero.animation_finished
	sub_zero.play("idle")

func fire_projectile() -> void:
	ice_projectile.position = sub_zero.position + Vector2(50, -50)
	ice_projectile.visible = true
	ice_projectile.play("fly")

	print("Firing ice from %s to %s" % [ice_projectile.position, ice_target_pos])

	var tween = create_tween()
	tween.tween_property(ice_projectile, "position", ice_target_pos, 0.5)

func check_timing_beats(current_beat_float: float) -> String:
	var target_beat_offset = first_target_beat - 1
	var cycle_position = fmod(current_beat_float - target_beat_offset, float(beats_per_cycle))
	if cycle_position < 0:
		cycle_position += beats_per_cycle

	var diff = min(cycle_position, beats_per_cycle - cycle_position)

	if debug_show_beat_info:
		print("Shot at beat %.2f, distance to target: %.2f beats" % [current_beat_float, diff])

	if diff <= PERFECT_WINDOW_BEATS:
		score += 100
		perfect_count += 1
		return "perfect"
	elif diff <= GOOD_WINDOW_BEATS:
		score += 50
		good_count += 1
		return "good"
	elif diff <= OK_WINDOW_BEATS:
		score += 25
		ok_count += 1
		return "ok"
	else:
		miss_count += 1
		return "miss"

func display_timing_feedback(result: String) -> void:
	timing_label.modulate.a = 1.0

	# Show feedback on beat indicator
	if beat_indicator:
		beat_indicator.show_feedback(result)

	match result:
		"perfect":
			timing_label.text = PERFECT_MESSAGES[randi() % PERFECT_MESSAGES.size()]
			timing_label.modulate = Color.GOLD
		"good":
			timing_label.text = GOOD_MESSAGES[randi() % GOOD_MESSAGES.size()]
			timing_label.modulate = Color.GREEN
		"ok":
			timing_label.text = OK_MESSAGES[randi() % OK_MESSAGES.size()]
			timing_label.modulate = Color.CYAN
			shake_amount = SHAKE_OK
		"miss":
			timing_label.text = MISS_MESSAGES[randi() % MISS_MESSAGES.size()]
			timing_label.modulate = Color.RED
			shake_amount = SHAKE_MISS

	var tween = create_tween()
	tween.tween_property(timing_label, "modulate:a", 0.0, 0.5)

func update_score() -> void:
	score_label.text = "Score: %d" % score

func _show_end_screen() -> void:
	game_over = true
	can_shoot = false

	# Hide gameplay elements
	if beat_indicator:
		beat_indicator.visible = false
	if ice_projectile:
		ice_projectile.visible = false

	# Calculate total attempts and percentage
	var total_shots = perfect_count + good_count + ok_count + miss_count
	var accuracy = 0.0
	if total_shots > 0:
		accuracy = float(perfect_count + good_count) / float(total_shots) * 100.0

	# Build end screen text
	var end_text = "FINISH HIM!\n\n"
	end_text += "SCORE: %d\n\n" % score
	end_text += "PERFECT: %d\n" % perfect_count
	end_text += "GOOD: %d\n" % good_count
	end_text += "OK: %d\n" % ok_count
	end_text += "MISS: %d\n\n" % miss_count
	end_text += "ACCURACY: %.0f%%\n\n" % accuracy
	end_text += "PRESS SPACE TO PLAY AGAIN"

	if end_label:
		end_label.text = end_text
	if end_panel:
		end_panel.visible = true

func _reset_game() -> void:
	# Stop music
	if audio_player:
		audio_player.stop()

	# Reset all tracking
	score = 0
	perfect_count = 0
	good_count = 0
	ok_count = 0
	miss_count = 0
	game_over = false
	game_started = false
	current_beat = -1
	current_cycle = -1
	current_level_index = 0
	has_shot_this_cycle = false

	# Hide end panel
	if end_panel:
		end_panel.visible = false

	# Restart from intro
	_start_intro()
