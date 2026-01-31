// Register
pub fn register(r: *Registry) void {
    r.addModule(Player);
    r.addModule(Mob);
    r.addModule(Main);
    r.addModule(Hud);
}

const std = @import("std");
const godot = @import("godot");
const Registry = godot.extension.Registry;
const Player = @import("modules/Player.zig");
const Mob = @import("modules/Mob.zig");
const Main = @import("modules/Main.zig");
const Hud = @import("modules/Hud.zig");
