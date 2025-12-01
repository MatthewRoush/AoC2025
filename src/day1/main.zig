const std = @import("std");
const builtin = @import("builtin");

const dial_max = 99;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    const cwd = std.fs.cwd();

    {
        const input = cwd.readFileAlloc(gpa, "input_data/day1/puzzle1_example.txt", 1024 * 1024) catch unreachable;
        defer gpa.free(input);
        std.debug.print("Puzzle 1 example answer: {d}\n", .{puzzle1(input)});
    }

    {
        const input = cwd.readFileAlloc(gpa, "input_data/day1/puzzle1.txt", 1024 * 1024) catch unreachable;
        defer gpa.free(input);
        std.debug.print("Puzzle 1 answer: {d}\n", .{puzzle1(input)});
    }
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

fn rotateDial(dial: i32, rotation: i32) i32 {
    return @mod(dial + rotation, dial_max + 1);
}

fn puzzle1(input: []const u8) u32 {
    var sum: u32 = 0;

    var dial: i32 = 50;

    var iterator = std.mem.splitScalar(u8, input, '\n');

    while (iterator.next()) |line| {
        const rotation = parseRotation(line);

        dial = rotateDial(dial, rotation);

        sum += @intFromBool(dial == 0);
    }

    return sum;
}
