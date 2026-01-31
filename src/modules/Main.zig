const Main = @This();

pub fn register(r: *Registry) void {
    const class = r.createClass(Main, r.allocator, .auto);
    class.addMethod("game_over", .auto);
    class.addMethod("new_game", .auto);
    class.addMethod("on_mob_timer_timeout", .auto);
    class.addMethod("on_score_timer_timeout", .auto);
    class.addMethod("on_start_timer_timeout", .auto);
}

allocator: Allocator,
base: *Node,
mob_scene: ?*PackedScene = null,
player: ?*Player = null,
hud: ?*Hud = null,
score: i64 = 0,

pub fn create(allocator: *Allocator) !*Main {
    const self = try allocator.create(Main);
    self.* = .{
        .allocator = allocator.*,
        .base = Node.init(),
    };
    self.base.setInstance(Main, self);
    return self;
}

pub fn destroy(self: *Main, allocator: *Allocator) void {
    self.base.destroy();
    allocator.destroy(self);
}

pub fn _enterTree(self: *Main) void {
    if (Engine.isEditorHint()) return;
    const mob_timer_node = self.getNodeAs(Timer, String.fromLatin1("MobTimer"));
    if (mob_timer_node) |timer| {
        timer.connect(Timer.Timeout, .fromClosure(self, &onMobTimerTimeout)) catch {};
    }
    const score_timer_node = self.getNodeAs(Timer, String.fromLatin1("ScoreTimer"));
    if (score_timer_node) |timer| {
        timer.connect(Timer.Timeout, .fromClosure(self, &onScoreTimerTimeout)) catch {};
    }
    const start_timer_node = self.getNodeAs(Timer, String.fromLatin1("StartTimer"));
    if (start_timer_node) |timer| {
        timer.connect(Timer.Timeout, .fromClosure(self, &onStartTimerTimeout)) catch {};
    }
    self.initializeMobScene();
    self.initializePlayer();
    self.initializeHUD();
}

pub fn gameOver(self: *Main) void {
    const score_timer_node = self.getNodeAs(Timer, String.fromLatin1("ScoreTimer"));
    if (score_timer_node) |timer| {
        timer.stop();
    }
    const mob_timer_node = self.getNodeAs(Timer, String.fromLatin1("MobTimer"));
    if (mob_timer_node) |timer| {
        timer.stop();
    }
    if (self.hud) |hud| hud.showGameOver();
    const music_node = self.getNodeAs(AudioStreamPlayer, String.fromLatin1("Music"));
    if (music_node) |music| {
        music.stop();
    }
    const sound_node = self.getNodeAs(AudioStreamPlayer, String.fromLatin1("DeathSound"));
    if (sound_node) |sound| {
        sound.play(.{});
    }
}

pub fn newGame(self: *Main) void {
    self.score = 0;
    self.base.getTree().?.callGroup(StringName.fromComptimeLatin1("mobs"), StringName.fromComptimeLatin1("queue_free"), .{});
    if (self.player) |player| {
        const start_position_node = self.getNodeAs(Marker2D, String.fromLatin1("StartPosition"));
        if (start_position_node) |position| {
            player.start(position.getPosition());
        }
    }
    const start_timer_node = self.getNodeAs(Timer, String.fromLatin1("StartTimer"));
    if (start_timer_node) |timer| {
        timer.start(.{});
    }
    if (self.hud) |hud| {
        hud.updateScore(self.score);
        hud.showMessage(String.fromLatin1("Get Ready"));
    }
    const music_node = self.getNodeAs(AudioStreamPlayer, String.fromLatin1("Music"));
    if (music_node) |music| {
        music.play(.{});
    }
}

pub fn onMobTimerTimeout(self: *Main) void {
    const mob_spawn_location_node = self.getNodeAs(PathFollow2D, String.fromLatin1("MobPath/MobSpawnLocation"));
    if (mob_spawn_location_node) |location| {
        // Create a new instance of the Mob scene.
        const mob = Mob.create(&self.allocator) catch unreachable;
        const node = self.mob_scene.?.instantiate(.{}).?;
        mob.base = RigidBody2D.downcast(node).?;
        // Choose a random location on Path2D.
        location.setProgressRatio(godot.random.randf());
        // Set the mob's position to the random location.
        mob.base.setPosition(location.getPosition());
        // Set the mob's direction perpendicular to the path direction.
        var direction = location.getRotation() + std.math.pi / 2.0;
        // Add some randomness to the direction.
        direction += godot.random.randfRange(-std.math.pi / 4.0, std.math.pi / 4.0);
        mob.base.setRotation(direction);
        // Choose the velocity for the mob.
        var velocity: Vector2 = .{ .x = @floatCast(godot.random.randfRange(150.0, 250.0)), .y = 0.0 };
        mob.base.setLinearVelocity(velocity.rotated(direction));
        // Spawn the mob by adding it to the Main scene.
        self.base.addChild(Node.upcast(mob), .{});
    }
}

pub fn onScoreTimerTimeout(self: *Main) void {
    self.score += 1;
    if (self.hud) |hud| hud.updateScore(self.score);
}

pub fn onStartTimerTimeout(self: *Main) void {
    const mob_timer_node = self.getNodeAs(Timer, String.fromLatin1("MobTimer"));
    if (mob_timer_node) |timer| {
        timer.start(.{});
    }
    const score_timer_node = self.getNodeAs(Timer, String.fromLatin1("ScoreTimer"));
    if (score_timer_node) |timer| {
        timer.start(.{});
    }
}

fn initializeMobScene(self: *Main) void {
    var scene_path: String = .fromLatin1("res://scenes/mob.tscn");
    defer scene_path.deinit();
    const resource = ResourceLoader.load(scene_path, .{}).?;
    self.mob_scene = PackedScene.downcast(resource);
}

fn initializePlayer(self: *Main) void {
    var path: String = .fromLatin1("Player");
    defer path.deinit();
    const node = self.base.getNode(NodePath.fromString(path));
    if (node) |n| {
        const player = Player.create(&self.allocator) catch unreachable;
        player.*.base = Area2D.downcast(n).?;
        self.player = player;
        self.player.?.base.connect(Player.Hit, .fromClosure(self, &gameOver)) catch {};
    }
}

fn initializeHUD(self: *Main) void {
    var path: String = .fromLatin1("HUD");
    defer path.deinit();
    const node = self.base.getNode(NodePath.fromString(path));
    if (node) |n| {
        const hud = Hud.create(&self.allocator) catch unreachable;
        hud.*.base = CanvasLayer.downcast(n).?;
        self.hud = hud;
        self.hud.?.base.connect(Hud.StartGame, .fromClosure(self, &newGame)) catch {};
    }
}

fn getNodeAs(self: *Main, comptime T: type, path: String) ?*T {
    return T.downcast(self.base.getNode(NodePath.fromString(path)).?);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const godot = @import("godot");
const Registry = godot.extension.Registry;
const Engine = godot.class.Engine;
const PackedScene = godot.class.PackedScene;
const Node = godot.class.Node;
const Timer = godot.class.Timer;
const ResourceLoader = godot.class.ResourceLoader;
const Area2D = godot.class.Area2d;
const RigidBody2D = godot.class.RigidBody2d;
const Marker2D = godot.class.Marker2d;
const PathFollow2D = godot.class.PathFollow2d;
const CanvasLayer = godot.class.CanvasLayer;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const Variant = godot.builtin.Variant;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const NodePath = godot.builtin.NodePath;
const Vector2 = godot.builtin.Vector2;
const Player = @import("Player.zig");
const Mob = @import("Mob.zig");
const Hud = @import("Hud.zig");
