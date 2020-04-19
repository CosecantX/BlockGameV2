extends Node2D

export (String) var color
export (bool) var bomb = false
export (float) var dropTime = .5
var marked = false
var dropTween

signal tweenDone

func _ready():
	dropTween = $dropTween

func move(target: Vector2):
	dropTween.interpolate_property(self, "position", position, target, dropTime, Tween.TRANS_SINE, Tween.EASE_OUT)
	dropTween.start()

func _on_dropTween_tween_all_completed():
	emit_signal("tweenDone")
