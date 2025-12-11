const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const Vector2 = struct {
    x: i32,
    y: i32,
};

fn rectArea(p1: Vector2, p2: Vector2) u64 {
    return @as(u64, @intCast((@abs(p1.x - p2.x) + 1))) * @as(u64, @intCast((@abs(p1.y - p2.y) + 1)));
}

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u64, gpa, .day9, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    if (puzzle == .puzzle2) return 0;

    var tiles: std.ArrayList(Vector2) = .empty;
    defer tiles.deinit(allocator);

    var biggest_rect: u64 = 0;

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        const comma = std.mem.indexOfScalar(u8, line, ',').?;

        const tile: Vector2 = .{
            .x = std.fmt.parseInt(i32, line[0 .. comma], 10) catch unreachable,
            .y = std.fmt.parseInt(i32, line[comma + 1 ..], 10) catch unreachable,
        };

        for (tiles.items) |other_tile| {
            const new_rect = rectArea(tile, other_tile);

            if (new_rect > biggest_rect) biggest_rect = new_rect;
        }

        tiles.append(allocator, tile) catch unreachable;
    }

    return biggest_rect;
}
