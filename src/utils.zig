const std = @import("std");

pub const Puzzle = enum {
    puzzle1,
    puzzle2,

    pub fn string(self: @This()) []const u8 {
        return switch (self) {
            .puzzle1 => "Puzzle 1",
            .puzzle2 => "Puzzle 2",
        };
    }
};

pub const Example = enum {
    example,
    main,

    pub fn string(self: @This()) []const u8 {
        return switch (self) {
            .example => "Example",
            .main    => "       ",
        };
    }
};

pub fn printDay(day: comptime_int) void {
    std.debug.print("----- Day {d} -----\n", .{day});
}

pub fn checkAnswer(T: type, maybe_expected: ?T, actual: T, puzzle: Puzzle, example: Example) void {
    std.debug.print("    {s} {s}: ", .{puzzle.string(), example.string()});

    if (maybe_expected) |expected| {
        if (expected == actual) {std.debug.print("Passed ({d})\n", .{actual});}
        else {std.debug.print("Failed. Expected {d}, got {d}\n", .{expected, actual});}
    } else {
        std.debug.print("{d} (Untested)\n", .{actual});
    }
}

pub fn readIntFromFile(T: type, allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) T {
    const data = dir.readFileAlloc(allocator, path, 1024 * 1024) catch unreachable;
    defer allocator.free(data);

    return std.fmt.parseInt(T, data, 10) catch unreachable;
}
