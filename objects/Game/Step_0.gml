// live_auto_call;

// Pause stuff
if (keyboard_check_pressed(vk_escape)) {
	self.paused = !self.paused;
	if (self.paused)	{
		time_source_pause(time_source_game);
		with (cls_Unit) path_speed = 0;
	}
	else				{
		time_source_resume(time_source_game);
		with (cls_Unit) path_speed = self.stats.walk_speed;
	}
}

self.update_current_wave();


// Let's enable hot-reloading our tables while in DEV mode.
// We wrap it with try...catch to message the user if something failed and keep the previous good data

if (keyboard_check_pressed(ord("E"))) {
	try {
		spread_reload_table("tbl_enemies");
		with (cls_Unit) self.update_stats();	// We call the update stats method from the object to make sure it gets the new values
		self.error_message = "Spread reloaded enemies successfully!";
		self.alarm[0] = 60*2;		
	}
	catch (_e) {
		self.error_message = "Spread could not reload enemies.\n"+string_replace_all(_e, "[", "[[");
		self.alarm[0] = 60*5;
	}
}
if (keyboard_check_pressed(ord("T"))) {
	try {
		spread_reload_table("tbl_towers");
		with (cls_Tower) self.update_stats();	// We call the update stats method from the object to make sure it gets the new values
		self.error_message = "Spread reloaded towers successfully!";
		self.alarm[0] = 60*2;
	}
	catch (_e) {
		self.error_message = "Spread could not reload towers.\n"+string_replace_all(_e, "[", "[[");
		self.alarm[0] = 60*5;
	}
}
if (keyboard_check_pressed(ord("P"))) {
	try {
		spread_reload_table("tbl_projectiles");
		with (cls_Projectile) self.update_stats();	// We call the update stats method from the object to make sure it gets the new values
		self.error_message = "Spread reloaded projectiles successfully!";
		self.alarm[0] = 60*2;
	}
	catch (_e) {
		self.error_message = string_replace_all(_e, "[", "[[");
		self.alarm[0] = 60*5;
	}
}
if (keyboard_check_pressed(ord("W"))) {
	try {
		spread_reload_table("tbl_waves");
		self.error_message = "Spread reloaded waves successfully!";
		self.alarm[0] = 60*2;
	}
	catch (_e) {
		self.error_message = string_replace_all(_e, "[", "[[");
		self.alarm[0] = 60*5;
	}
}

with (cls_Unit) self.depth = -self.y;
with (cls_Tower) self.depth = -self.y;
with (cls_Projectile) self.depth = -self.y;