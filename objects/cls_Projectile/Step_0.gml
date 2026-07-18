// live_auto_call;

if (Game.paused) exit;
if (self.stats.is_homing) {
	if (instance_exists(self.target)) {
		self.dir = point_direction(self.x, self.y, self.target.x, self.target.y);		
	}	
}
self.x += lengthdir_x(self.stats.projectile_speed, self.dir);
self.y += lengthdir_y(self.stats.projectile_speed, self.dir);
self.image_angle = self.dir;

var _id = instance_place(self.x, self.y, cls_Unit);
if (_id != noone) {
	_id.hp -= self.stats.projectile_damage;	
	instance_destroy();
}

if (self.x < 0 || self.x >= room_width || self.y < 0 || self.y > room_height) instance_destroy();