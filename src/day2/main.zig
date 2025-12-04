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

    utils.runSolution(u64, gpa, .day2, solve);
}

fn isDoubleSequence(number: u64) bool {
    const static = struct {
        var buffer: [32]u8 = undefined;
    };

    const string = std.fmt.bufPrint(&static.buffer, "{d}", .{number}) catch unreachable;

    if (string.len & 1 == 1) return false;

    const half_len = string.len / 2;

    return std.mem.eql(u8, string[0 .. half_len], string[half_len ..]);
}

fn isAnySequence(number: u64) bool {
    const static = struct {
        var buffer: [32]u8 = undefined;
        var previous_sequence_lens: [64]u8 = undefined;
    };

    const string = std.fmt.bufPrint(&static.buffer, "{d}", .{number}) catch unreachable;

    const half_len = string.len / 2;

    var previous_sequence_lens = std.ArrayList(u8).initBuffer(&static.previous_sequence_lens);

    for (1 .. half_len + 1) |k| {
        const i = (half_len + 1) - k;

        // If a sequence is half the length of one that was already tried, it can be skipped.
        // Take 48291753 for example, the first sequence to check is 4829, but it doesn't match 1753.
        // Next 48 would be checked, but if 48 was correct, then the first sequence would've been 4848, and the other half would've been 4848 as well.
        // So 48 can be skipped, and 4 will also be skipped.
        if (std.mem.indexOfScalar(u8, previous_sequence_lens.items, @intCast(i * 2))) |_| {
            previous_sequence_lens.appendAssumeCapacity(@intCast(i));
            continue;
        }

        _ = std.math.divExact(u64, string.len, i) catch continue;

        previous_sequence_lens.appendAssumeCapacity(@intCast(i));

        var iterator = std.mem.window(u8, string, i, i);
        const sequence = iterator.first();

        var invalid_id: bool = true;

        while (iterator.next()) |window| {
            if (!std.mem.eql(u8, sequence, window)) {
                invalid_id = false;
                break;
            }
        }

        if (invalid_id) return true;
    }

    return false;
}

fn solve(_: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    var sum: u64 = 0;

    var iterator = std.mem.splitScalar(u8, input, ',');

    while (iterator.next()) |range| {
        if (std.mem.indexOfScalar(u8, range, '-')) |i| {
            const range_begin_str = range[0 .. i];
            const range_end_str   = range[i + 1 ..];

            if (puzzle == .puzzle1 and range_begin_str.len == range_end_str.len and range_begin_str.len & 1 == 1) continue;

            const range_begin = std.fmt.parseInt(u64, range[0 .. i], 10) catch unreachable;
            const range_end   = std.fmt.parseInt(u64, range[i + 1 ..], 10) catch unreachable;

            for (range_begin .. range_end + 1) |x| {
                switch (puzzle) {
                    .puzzle1 => if (isDoubleSequence(x)) {sum += x;},
                    .puzzle2 => if (isAnySequence(x)) {sum += x;},
                }
            }
        }
    }

    return sum;
}
