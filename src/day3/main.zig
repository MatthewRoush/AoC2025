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

    utils.runSolution(u64, gpa, .day3, solve);
}

fn solve(_: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    var sum: u64 = 0;

    const battery_count = if (puzzle == .puzzle1) 2 else 12;

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        var joltage: u64 = 0;
        var previous_battery_i: usize = 0;

        for (0 .. battery_count) |i| {
            var digit: u8 = '0';

            const start = if (i == 0) previous_battery_i else previous_battery_i + 1;
            const end = line.len - (battery_count - 1 - i);

            for (line[start .. end], start ..) |ch, k| {
                if (ch > digit) {
                    digit = ch;
                    previous_battery_i = k;

                    if (ch == '9') break;
                }
            }

            joltage = joltage * 10 + (digit - '0');
        }

        sum += joltage;
    }

    return sum;
}
