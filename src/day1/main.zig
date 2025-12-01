const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

const dial_max = 99;

const max_file_size = 1024 * 1024;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    const cwd = std.fs.cwd();

    const example_input = cwd.readFileAlloc(gpa, "input_data/day1/puzzle_example.txt", max_file_size) catch unreachable;
    defer gpa.free(example_input);

    const main_input = cwd.readFileAlloc(gpa, "input_data/day1/puzzle.txt", max_file_size) catch unreachable;
    defer gpa.free(main_input);

    const example_answer_1 = utils.readIntFromFile(u32, gpa, cwd, "input_data/day1/puzzle_example_answer_1.txt");
    const example_answer_2 = utils.readIntFromFile(u32, gpa, cwd, "input_data/day1/puzzle_example_answer_2.txt");
    const main_answer_1 = utils.readIntFromFile(u32, gpa, cwd, "input_data/day1/puzzle_answer_1.txt");
    const main_answer_2 = utils.readIntFromFile(u32, gpa, cwd, "input_data/day1/puzzle_answer_2.txt");

    utils.printDay(1);

    solve(example_input, .puzzle1, .example, example_answer_1);
    solve(main_input,    .puzzle1, .main,    main_answer_1);

    solve(example_input, .puzzle2, .example, example_answer_2);
    solve(main_input,    .puzzle2, .main,    main_answer_2);
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

fn solve(input: []const u8, comptime puzzle: utils.Puzzle, example: utils.Example, answer: ?u32) void {
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

    utils.checkAnswer(u32, answer, sum, puzzle, example);
}
