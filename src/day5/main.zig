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

    utils.runSolution(u64, gpa, .day5, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    var fresh_ids: u64 = 0;

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

    switch (puzzle) {
        .puzzle1 => {
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
        },
        .puzzle2 => {
            var indicies_to_remove: std.ArrayList(usize) = std.ArrayList(usize).initCapacity(allocator, 16) catch unreachable;
            defer indicies_to_remove.deinit(allocator);

            var compressed = false;

            while (!compressed) {
                var i: usize = 0;

                var removed_any = false;

                while (i < id_ranges.items.len) {
                    const range = &id_ranges.items[i];

                    indicies_to_remove.clearRetainingCapacity();

                    for (id_ranges.items, 0 ..) |other, k| {
                        if (i == k) continue;

                        if (other.begin >= range.begin and other.end <= range.end) {
                            indicies_to_remove.appendAssumeCapacity(k);
                        } else if (other.begin >= range.begin and other.begin <= range.end and other.end > range.end) {
                            range.end = other.end;
                            indicies_to_remove.appendAssumeCapacity(k);
                        } else if (other.begin < range.begin and other.end >= range.begin and other.end <= range.end) {
                            range.begin = other.begin;
                            indicies_to_remove.appendAssumeCapacity(k);
                        }
                    }

                    if (indicies_to_remove.items.len > 0) {
                        id_ranges.orderedRemoveMany(indicies_to_remove.items);

                        i = indicies_to_remove.items[0];
                        removed_any = true;
                    } else {
                        i += 1;
                    }
                }

                compressed = compressed or !removed_any;
            }

            for (id_ranges.items) |range| {
                fresh_ids += range.end - range.begin + 1;
            }
        }
    }

    return fresh_ids;
}
