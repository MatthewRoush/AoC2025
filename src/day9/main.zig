const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const Vector2 = struct {
    x: i32,
    y: i32,
};

const Rectangle = struct {
    p1: Vector2,
    p2: Vector2,
    area: u64 = undefined,

    pub fn init(p1: Vector2, p2: Vector2) @This() {
        var self: @This() = .{.p1 = p1, .p2 = p2};
        self.calcArea();
        return self;
    }

    pub fn calcArea(self: *@This()) void {
        self.area = @as(u64, @intCast((@abs(self.p1.x - self.p2.x) + 1))) * @as(u64, @intCast((@abs(self.p1.y - self.p2.y) + 1)));
    }

    pub fn greaterThan(_: void, a: @This(), b: @This()) bool {
        return a.area > b.area;
    }
};

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u64, gpa, .day9, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    if (puzzle == .puzzle2) return undefined;

    var tiles: std.ArrayList(Vector2) = .empty;
    defer tiles.deinit(allocator);

    var rects: std.ArrayList(Rectangle) = .empty;
    defer rects.deinit(allocator);

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        const comma = std.mem.indexOfScalar(u8, line, ',').?;

        const tile: Vector2 = .{
            .x = std.fmt.parseInt(i32, line[0 .. comma], 10) catch unreachable,
            .y = std.fmt.parseInt(i32, line[comma + 1 ..], 10) catch unreachable,
        };

        for (tiles.items) |other_tile| {
            rects.append(allocator, .init(tile, other_tile)) catch unreachable;
        }

        tiles.append(allocator, tile) catch unreachable;
    }

    std.mem.sortUnstable(Rectangle, rects.items, {}, Rectangle.greaterThan);

    return rects.items[0].area;
}
