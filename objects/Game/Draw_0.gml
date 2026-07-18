// live_auto_call;

// Place tower stuff
if (self.selected != undefined) {
	// tower placement
	var _tower = spread_get_item(self.selected, "tbl_towers");	
	var _spr = asset_get_index(_tower.sprite_name);
	var _tilemap = layer_tilemap_get_id(layer_get_id("lyr_Tile_Paths"));
	var _pixel = tilemap_get_at_pixel(_tilemap, device_mouse_x(0), device_mouse_y(0));
	
	
	var _x = device_mouse_x(0);
	var _y = device_mouse_y(0)-sprite_get_yoffset(_spr);
	
	var _over_path = array_get_index([5,6,7,9,11,13,14,15], _pixel) != -1;
	var _over_unit = position_meeting(_x, _y, cls_Tower);
	var _over = _over_path || _over_unit;
	
	var _blend = _over ? c_red : c_white;
		
	draw_sprite_ext(_spr, 0, _x, _y, 1, 1, 0, _blend, 0.5);
	
	if (!_over && device_mouse_check_button_released(0, mb_left) && !self.selecting_towers && _tower.cost <= self.current_money) {
		instance_create_layer(_x, _y, "lyr_Instances", cls_Tower, {key: self.selected});
		self.selected = undefined;
		self.current_money -= _tower.cost;
	}
}