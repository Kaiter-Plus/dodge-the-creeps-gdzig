const Hud = @This();

pub fn register(r: *Registry) void {
    const class = r.createClass(Hud, r.allocator, .auto);
    class.addMethod("show_message", .auto);
    class.addMethod("show_game_over", .auto);
    class.addMethod("show_game_start", .auto);
    class.addMethod("update_score", .auto);
    class.addMethod("on_start_button_pressed", .auto);
    class.addMethod("on_message_timer_timeout", .auto);
    class.addSignal(StartGame);
}

pub const StartGame = struct {};

allocator: Allocator,
base: *CanvasLayer,

pub fn create(allocator: *Allocator) !*Hud {
    const self = try allocator.create(Hud);
    self.* = .{
        .allocator = allocator.*,
        .base = CanvasLayer.init(),
    };
    self.base.setInstance(Hud, self);
    return self;
}

pub fn destroy(self: *Hud, allocator: *Allocator) void {
    self.base.destroy();
    allocator.destroy(self);
}

pub fn _enterTree(self: *Hud) void {
    const start_button_node = self.getNodeAs(Button, String.fromLatin1("StartButton"));
    if (start_button_node) |button| {
        button.connect(Button.Pressed, .fromClosure(self, &onStartButtonPressed)) catch {};
    }
    const message_timer_node = self.getNodeAs(Timer, String.fromLatin1("MessageTimer"));
    if (message_timer_node) |timer| {
        timer.connect(Timer.Timeout, .fromClosure(self, &onMessageTimerTimeout)) catch {};
    }
}

pub fn showMessage(self: *Hud, text: String) void {
    const message_node = self.getNodeAs(Label, String.fromLatin1("Message"));
    if (message_node) |message| {
        message.setText(text);
        message.show();
    }
    const message_timer_node = self.getNodeAs(Timer, String.fromLatin1("MessageTimer"));
    if (message_timer_node) |timer| {
        timer.start(.{});
    }
}

pub fn showGameStart(self: *Hud) void {
    const message_timer_node = self.getNodeAs(Timer, String.fromLatin1("MessageTimer"));
    if (message_timer_node) |timer| {
        timer.disconnect(Timer.Timeout, .fromClosure(self, &showGameStart));
    }
    const message_node = self.getNodeAs(Label, String.fromLatin1("Message"));
    if (message_node) |message| {
        message.setText(String.fromLatin1("Dodge the Creeps!"));
        message.show();
    }
    const start_button_node = self.getNodeAs(Button, String.fromLatin1("StartButton"));
    if (start_button_node) |button| {
        button.show();
    }
}

pub fn showGameOver(self: *Hud) void {
    self.showMessage(String.fromLatin1("Game Over!"));
    const message_timer_node = self.getNodeAs(Timer, String.fromLatin1("MessageTimer"));
    if (message_timer_node) |timer| {
        timer.connect(Timer.Timeout, .fromClosure(self, &showGameStart)) catch {};
    }
}

pub fn updateScore(self: *Hud, score: i64) void {
    const score_label_node = self.getNodeAs(Label, String.fromLatin1("ScoreLabel"));
    if (score_label_node) |label| {
        var score_text_buf: [24]u8 = undefined;
        const score_text = std.fmt.bufPrintZ(&score_text_buf, "{d}", .{score}) catch unreachable;
        label.setText(String.fromLatin1(score_text));
    }
}

pub fn onStartButtonPressed(self: *Hud) void {
    const start_button_node = self.getNodeAs(Button, String.fromLatin1("StartButton"));
    if (start_button_node) |button| {
        button.hide();
        self.base.emit(StartGame, .{}) catch {};
    }
}

pub fn onMessageTimerTimeout(self: *Hud) void {
    const message_node = self.getNodeAs(Label, String.fromLatin1("Message"));
    if (message_node) |message| {
        message.hide();
    }
}

fn getNodeAs(self: *Hud, comptime T: type, path: String) ?*T {
    return T.downcast(self.base.getNode(NodePath.fromString(path)).?);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const godot = @import("godot");
const Registry = godot.extension.Registry;
const Engine = godot.class.Engine;
const CanvasLayer = godot.class.CanvasLayer;
const Label = godot.class.Label;
const Button = godot.class.Button;
const Timer = godot.class.Timer;
const SceneTreeTimer = godot.class.SceneTreeTimer;
const String = godot.builtin.String;
const NodePath = godot.builtin.NodePath;
