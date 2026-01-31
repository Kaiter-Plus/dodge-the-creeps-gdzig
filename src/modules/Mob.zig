const Mob = @This();

pub fn register(r: *Registry) void {
    const class = r.createClass(Mob, r.allocator, .auto);
    class.addMethod("on_notifier_screen_exited", .auto);
}

allocator: Allocator,
base: *RigidBody2D,

pub fn create(allocator: *Allocator) !*Mob {
    const self = try allocator.create(Mob);
    self.* = .{
        .allocator = allocator.*,
        .base = RigidBody2D.init(),
    };
    self.base.setInstance(Mob, self);
    return self;
}

pub fn destroy(self: *Mob, allocator: *Allocator) void {
    self.base.destroy();
    allocator.destroy(self);
}

pub fn _enterTree(self: *Mob) void {
    if (Engine.isEditorHint()) return;
    const visible_on_screen_notifier_node = self.getNodeAs(VisibleOnScreenNotifier2D, String.fromLatin1("VisibleOnScreenNotifier2D"));
    if (visible_on_screen_notifier_node) |notifier| {
        notifier.connect(VisibleOnScreenNotifier2D.ScreenExited, .fromClosure(self, &onNotifierScreenExited)) catch {};
    }
}

pub fn _ready(self: *Mob) void {
    if (Engine.isEditorHint()) return;
    const animated_sprite_node = self.getNodeAs(AnimatedSprite2D, String.fromLatin1("AnimatedSprite2D"));
    if (animated_sprite_node) |animated| {
        const sprite_frames = animated.getSpriteFrames();
        if (sprite_frames) |frames| {
            const mob_types = Array.fromPackedStringArray(frames.getAnimationNames());
            animated.setAnimation(StringName.fromString(mob_types.pickRandom().stringify()));
            animated.play(.{});
        }
    }
}

pub fn onNotifierScreenExited(self: *Mob) void {
    self.base.queueFree();
}

fn getNodeAs(self: *Mob, comptime T: type, path: String) ?*T {
    return T.downcast(self.base.getNode(NodePath.fromString(path)).?);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const godot = @import("godot");
const Registry = godot.extension.Registry;
const Engine = godot.class.Engine;
const RigidBody2D = godot.class.RigidBody2d;
const AnimatedSprite2D = godot.class.AnimatedSprite2d;
const CollisionShape2D = godot.class.CollisionShape2d;
const VisibleOnScreenNotifier2D = godot.class.VisibleOnScreenNotifier2d;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const NodePath = godot.builtin.NodePath;
const Variant = godot.builtin.Variant;
const Array = godot.builtin.Array;
