@tool
extends Node2D

const TILE_SIZE: float = 100.0

const SPACING: float = 5

const COS_45 = 0.70710678118 # sqrt(2.0)/2.0
const SQRT_2 = 1.41421356237

@export var start_marker: Marker2D

@export var end_marker: Marker2D


func _process(delta: float) -> void:
	var rect_half_size: Vector2 = Vector2(TILE_SIZE, TILE_SIZE) / 2.0
	
	start_marker.global_position = start_marker.global_position.clamp(-rect_half_size, rect_half_size)
	
	queue_redraw()


func _draw() -> void:
	var rect_offset: Vector2 = -Vector2(TILE_SIZE, TILE_SIZE) / 2.0
	
	var velocity: Vector2 = end_marker.global_position - start_marker.global_position
	
	for i in range(-1, 2):
		for j in range(-1, 2):
			
			var offset: Vector2 = Vector2(i, j)
			
			var tile_offset: Vector2 = offset * (TILE_SIZE + SPACING)
			
			var color: Color = Color.WHITE
			
			var diagonal: bool = i != 0 and j != 0
			
			var can_reach_center: bool = abs((velocity / max(1e-6, velocity.length())).dot(offset / SQRT_2)) > COS_45;
			
			if diagonal and !can_reach_center:
				color = Color.RED
			
			draw_rect(Rect2(tile_offset + rect_offset, Vector2(TILE_SIZE, TILE_SIZE)), color)
	
	var half_velocity: Vector2 = velocity / 2.0
	
	draw_line(start_marker.global_position - half_velocity, start_marker.global_position + half_velocity, Color.GREEN, 10)
