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

        tiles.append(allocator, tile) catch unreachable;
    }

    for (tiles.items, 0..) |this_tile, i| {
        for (i..tiles.items.len + 1) |_k| {
            const k = (_k + 1) % tiles.items.len;
            const other_tile = tiles.items[k];

            switch (puzzle) {
                .puzzle1 => {
                    const new_rect = rectArea(this_tile, other_tile);
                    biggest_rect = @max(biggest_rect, new_rect);
                },
                .puzzle2 => {
                    const new_rect = rectArea(this_tile, other_tile);

                    const rect_min_x = @min(this_tile.x, other_tile.x);
                    const rect_max_x = @max(this_tile.x, other_tile.x);
                    const rect_min_y = @min(this_tile.y, other_tile.y);
                    const rect_max_y = @max(this_tile.y, other_tile.y);

                    if (new_rect > biggest_rect) {
                        var is_within_lines = true;

                        for (tiles.items, 0..) |edge_p1, j| {
                            const edge_p2 = tiles.items[(j + 1) % tiles.items.len];

                            const edge_min_x = @min(edge_p1.x, edge_p2.x);
                            const edge_max_x = @max(edge_p1.x, edge_p2.x);
                            const edge_min_y = @min(edge_p1.y, edge_p2.y);
                            const edge_max_y = @max(edge_p1.y, edge_p2.y);

                            if (rect_min_x > edge_max_x or
                                rect_max_x < edge_min_x or
                                rect_min_y > edge_max_y or
                                rect_max_y < edge_min_y) continue;

                            const horizontal_edge = edge_min_y == edge_max_y;
                            const vertical_edge   = edge_min_x == edge_max_x;

                            if (horizontal_edge and (edge_min_y == this_tile.y or edge_min_y == other_tile.y)) continue;
                            if (vertical_edge   and (edge_min_x == this_tile.x or edge_min_x == other_tile.x)) continue;

                            is_within_lines = false;
                            break;
                        }

                        if (is_within_lines) biggest_rect = new_rect;
                    }
                },
            }
        }
    }

    return biggest_rect;
}
