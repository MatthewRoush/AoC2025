const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

const max_file_size = 1024 * 1024;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    const cwd = std.fs.cwd();

    const example_input = cwd.readFileAlloc(gpa, "input_data/day2/puzzle_example.txt", max_file_size) catch unreachable;
    defer gpa.free(example_input);

    const main_input = cwd.readFileAlloc(gpa, "input_data/day2/puzzle.txt", max_file_size) catch unreachable;
    defer gpa.free(main_input);

    const example_answer_1 = utils.readIntFromFile(u64, gpa, cwd, "input_data/day2/puzzle_example_answer_1.txt");
    const main_answer_1 = utils.readIntFromFile(u32, gpa, cwd, "input_data/day2/puzzle_answer_1.txt");

    utils.printDay(2);

    solve(example_input, .puzzle1, .example, example_answer_1);
    solve(main_input,    .puzzle1, .main,    null);
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

fn solve(input: []const u8, comptime puzzle: utils.Puzzle, example: utils.Example, answer: ?u64) void {
    var sum: u64 = 0;

    var iterator = std.mem.splitScalar(u8, input, ',');

    while (iterator.next()) |range| {
        if (std.mem.indexOfScalar(u8, range, '-')) |i| {
            const range_begin_str = range[0 .. i];
            const range_end_str   = range[i + 1 ..];

            if (range_begin_str.len == range_end_str.len and range_begin_str.len & 1 == 1) continue;

            const range_begin = std.fmt.parseInt(u64, range[0 .. i], 10) catch unreachable;
            const range_end   = std.fmt.parseInt(u64, range[i + 1 ..], 10) catch unreachable;

            for (range_begin .. range_end + 1) |x| {
                if (isDoubleSequence(x)) sum += x;
            }
        }
    }

    utils.checkAnswer(u64, answer, sum, puzzle, example);
}
