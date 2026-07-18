self.update_stats = function() {
	self.stats = spread_get_item(self.key, "tbl_projectiles");
}
self.update_stats();

self.sprite_index = asset_get_index($"spr_tower_{self.key}_projectile");
self.mask_index = self.sprite_index; 

if (instance_exists(self.target)) {
	self.dir = point_direction(self.x, self.y, self.target.x, self.target.y);
}
else {
	self.dir = irandom_range(0, 360);
}