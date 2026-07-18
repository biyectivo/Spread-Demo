self.update_stats = function() {
	self.stats = spread_get_item(self.key, "tbl_enemies");
	if (!Game.paused) self.path_speed = self.stats.walk_speed;
}
self.update_stats();
self.hp = self.stats.max_hp;


self.sprite_index = asset_get_index($"spr_{self.key}");
self.mask_index = self.sprite_index;

var _px = path_get_point_x(pth_TD, 0);
var _py = path_get_point_y(pth_TD, 0);
self.x = _px;
self.y = _py;
path_start(pth_TD, self.stats.walk_speed, path_action_stop, true);
