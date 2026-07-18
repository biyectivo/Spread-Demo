// live_auto_call;

if (point_in_rectangle(device_mouse_x(0), device_mouse_y(0), self.bbox_left, self.bbox_top, self.bbox_right, self.bbox_bottom)) {
	var _fmt = "[scale,0.2][fa_center][fa_bottom][c_white]";
	scribble($"{_fmt}{self.stats.tower_name}").draw(self.x, self.y-8);
	draw_circle_color(self.x, self.y, self.stats.range, c_red, c_red, true);
}