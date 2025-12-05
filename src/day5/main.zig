const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const IdRange = struct {
    begin: u64,
    end: u64,
};

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u32, gpa, .day5, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u32 {
    _ = puzzle;

    var fresh_ids: u32 = 0;

    var id_ranges: std.ArrayList(IdRange) = .empty;
    defer id_ranges.deinit(allocator);

    var iterator = utils.lineIterator(input);

    // Get ID ranges.
    while (iterator.next()) |line| {
        // Blank line indicates the end of the ID ranges.
        if (std.mem.eql(u8, line, "")) break;

        const i = std.mem.indexOfScalar(u8, line, '-').?;

        const range = IdRange{
            .begin = std.fmt.parseInt(u64, line[0 .. i], 10) catch unreachable,
            .end   = std.fmt.parseInt(u64, line[i + 1 ..], 10) catch unreachable
        };

        id_ranges.append(allocator, range) catch unreachable;
    }

    // Check IDs.
    while (iterator.next()) |line| {
        const id = std.fmt.parseInt(u64, line, 10) catch unreachable;

        for (id_ranges.items) |range| {
            if (id >= range.begin and id <= range.end) {
                fresh_ids += 1;
                break;
            }
        }
    }

    return fresh_ids;
}
