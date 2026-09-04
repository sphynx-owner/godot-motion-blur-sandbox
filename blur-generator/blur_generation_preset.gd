@tool
class_name BlurGenerationPreset
extends Resource

@export var name: String:
	set(value):
		name = value
		resource_name = value

@export var enabled: bool = true

## The framerate to emulate. Lower framerate means larger slice of time being
## accumulated over.
@export var framerate: int = 30

## The amount of timesteps to accumulate along. It includes the very ends
## of the time range.
@export var resolution: int = 30

## In which direction, given the current replay position, to start accumulating.
## [enum BlurGenerator.CENTERED] means the accumulation time range starts slightly before and ends 
## equally after the replay reference position. [enum BlurGenerator.LEADING] means the time range
## starts at the replay position, and moves forward. [enum BlurGenerator.TRAILING] means the
## time range starts before the replay position, and moves forward, ending at the replay position.
@export var accumulation_directionality: BlurGenerator.Directionality = BlurGenerator.Directionality.CENTERED

## When [code]null[/code], the blur generator would use no compositor effects, and generate
## an accumulation using discrete time steps. When set to some value, it's assumed that
## a motion blur is now applied as a compositor effect, and the blur generator would take
## [member custom_compositor_directionality] into account and would offset the timesteps
## slightly to match the "blurred motion range" as well as possible.
@export var custom_compositor: Compositor = null

## You must manually match this value to the directionality of the active motion blur
## on your [member custom_compositor]. [enum BlurGenerator.CENTERED] is for most motion blurs,
## where the image is blurred both forwards and backwards along the direction of motion at
## each pixel. [enum BlurGenerator.LEADING] is for motion blurs that blur ahead of the pixel
## along the motion direction, wich should not be a thing honestly. [enum BlurGenerator.TRAILING]
## is for motion blurs that genreate backwards along the motion direction from each pixel. It
## too is not a common practice, but I've worked on such motion blurs in the past and they
## should be supported.
# TODO @sphynx-owner: explore discovering the directionality procedurally given the
# motion blur type.
@export var custom_compositor_directionality: BlurGenerator.Directionality = BlurGenerator.Directionality.CENTERED


func _validate_property(property: Dictionary) -> void:
	if property.name == "compositor_blur_directionality":
		if custom_compositor == null:
			property.usage &= ~PROPERTY_USAGE_EDITOR
