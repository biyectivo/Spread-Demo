// live_auto_call;

// Draw the top HUD
draw_set_alpha(0.5);
draw_rectangle_color(0, 0, display_get_gui_width(), 30, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

var _fmt = "[fa_left][fa_middle][c_white][scale,0.2]";
scribble($"{_fmt}Spread in Dev mode? [c_lime]{spread_prod_mode() ? "No" : "Yes"}[c_white]").draw(10, 10);
var _reload_msg = spread_prod_mode() ? "You cannot reload live data, you are in prod mode" : "Press to hot-reload frm XLSX:		([c_lime]E[c_white])nemies	([c_lime]T[c_white])owers	([c_lime]P[c_white])rojectiles	([c_lime]W[c_white])aves";
scribble($"{_fmt}Pause: [c_lime]ESC [c_white]	{_reload_msg}").draw(10, 20);

var _fmt = "[fa_right][fa_middle][c_white][scale,0.3]";
scribble($"{_fmt}Money: ${self.current_money}").draw(display_get_gui_width()- 10, 10);
scribble($"{_fmt}Current wave: {self.current_wave+1}").draw(display_get_gui_width()-10, 20);

// Draw a paused text
if (self.paused) scribble($"[fa_center][fa_middle]GAME PAUSED").draw(GUI_W/2, GUI_H/2);
// Draw error on Spread load if failed
if (self.alarm[0] > 0) {
	draw_set_alpha(0.5);
	draw_rectangle_color(GUI_W*1/8, GUI_H*1/8, GUI_W*7/8, GUI_H*7/8, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1);
	scribble($"[fa_center][fa_middle][scale,0.3]{self.error_message}").wrap(GUI_W*3/4).draw(GUI_W/2, GUI_H/2);
}

// Draw the tower placement buttons

// Let's get the towers data with spread_get_* functions
var _towers = spread_get_item_keys("tbl_towers");
array_sort(_towers, true);
var _n=array_length(_towers);
var _button_size = 36;
var _button_spacing = 12;
var _bottom_padding = 4;
var _toolbar_width = _n * _button_size + (_n-1) * _button_spacing;
var _x = (display_get_gui_width() - _toolbar_width)/2;
var _y = display_get_gui_height() - _button_size - _bottom_padding;

var _selecting_towers = false;
	
for (var _i=0; _i<_n; _i++) {
	draw_set_alpha(0.5);
	draw_rectangle_color(_x, _y, _x+_button_size, _y+_button_size, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1);
	
	// Let's get the tower data with spread_get_item (we could also use spread_get and just get a specific field instead, but in this case we will be using several, so it's better to fetch the entire item struct)
	var _tower_id = _towers[_i];
	var _tower = spread_get_item(_tower_id, "tbl_towers");
	if (self.selected == _tower_id)		draw_rectangle_color(_x, _y, _x+_button_size, _y+_button_size, c_yellow, c_yellow, c_yellow, c_yellow, true);
	
	
	
	var _spr = asset_get_index(_tower.sprite_name);	
	var _alpha = _tower.cost <= self.current_money ? 1 : 0.5;
	draw_sprite_ext(_spr, 0, _x+_button_size/2, _y+_button_size/2, 1, 1, 0, c_white, _alpha);	
	
	// Tootlip
	if (point_in_rectangle(device_mouse_x(0), device_mouse_y(0), _x, _y, _x+_button_size, _y+_button_size)) {		
		_selecting_towers = true;
		if (_tower.cost <= self.current_money) {
			draw_rectangle_color(_x, _y, _x+_button_size, _y+_button_size, #ccaa00, #ccaa00, #ccaa00, #ccaa00, true);
			var _fmt = "[fa_left][fa_bottom][c_white][scale,0.2]";
		}
		else {
			var _fmt = "[fa_left][fa_bottom][c_gray][scale,0.2]";
		}
		
		var _s = scribble($"{_fmt}{_tower.tower_name} (${_tower.cost})\n[c_gray]Delay: {_tower.delay}\nRange: {_tower.range}\n{_tower.is_attacking ? string($"Projectiles fired: {_tower.projectiles_fired}") : ""}");
		var _w = _s.get_width() + 4;
		var _h = _s.get_height() + 4;
		draw_set_alpha(0.7);
		draw_rectangle_color(_x, _y-_h, _x+_w, _y, c_black, c_black, c_black, c_black, false);
		draw_set_alpha(1);		
		_s.draw(_x+2, _y - _bottom_padding)
		if (device_mouse_check_button_pressed(0, mb_left) && _tower.cost <= self.current_money)	{
			if (self.selected == _tower_id)	self.selected = undefined;
			else self.selected = _tower_id;
		}
	}
	
	_x += _button_size + _button_spacing;
}
self.selecting_towers = _selecting_towers;