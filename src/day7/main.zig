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

    utils.runSolution(u64, gpa, .day7, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
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

    switch (puzzle) {
        .puzzle1 => {
            var splits: u64 = 0;

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
        },
        .puzzle2 => {
            // I was stuck on this so I did some searching (query was "plinko total paths") and found https://goldenberg.biology.utah.edu/courses/biol3550/courseMaterial/slides/lect7_plinkoProbabilities.pdf
            // which led me to https://en.wikipedia.org/wiki/Pascal%27s_triangle.
            // After many hours and failing to find a useful pattern, I found the solution.
            //
            // I'm going to use a plinko board for this explanation, you can also see "diagram.png" for a poorly made visual example.
            // Every peg will have a number on it which represents the number of paths there are from it to the top peg.
            // As with Pascal's Triangle, the "outside" pegs are all one, easy enough.
            // For every other peg, you do not just sum the pegs directly above it.
            // Some pegs are missing, you instead sum the pegs directly above the current peg IF they are NOT missing.
            // You also add the value of the peg above those two pegs (between them on the row above them) if that peg IS missing.
            //
            // Once that is done, you go through the last row.
            // If the peg is not missing, you add its value twice to the sum of total paths, if it is missing you add its value once.
            // If any pegs are missing in the row above the last, you add their value once to the sum of total paths.
            // With that you now have the total number of paths for the broken plinko board you are using. You really should just get a new one.

            var paths: u64 = 0;

            var   triangle_row_current = allocator.alloc(u64, splitter_rows.items.len + 1) catch unreachable;
            const triangle_row_prev_1  = allocator.alloc(u64, triangle_row_current.len) catch unreachable;
            const triangle_row_prev_2  = allocator.alloc(u64, triangle_row_current.len) catch unreachable;

            defer allocator.free(triangle_row_current);
            defer allocator.free(triangle_row_prev_1);
            defer allocator.free(triangle_row_prev_2);

            for (splitter_rows.items, 0 ..) |row, row_i| {
                const max_row_splitters  = row_i + 1;
                const first_splitter_pos = start_pos - row_i;

                for (0 .. max_row_splitters) |col_i| {
                    const pos = first_splitter_pos + col_i * 2;

                    if (col_i == 0 or col_i == max_row_splitters - 1) {
                        std.debug.assert(row[pos] == '^');
                        triangle_row_current[col_i] = 1;

                        if (row_i == splitter_rows.items.len - 1) paths += 2;
                    } else {
                        triangle_row_current[col_i] = 0;

                        if (splitter_rows.items[row_i - 1][pos - 1] == '^') triangle_row_current[col_i] += triangle_row_prev_1[col_i - 1];
                        if (splitter_rows.items[row_i - 1][pos + 1] == '^') triangle_row_current[col_i] += triangle_row_prev_1[col_i];
                        if (splitter_rows.items[row_i - 2][pos]     == '.') triangle_row_current[col_i] += triangle_row_prev_2[col_i - 1];

                        if (row_i == splitter_rows.items.len - 1) {
                            // Last row.
                            if      (row[pos] == '^') {paths += triangle_row_current[col_i] * 2;}
                            else if (row[pos] == '.') {paths += triangle_row_current[col_i];}
                            else {unreachable;}
                        } else if (row_i == splitter_rows.items.len - 2) {
                            // Second to last row.
                            if (splitter_rows.items[row_i][pos] == '.') {paths += triangle_row_current[col_i];}
                        }
                    }
                }

                @memcpy(triangle_row_prev_2, triangle_row_prev_1);
                @memcpy(triangle_row_prev_1, triangle_row_current);
            }

            return paths;
        }
    }
}
