const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const Beam = struct {
    row: u8,
    pos: u8,
};

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u32, gpa, .day7, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u32 {
    _ = puzzle;

    var splits: u32 = 0;

    var splitter_rows: std.ArrayList([]const u8) = .empty;
    defer splitter_rows.deinit(allocator);

    var iterator = utils.lineIterator(input);

    const start_pos: u8 = @intCast(std.mem.indexOfScalar(u8, iterator.first(), 'S').?);

    // Every odd numbered line can be skipped.
    _ = iterator.next();

    while (iterator.next()) |line| {
        splitter_rows.append(allocator, line) catch unreachable;

        _ = iterator.next();
    }

    var beams_front: std.ArrayList(Beam) = .empty;
    var beams_back:  std.ArrayList(Beam) = .empty;

    defer beams_front.deinit(allocator);
    defer beams_back.deinit(allocator);

    beams_front.append(allocator, .{.row = 0, .pos = start_pos}) catch unreachable;

    while (beams_front.items[0].row < splitter_rows.items.len) {
        for (beams_front.items) |beam| {
            if (splitter_rows.items[beam.row][beam.pos] == '^') {
                const beam_left:  Beam = .{.row = beam.row + 1, .pos = beam.pos - 1};
                const beam_right: Beam = .{.row = beam.row + 1, .pos = beam.pos + 1};

                var append_left  = true;
                var append_right = true;

                for (beams_back.items) |other| {
                    append_left = append_left and (other.row != beam_left.row or other.pos != beam_left.pos);
                    append_right = append_right and (other.row != beam_right.row or other.pos != beam_right.pos);
                }

                if (append_left)  beams_back.append(allocator, beam_left) catch unreachable;
                if (append_right) beams_back.append(allocator, beam_right) catch unreachable;

                if (append_left or append_right) splits += 1;
            } else {
                beams_back.append(allocator, .{.row = beam.row + 1, .pos = beam.pos}) catch unreachable;
            }
        }

        const temp = beams_front;
        beams_front = beams_back;
        beams_back = temp;
        beams_back.clearRetainingCapacity();
    }

    return splits;
}
