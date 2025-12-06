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

    utils.runSolution(u64, gpa, .day6, solve);
}

fn solve(_: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    _ = puzzle;

    const static = struct {
        var rows_buffer: [16][]const u8 = undefined;
    };

    var sum: u64 = 0;

    var number_rows: std.ArrayList([]const u8) = .initBuffer(&static.rows_buffer);
    var operator_row: []const u8 = undefined;

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        if (line[0] == '+' or line[0] == '*') {operator_row = line;}
        else {
            number_rows.appendAssumeCapacity(line);

            if (number_rows.items.len > 0) std.debug.assert(line.len == number_rows.items[0].len);
        }
    }

    while (true) {
        if (operator_row.len == 0) break;

        const operator: u8 = operator_row[0];

        var begin: usize = 1;
        while (begin < operator_row.len and operator_row[begin] == ' ') begin += 1;

        operator_row = operator_row[begin ..];

        var answer: u64 = switch (operator) {
            '+' => 0,
            '*' => 1,
            else => unreachable
        };

        for (number_rows.items) |*row| {
            while (row.*[0] == ' ') row.* = row.*[1 ..];

            var i: usize = 0;
            while (i < row.len and row.*[i] != ' ') i += 1;

            const number = std.fmt.parseInt(u64, row.*[0 .. i], 10) catch unreachable;

            if (i + 1 < row.len) row.* = row.*[i + 1 ..];

            switch (operator) {
                '+' => answer += number,
                '*' => answer *= number,
                else => unreachable
            }
        }

        sum += answer;
    }

    return sum;
}
