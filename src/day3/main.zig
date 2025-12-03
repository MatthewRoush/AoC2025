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

fn solve(input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    if (puzzle == .puzzle2) return undefined;

    var sum: u64 = 0;

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        var first_digit: u8 = '0';
        var first_digit_i: usize = 0;

        for (line[0 .. line.len - 1], 0 ..) |ch, i| {
            if (ch > first_digit) {
                first_digit = ch;
                first_digit_i = i;

                if (first_digit == '9') break;
            }
        }

        var second_digit: u8 = '0';

        for (line[first_digit_i + 1 ..]) |ch| {
            if (ch > second_digit) {
                second_digit = ch;

                if (second_digit == '9') break;
            }
        }

        sum += ((first_digit - '0') * 10) + (second_digit - '0');
    }

    return sum;
}
