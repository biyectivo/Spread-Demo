// live_auto_call;

if (Game.paused) exit;
if (self.hp <= 0) {
	Game.current_money += 100;
	Game.total_money += 100;
	instance_destroy();	
}
if (place_meeting(self.x, self.y, obj_Castle)) {
	obj_Castle.hp -= self.stats.damage;
	instance_destroy();
}