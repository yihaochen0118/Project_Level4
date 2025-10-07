extends Node
class_name UIAnimator

# ✅ 给按钮添加通用悬停/点击动画
func apply_button_effects(button: TextureButton):
	if not button:
		return

	# --- 初始透明度（淡入）---
	button.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(button, "modulate:a", 1, 0.3)

	# --- 悬停放大 ---
	button.mouse_entered.connect(func():
		var t = create_tween()
		t.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	)

	# --- 离开恢复 ---
	button.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(button, "scale", Vector2(1, 1), 0.1)
	)

	# --- 点击轻微闪烁 ---
	button.pressed.connect(func():
		var t = create_tween()
		t.tween_property(button, "modulate", Color(0.8, 0.8, 0.8), 0.05)
		t.tween_property(button, "modulate", Color(1, 1, 1), 0.05)
	)
