// Game start stuff

switch(room) {
	case room_Init:
		room_goto(room_Game);
		break;
	case room_Game:
		var _spawn_rate = spread_get("wave 1", "spawn_rate", "tbl_waves") * 60;
		self.spawner_ts = time_source_create(time_source_game, _spawn_rate, time_source_units_frames, self.spawn_enemy, [], -1, time_source_expire_nearest);
		time_source_start(self.spawner_ts);
		self.current_money = 200;
		break;
}