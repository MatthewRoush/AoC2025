const std = @import("std");

const max_file_size = 1024 * 1024;

pub const Day = enum(u8) {
    day1 = 1,
    day2,
    day3,
    day4,
    day5,
    day6,
    day7,
    day8,
    day9,
    day10,
    day11,
    day12,

    pub fn string(self: @This()) []const u8 {
        return switch (self) {
            .day1  => "day1",
            .day2  => "day2",
            .day3  => "day3",
            .day4  => "day4",
            .day5  => "day5",
            .day6  => "day6",
            .day7  => "day7",
            .day8  => "day8",
            .day9  => "day9",
            .day10 => "day10",
            .day11 => "day11",
            .day12 => "day12",
        };
    }
};

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

pub fn checkAnswer(T: type, maybe_expected: ?T, actual: T, comptime puzzle: Puzzle, comptime example: Example) void {
    std.debug.print("    {s} {s}: ", .{puzzle.string(), example.string()});

    if (maybe_expected) |expected| {
        if (expected == actual) {std.debug.print("Passed ({d})\n", .{actual});}
        else {std.debug.print("Failed. Expected {d}, got {d}\n", .{expected, actual});}
    } else {
        std.debug.print("{d} (Untested)\n", .{actual});
    }
}

pub fn runSolution(T: type, allocator: std.mem.Allocator, comptime day: Day, solve: *const fn (allocator: std.mem.Allocator, input: []const u8, comptime puzzle: Puzzle) T) void {
    const cwd = std.fs.cwd();

    const day_str = comptime day.string();

    const data_directory_path = "input_data/" ++ day_str;

    // If both puzzles use the same example input, only 'example_path' is used.
    // If both puzzles have a different example input, 'example_path_1' and 'example_path_2' are used.
    const example_path   = data_directory_path ++ "/puzzle_example.txt";
    const example_path_1 = data_directory_path ++ "/puzzle_example_1.txt";
    const example_path_2 = data_directory_path ++ "/puzzle_example_2.txt";

    const example_input: ?[]u8 = cwd.readFileAlloc(allocator, example_path, max_file_size) catch |err| switch (err) {
        else => unreachable,
        error.FileNotFound => null,
    };

    var example_input_1: []u8 = undefined;
    var example_input_2: []u8 = undefined;

    if (example_input == null) {
        example_input_1 = cwd.readFileAlloc(allocator, example_path_1, max_file_size) catch unreachable;
        example_input_2 = cwd.readFileAlloc(allocator, example_path_2, max_file_size) catch unreachable;
    } else {
        example_input_1 = example_input.?;
        example_input_2 = example_input.?;
    }

    defer {
        if (example_input != null) {
            allocator.free(example_input.?);
        } else {
            allocator.free(example_input_1);
            allocator.free(example_input_2);
        }
    }

    const main_input = cwd.readFileAlloc(allocator, "input_data/" ++ day_str ++ "/puzzle.txt", max_file_size) catch unreachable;
    defer allocator.free(main_input);

    const example_answer_1 = readIntFromFile(T, allocator, cwd, "input_data/" ++ day_str ++ "/puzzle_example_answer_1.txt");
    const example_answer_2 = readIntFromFile(T, allocator, cwd, "input_data/" ++ day_str ++ "/puzzle_example_answer_2.txt");
    const main_answer_1 = readIntFromFile(T, allocator, cwd, "input_data/" ++ day_str ++ "/puzzle_answer_1.txt");
    const main_answer_2 = readIntFromFile(T, allocator, cwd, "input_data/" ++ day_str ++ "/puzzle_answer_2.txt");

    std.debug.print("----- Day {d} -----\n", .{@intFromEnum(day)});

    var timer = std.time.Timer.start() catch unreachable;

    {
        const answer = solve(allocator, example_input_1, .puzzle1);
        checkAnswer(T, example_answer_1, answer, .puzzle1, .example);
    }
    {
        const answer = solve(allocator, main_input, .puzzle1);
        checkAnswer(T, main_answer_1, answer, .puzzle1, .main);
    }
    {
        const answer = solve(allocator, example_input_2, .puzzle2);
        checkAnswer(T, example_answer_2, answer, .puzzle2, .example);
    }
    {
        const answer = solve(allocator, main_input, .puzzle2);
        checkAnswer(T, main_answer_2, answer, .puzzle2, .main);
    }

    std.debug.print("Time = {d}ms\n\n", .{@as(f64, @floatFromInt(timer.read())) / @as(f64, std.time.ns_per_ms)});
}

pub fn readIntFromFile(T: type, allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) ?T {
    const data = dir.readFileAlloc(allocator, path, 1024) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => unreachable
    };
    defer allocator.free(data);

    return std.fmt.parseInt(T, data, 10) catch unreachable;
}

pub const LineIterator = struct {
    const Self = @This();

    newline_iterator: std.mem.SplitIterator(u8, .scalar),

    fn maybeStripTrailingCr(buffer: []const u8)[]const u8 {
        return switch (buffer[buffer.len - 1]) {
            '\r' => buffer[0 .. buffer.len - 1],
            else => buffer
        };
    }

    pub fn first(self: *Self) []const u8 {
        return maybeStripTrailingCr(self.newline_iterator.first());
    }

    pub fn next(self: *Self) ?[]const u8 {
        return maybeStripTrailingCr(self.newline_iterator.next() orelse return null);
    }

    pub fn peek(self: *Self) ?[]const u8 {
        return maybeStripTrailingCr(self.newline_iterator.peek() orelse return null);
    }

    pub fn reset(self: *Self) void {
        self.newline_iterator.reset();
    }

    pub fn rest(self: *Self) []const u8 {
        return self.newline_iterator.rest();
    }
};

pub fn lineIterator(buffer: []const u8) LineIterator {
    return .{
        .newline_iterator = std.mem.splitScalar(u8, buffer, '\n'),
    };
}
