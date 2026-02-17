extends PanelContainer

func setup(name_text: String, points: int, medal_texture: Texture2D):
	$HBoxContainer/player_name.text = name_text
	$HBoxContainer/player_points.text = str(points) + " PTS"
	
	# Lógica del nodo medal
	if medal_texture != null:
		$HBoxContainer/medal.texture = medal_texture
		$HBoxContainer/medal.show()
