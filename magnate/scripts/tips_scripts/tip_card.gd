extends Control

signal card_clicked(index) # Para avisar al padre cuando la clican

var my_index: int = 0

func setup(data: TipData, index: int):
	$Panel/HBoxContainer/VBoxContainer/tip_number.text = data.number
	$Panel/HBoxContainer/VBoxContainer/tip_title.text = data.title
	$Panel/HBoxContainer/VBoxContainer/tip_text.text = data.description
	my_index = index

func _on_invisible_button_pressed() -> void:
	card_clicked.emit(my_index)
