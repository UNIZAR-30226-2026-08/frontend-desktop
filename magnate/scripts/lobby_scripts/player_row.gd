extends PanelContainer

func setup(name_text: String, status_text: String, icon_texture: Texture2D):
	$HBoxContainer/player_name.text = name_text
	$HBoxContainer/player_info.text = status_text
	$HBoxContainer/player_icon.texture = icon_texture
