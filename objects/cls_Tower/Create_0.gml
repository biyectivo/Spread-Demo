self.update_stats = function() {
	self.stats = spread_get_item(self.key, "tbl_towers");
}
self.update_stats();

self.sprite_index = asset_get_index(self.stats.sprite_name);
self.mask_index = self.sprite_index;

self.fsm = new StateMachine();
self.fsm.add("Idle", {
	"enter": function() {
	},
	"step": function() {},
	"leave": function() {},
});


self.fsm.add("Attack-Heal", {
	"enter": function() {
		if (self.stats.is_attacking) {
			var _target_id = instance_nearest(self.x, self.y, cls_Unit);
			instance_create_layer(self.x, self.y, "lyr_Instances", cls_Projectile, {key: self.stats.projectile, target: _target_id});
		}
	},
	"step": function() {},
	"leave": function() {},
});


self.fsm.add("Delay", {
	"enter": function() {		
	},
	"step": function() {},
	"leave": function() {},
});

self.fsm.add_transition("Idle", "Delay", function() {
	if (self.stats.is_attacking) {
		return distance_to_object(cls_Unit) <= self.stats.range;
	}
	else {
		return distance_to_object(cls_Tower) <= self.stats.range;
	}
});

self.fsm.add_transition("Delay", "Attack-Heal", function() {
	// Check still within range
	if (self.fsm.get_state_timer() >= 60 * self.stats.delay) {
		if (self.stats.is_attacking) {
			return distance_to_object(cls_Unit) <= self.stats.range;
		}
		else {
			return distance_to_object(cls_Tower) <= self.stats.range;
		}
	}
	else {
		return false;
	}
});

self.fsm.add_transition("Delay", "Idle", function() {
	// Check still within range
	if (self.fsm.get_state_timer() >= 60 * self.stats.delay) {
		if (self.stats.is_attacking) {
			return distance_to_object(cls_Unit) > self.stats.range;
		}
		else {
			return distance_to_object(cls_Tower) > self.stats.range;
		}
	}
	else {
		return false;
	}
});


self.fsm.add_transition("Attack-Heal", "Delay", function() {
	return true;
});

self.fsm.init("Idle");