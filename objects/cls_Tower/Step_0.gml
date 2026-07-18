// live_auto_call;

if (Game.paused) exit;
self.fsm.step();
self.fsm.transition();