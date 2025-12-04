const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u32, gpa, .day4, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u32 {
    _ = puzzle;

    var sum: u32 = 0;

    var grid: std.ArrayList(u8) = .empty;
    defer grid.deinit(allocator);

    var grid_height: usize = 0;

    var iterator = utils.lineIterator(input);

    const grid_width = iterator.first().len;
    iterator.reset();

    while (iterator.next()) |line| {
        grid.appendSlice(allocator, line) catch unreachable;
        grid_height += 1;
    }

    for (grid.items, 0 ..) |cell, i| {
        if (cell == '.') continue;

        var neighbors: u32 = 0;

        const x: i32 = @intCast(i % grid_width);
        const y: i32 = @intCast(i / grid_width);

        var y_offset: i32 = -1;

        while (y_offset < 2) : (y_offset += 1) {
            var x_offset: i32 = -1;

            while (x_offset < 2) : (x_offset += 1) {
                if (x_offset == 0 and y_offset == 0) continue;

                const neighbor_x = x + x_offset;
                const neighbor_y = y + y_offset;

                if (neighbor_x < 0 or neighbor_x >= grid_width or neighbor_y < 0 or neighbor_y >= grid_height) continue;

                const neighbor_index = @as(usize, @intCast(neighbor_x)) + @as(usize, @intCast(neighbor_y)) * grid_width;

                if (grid.items[neighbor_index] == '@') neighbors += 1;
            }
        }

        if (neighbors < 4) sum += 1;
    }

    return sum;
}
