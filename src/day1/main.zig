const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

const dial_max = 99;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u32, gpa, .day1, solve);
}

fn parseRotation(rotation: []const u8) i32 {
    std.debug.assert(rotation.len >= 2);
    std.debug.assert(rotation[0] == 'R' or rotation[0] == 'L');

    const sign: i32 = if (rotation[0] == 'L') -1 else 1;

    var value: i32 = 0;

    for (rotation[1..]) |ch| {
        value *= 10;
        value += ch - '0';
    }

    return value * sign;
}

fn solve(input: []const u8, comptime puzzle: utils.Puzzle) u32 {
    var sum: u32 = 0;

    var dial: i32 = 50;

    var iterator = std.mem.splitScalar(u8, input, '\n');

    while (iterator.next()) |line| {
        // If the line endings are "\r\n" then `line` will end with a '\r'.
        const rotation = switch (line[line.len - 1]) {
            '\r' => parseRotation(line[0 .. line.len - 1]),
            else => parseRotation(line)
        };

        const rotated_dial = dial + rotation;

        const wrapped_dial = @mod(rotated_dial, dial_max + 1);

        if (puzzle == .puzzle2) {
            var crossed_zero_count: u32 = @abs(rotated_dial) / (dial_max + 1) + @intFromBool(rotated_dial < 0 and dial != 0);

            if (wrapped_dial == 0 and crossed_zero_count > 0) crossed_zero_count -= 1;

            sum += crossed_zero_count;
        }

        sum += @intFromBool(wrapped_dial == 0);

        dial = wrapped_dial;
    }

    return sum;
}
