const Player = @This();

pub fn register(r: *Registry) void {
    const class = r.createClass(Player, r.allocator, .auto);
    // Methods
    class.addMethod("on_body_entered", .auto); // It will attach onBodyEntered
    class.addMethod("start", .auto);
    // Exported property
    class.addProperty("speed", .auto);
    // Signal
    class.addSignal(Hit);
}

pub const Hit = struct {}; // signal

allocator: Allocator,
base: *Area2D, // the Godot node instance backing this struct
speed: f64 = 400.0, // How fast the player will move (pixels/sec).
screen_size: Vector2 = .zero, // Size of the game window.

pub fn create(allocator: *Allocator) !*Player {
    const self = try allocator.create(Player);
    self.* = .{
        .allocator = allocator.*,
        .base = Area2D.init(),
    };
    self.base.setInstance(Player, self);
    return self;
}

pub fn destroy(self: *Player, allocator: *Allocator) void {
    self.base.destroy();
    allocator.destroy(self);
}

pub fn _enterTree(self: *Player) void {
    if (Engine.isEditorHint()) return;
    self.base.connect(Area2D.BodyEntered, .fromClosure(self, &onBodyEntered)) catch {};
}

pub fn _ready(self: *Player) void {
    if (Engine.isEditorHint()) return;
    self.screen_size = self.base.getViewportRect().size;
    self.base.hide();
}

pub fn _process(self: *Player, delta: f64) void {
    if (Engine.isEditorHint()) return;

    var velocity = Vector2.zero; // The player's movement vector.
    if (Input.isActionPressed(.fromLatin1("move_right", false), .{})) {
        velocity = velocity.add(Vector2.right);
    }
    if (Input.isActionPressed(.fromLatin1("move_left", false), .{})) {
        velocity = velocity.add(Vector2.left);
    }
    if (Input.isActionPressed(.fromLatin1("move_down", false), .{})) {
        velocity = velocity.add(Vector2.down);
    }
    if (Input.isActionPressed(.fromLatin1("move_up", false), .{})) {
        velocity = velocity.add(Vector2.up);
    }

    const animated_sprite_node = self.getNodeAs(AnimatedSprite2D, String.fromLatin1("AnimatedSprite2D"));
    if (animated_sprite_node) |animated| {
        if (velocity.length() > 0.0) {
            velocity = velocity.normalized().mulFloat(self.speed);
            if (velocity.x != 0.0) {
                animated.setAnimation(.fromLatin1("walk", false));
                animated.setFlipV(false);
                animated.setFlipH(velocity.x < 0.0);
            } else if (velocity.y != 0.0) {
                animated.setAnimation(.fromLatin1("up", false));
                animated.setFlipV(velocity.y > 0.0);
            }
            animated.play(.{});
        } else {
            animated.stop();
        }
    }

    var pos = self.base.getPosition();
    pos = pos.add(velocity.mulFloat(delta));
    pos = pos.clamp(Vector2.zero, self.screen_size);
    self.base.setPosition(pos);
}

pub fn onBodyEntered(self: *Player) void {
    self.base.hide(); // Player disappears after being hit.
    self.base.emit(Hit, .{}) catch {};
    const collision_shape_node = self.getNodeAs(CollisionShape2D, String.fromLatin1("CollisionShape2D"));
    if (collision_shape_node) |collision| {
        // Must be deferred as we can't change physics properties on a physics callback.
        collision.setDeferred(.fromLatin1("disabled", false), Variant.init(bool, true));
    }
}

pub fn start(self: *Player, pos: Vector2) void {
    self.base.setPosition(pos);
    self.base.show();
    const collision_shape_node = self.getNodeAs(CollisionShape2D, String.fromLatin1("CollisionShape2D"));
    if (collision_shape_node) |collision| {
        collision.setDisabled(false);
    }
}

fn getNodeAs(self: *Player, comptime T: type, path: String) ?*T {
    return T.downcast(self.base.getNode(NodePath.fromString(path)).?);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const godot = @import("godot");
const Registry = godot.extension.Registry;
const Engine = godot.class.Engine;
const Node = godot.class.Node;
const Input = godot.class.Input;
const Area2D = godot.class.Area2d;
const CollisionShape2D = godot.class.CollisionShape2d;
const AnimatedSprite2D = godot.class.AnimatedSprite2d;
const Vector2 = godot.builtin.Vector2;
const StringName = godot.builtin.StringName;
const String = godot.builtin.String;
const NodePath = godot.builtin.NodePath;
const Variant = godot.builtin.Variant;
