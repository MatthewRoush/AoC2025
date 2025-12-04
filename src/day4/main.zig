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
    var sum: u32 = 0;

    var array: std.ArrayList(u8) = .empty;

    var iterator = utils.lineIterator(input);

    const grid_width = iterator.first().len;
    iterator.reset();

    var grid_height: usize = 0;

    while (iterator.next()) |line| {
        array.appendSlice(allocator, line) catch unreachable;
        grid_height += 1;
    }

    var grid_primary = array.toOwnedSlice(allocator) catch unreachable;
    defer allocator.free(grid_primary);

    var grid_secondary: []u8 = allocator.dupe(u8, grid_primary) catch unreachable;
    defer allocator.free(grid_secondary);

    while (true) {
        var removed_any = false;

        for (grid_primary, 0 ..) |cell, i| {

            if (cell == '.') {
                grid_secondary[i] = '.';

                continue;
            }

            std.debug.assert(cell == '@');

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

                    if (grid_primary[neighbor_index] == '@') neighbors += 1;
                }
            }

            if (neighbors < 4) {
                sum += 1;
                grid_secondary[i] = '.';
                removed_any = true;
            }
        }

        if (puzzle == .puzzle1) break;

        if (!removed_any) break;

        const temp = grid_primary;
        grid_primary = grid_secondary;
        grid_secondary = temp;
    }

    return sum;
}
