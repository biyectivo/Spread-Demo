// live_auto_call;

// Here's the game init setup and functions... if you are reading this for the first time to understand how Spread works, you can ignore it for now and read the Spread section below
#region Game init

	randomize();
	scribble_font_set_default("fnt_GUI");

	self.paused = false;
	self.error_message = "";
	self.selected = undefined;
	self.total_money = 0;
	self.current_money = 0;
	self.current_wave = 0;
	self.update_current_wave = function() {
		// live_auto_call;
		var _waves = spread_get_item_keys("tbl_waves");
		array_sort(_waves, true);
		var _current_wave = 0;
		var _n=array_length(_waves);
		var _found = false;
		var _wave = 0;
		
		var _bound = spread_get(_waves[_wave+1], "money_trigger", "tbl_waves");		
		while (_wave < _n-1 && self.total_money > _bound) {
			_wave++;
			_bound = spread_get(_waves[_wave], "money_trigger", "tbl_waves");
		}
		_wave = clamp(_wave-1, 0, _n-1);
		
		if (_wave != self.current_wave) { // New wave
			var _spawn_rate = spread_get(_waves[_wave], "spawn_rate", "tbl_waves") * 60;
			self.current_wave = min(_n-1, _wave);
			time_source_reconfigure(self.spawner_ts, _spawn_rate, time_source_units_frames, self.spawn_enemy, [], -1, time_source_expire_nearest);
			time_source_start(self.spawner_ts);
		}
	};
	self.spawner_ts = undefined;

	self.spawn_enemy = function() {
		var _enemies = spread_get_item_keys("tbl_enemies");
		var _n=array_length(_enemies)
			
		var _array_probs = array_create(_n);
			
		for (var _i=0; _i<_n; _i++) {
			_array_probs[_i] = spread_get(_enemies[_i], $"prob_wave_{Game.current_wave+1}", "tbl_enemies");
		}
			
		var _key = array_random(_enemies, _array_probs);
		instance_create_layer(0, 0, "lyr_Instances", cls_Unit, {key: _key});
	};

	self.selecting_towers = false;

#endregion

#region Spread

	// Let's connect to our XLSX file, which sits in the C:\Users\<your username>\AppData\Local\Spread_Demo folder (in Windows). Make sure to place the downloaded sheet there!	
	// This connection to the XLSX file will be ignored if we are in production mode, since we will be using our precompiled JSON bundles for that
	spread_connect_xlsx("Spread Demo Game Data.xlsx", "db_game_data");

	// Now, let's define our tables

	// First, let's import the enemies
	spread_define_table("tbl_enemies", "db_game_data", "enemies", "B4:L13", [
		new Spread_ID("enemy_id"),
		new Spread_String("enemy_name", true, 0, 20),
		new Spread_String("enemy_description", true),
		new Spread_Num("walk_speed", true, false, 0,,true),
		new Spread_Num("max_hp", true, true, 0,,true),
		new Spread_Num("damage", true, true, 0,, true),
		new Spread_Num("prob_wave_1", true, false, 0, 1),
		new Spread_Num("prob_wave_2", true, false, 0, 1),
		new Spread_Num("prob_wave_3", true, false, 0, 1),
		new Spread_Num("prob_wave_4", true, false, 0, 1),
		new Spread_Num("prob_wave_5", true, false, 0, 1)
	], 1,,,,function(_table) {// Let's add a table-level validation to make sure wave spawn probabilities add up to 1
		var _sum_probs = [0, 0, 0, 0, 0];
		var _keys = struct_get_names(_table);
		for (var _i=0, _n=array_length(_keys); _i<_n; _i++) {
			_sum_probs[0] += _table[$ _keys[_i]].prob_wave_1;
			_sum_probs[1] += _table[$ _keys[_i]].prob_wave_2;
			_sum_probs[2] += _table[$ _keys[_i]].prob_wave_3;
			_sum_probs[3] += _table[$ _keys[_i]].prob_wave_4;
			_sum_probs[4] += _table[$ _keys[_i]].prob_wave_5;
		}
		return _sum_probs[0] == 1 && _sum_probs[1] == 1 && _sum_probs[2] == 1 && _sum_probs[3] == 1 && _sum_probs[4] == 1;
	});

	// Let's import the attack waves as well
	spread_define_table("tbl_waves", "db_game_data", "enemy waves", "a1:c6", [
		new Spread_ID("wave_id"),
		new Spread_Num("money_trigger", true, true, 0),
		new Spread_Num("spawn_rate", true, false),
	], 1);



	// We want to define our towers table, however since they will shoot projectiles and we have a separate table for those, we need to first define the projectiles table, and then reference the projectile fired from each tower in the towers table as a foreign key

	spread_define_table("tbl_projectiles", "db_game_data", "towers", "$P$4:$S$9", [	
		new Spread_Num("projectile_speed", true, false, 0,,true),
		new Spread_Boolean("is_homing", true, false, ["Yes"], ["No"]),
		new Spread_Num("projectile_damage", true, false, 0,, true),
		new Spread_ID("projectile_id"),
	
	]);

	// Let's import the towers now.
	// Let's define this one using a named range
	// Let's define an allowed list of sprites from our sprite asset data
	var _allowed_tower_sprites = tag_get_assets("towers");

	spread_define_table("tbl_towers", "db_game_data", "towers", "towers_table", [
		new Spread_ID("tower_id"),
		new Spread_String("tower_name", true),
		new Spread_Boolean("is_attacking", true, false, ["Y"], ["N"]),
		new Spread_String("sprite_name", true,,,_allowed_tower_sprites),
		new Spread_Num("delay", true, false, 0,,true),
		new Spread_Num("range", true, true, 0,,true),
		new Spread_Num("projectiles_fired", false, true, 1,4),
		new Spread_Num("upgraded_delay", true, false, 0,,true),
		new Spread_Num("upgraded_range", true, true, 0,,true),
		new Spread_Num("upgraded_projectiles_fired", false, true, 1,4),
		new Spread_Num("cost", true, true, 0, 10000, true),
		new Spread_FK("projectile", false, "tbl_projectiles")
		
	],1,,,function(_item) { // Let's add an item-level validation: attack should be < than upgraded attack, and the same with the other attributes
		return _item.delay > _item.upgraded_delay && _item.range < _item.upgraded_range && _item.projectiles_fired <= _item.upgraded_projectiles_fired;
	});


#endregion