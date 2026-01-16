extends Node2D

# Visual settings
@export var inner_radius: float = 40.0
@export var outer_radius_max: float = 120.0  # Starting size of closing ring
@export var ring_thickness: float = 6.0

@export var inner_color: Color = Color(0.2, 0.6, 1.0, 0.9)  # Blue filled circle
@export var outer_color: Color = Color(1.0, 1.0, 1.0, 0.8)  # White ring
@export var perfect_color: Color = Color(1.0, 0.84, 0.0, 1.0)  # Gold when rings align

# Result colors
const COLOR_PERFECT: Color = Color(1.0, 0.84, 0.0, 1.0)  # Gold
const COLOR_GOOD: Color = Color(0.0, 1.0, 0.3, 1.0)  # Green
const COLOR_OK: Color = Color(0.0, 0.8, 1.0, 1.0)  # Cyan
const COLOR_MISS: Color = Color(1.0, 0.2, 0.2, 1.0)  # Red

# Animation state
var ring_progress: float = 0.0  # 0 = ring at max size, 1 = ring at inner size
var pulse_scale: float = 1.0
var is_pulsing: bool = false

# Feedback state
var feedback_color: Color = Color.WHITE
var feedback_alpha: float = 0.0
var feedback_ring_scale: float = 1.0
var is_showing_feedback: bool = false

func _ready() -> void:
	# Force redraw every frame
	set_process(true)

func _process(_delta: float) -> void:
	# Handle pulse decay
	if is_pulsing:
		pulse_scale = lerp(pulse_scale, 1.0, 0.15)
		if pulse_scale < 1.02:
			pulse_scale = 1.0
			is_pulsing = false

	# Handle feedback animation
	if is_showing_feedback:
		feedback_alpha = lerp(feedback_alpha, 0.0, 0.08)
		feedback_ring_scale = lerp(feedback_ring_scale, 2.5, 0.12)
		if feedback_alpha < 0.05:
			feedback_alpha = 0.0
			is_showing_feedback = false

	queue_redraw()

func _draw() -> void:
	# Draw feedback ring (expanding colored ring on hit)
	if is_showing_feedback and feedback_alpha > 0:
		var fb_color = feedback_color
		fb_color.a = feedback_alpha
		var fb_radius = inner_radius * feedback_ring_scale
		draw_arc(Vector2.ZERO, fb_radius, 0, TAU, 64, fb_color, ring_thickness * 2, true)

	# Calculate current outer ring radius based on progress
	# Progress 0 = outer_radius_max, progress 1 = inner_radius (flush)
	var current_outer_radius = lerp(outer_radius_max, inner_radius, ring_progress)

	# Draw inner filled circle (with pulse)
	var pulsed_inner_radius = inner_radius * pulse_scale
	draw_circle(Vector2.ZERO, pulsed_inner_radius, inner_color)

	# Draw outer ring (not filled)
	# Color shifts toward perfect_color as ring gets close
	var proximity = 1.0 - abs(current_outer_radius - inner_radius) / (outer_radius_max - inner_radius)
	var ring_color = outer_color.lerp(perfect_color, proximity * proximity)

	# Draw the ring as an arc (full circle)
	draw_arc(Vector2.ZERO, current_outer_radius, 0, TAU, 64, ring_color, ring_thickness, true)

func set_ring_progress(progress: float) -> void:
	# Progress is 0-1 through the cycle
	# We want the ring to close in and hit exactly at progress = target_beat_position
	# For simplicity, assume target is at end of cycle (progress = 1.0 wraps to 0)
	ring_progress = progress

func pulse() -> void:
	# Trigger a pulse animation on the inner circle
	pulse_scale = 1.25
	is_pulsing = true

func reset() -> void:
	ring_progress = 0.0
	pulse_scale = 1.0
	is_pulsing = false
	feedback_alpha = 0.0
	is_showing_feedback = false

func show_feedback(result: String) -> void:
	# Show colored feedback ring based on result
	match result:
		"perfect":
			feedback_color = COLOR_PERFECT
		"good":
			feedback_color = COLOR_GOOD
		"ok":
			feedback_color = COLOR_OK
		"miss":
			feedback_color = COLOR_MISS
		_:
			feedback_color = Color.WHITE

	feedback_alpha = 1.0
	feedback_ring_scale = 1.0
	is_showing_feedback = true

func flash_perfect() -> void:
	show_feedback("perfect")
