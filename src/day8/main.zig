const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");

const example_boxes_count = 20;

const example_max_pairs = 10;
const max_pairs = 1000;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const Vector3 = struct {
    const Self = @This();

    x: i32,
    y: i32,
    z: i32,

    pub fn distToSqrd(self: Self, other: Self) u64 {
        const x: i64 = self.x - other.x;
        const y: i64 = self.y - other.y;
        const z: i64 = self.z - other.z;

        return @as(u64, @intCast(x*x)) + @as(u64, @intCast(y*y)) + @as(u64, @intCast(z*z));
    }
};

const Pair = struct {
    a: u16,
    b: u16,
    dist: u64,

    pub fn lessThan(_: void, lhs: Pair, rhs: Pair) bool {
        return lhs.dist < rhs.dist;
    }
};

pub fn main() void {
    const gpa, const debug = switch (builtin.mode) {
        .ReleaseFast, .ReleaseSmall => .{std.heap.smp_allocator, false},
        .Debug, .ReleaseSafe => .{debug_allocator.allocator(), true},
    };

    defer if (debug) std.debug.assert(debug_allocator.deinit() == .ok);

    utils.runSolution(u64, gpa, .day8, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    var boxes: std.ArrayList(Vector3) = .empty;
    defer boxes.deinit(allocator);

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        const comma_1 = std.mem.indexOfScalar(u8, line, ',').?;
        const comma_2 = std.mem.indexOfScalarPos(u8, line, comma_1 + 1, ',').?;

        const box = Vector3{
            .x = std.fmt.parseInt(i32, line[0 .. comma_1], 10) catch unreachable,
            .y = std.fmt.parseInt(i32, line[comma_1 + 1 .. comma_2], 10) catch unreachable,
            .z = std.fmt.parseInt(i32, line[comma_2 + 1 ..], 10) catch unreachable,
        };

        boxes.append(allocator, box) catch unreachable;
    }

    var pairs: std.ArrayList(Pair) = .empty;
    defer pairs.deinit(allocator);

    // Pair all the boxes.
    for (boxes.items, 0 ..) |box, i| {
        // Only looping over the boxes after the current box prevents redundant pairing.
        for (boxes.items[i + 1 ..], i + 1 ..) |other_box, k| {
            std.debug.assert(i != k);

            pairs.append(allocator, .{
                .a = @intCast(i),
                .b = @intCast(k),
                .dist = box.distToSqrd(other_box),
            }) catch unreachable;
        }
    }

    std.mem.sortUnstable(Pair, pairs.items, {}, Pair.lessThan);

    switch (puzzle) {
        .puzzle1 => {
            var circuits: std.ArrayList(std.AutoArrayHashMapUnmanaged(u16, void)) = .empty;
            defer {
                for (circuits.items) |*circuit| {
                    circuit.deinit(allocator);
                }

                circuits.deinit(allocator);
            }

            // Use the first n pairs.
            if (boxes.items.len == example_boxes_count) {
                pairs.shrinkAndFree(allocator, example_max_pairs);
            } else {
                std.debug.assert(pairs.items.len > max_pairs);
                pairs.shrinkAndFree(allocator, max_pairs);
            }

            // Group box pairs into circuits.
            for (pairs.items, 0 ..) |pair, i| {
                var circuit_i = circuits.items.len;

                // Check if the current pair is associated with a circuit.
                for (circuits.items, 0 ..) |*circuit, k| {
                    if (circuit.contains(pair.a) or circuit.contains(pair.b)) {
                        circuit.put(allocator, pair.a, {}) catch unreachable;
                        circuit.put(allocator, pair.b, {}) catch unreachable;

                        circuit_i = k;

                        break;
                    }
                }

                if (circuit_i == circuits.items.len) {
                    circuits.append(allocator, .empty) catch unreachable;

                    circuits.items[circuit_i].putNoClobber(allocator, pair.a, {}) catch unreachable;
                    circuits.items[circuit_i].putNoClobber(allocator, pair.b, {}) catch unreachable;
                }

                var circuit = circuits.items[circuit_i];

                // Pull other pairs into the circuit.
                for (pairs.items[i + 1 ..]) |other_pair| {
                    if (pair.a == other_pair.a or pair.a == other_pair.b or pair.b == other_pair.a or pair.b == other_pair.b) {

                        circuit.put(allocator, other_pair.a, {}) catch unreachable;
                        circuit.put(allocator, other_pair.b, {}) catch unreachable;
                    }
                }
            }

            // Combine circuits that have a shared box.
            compression_loop: while (true) {
                var compressed_any = false;

                outer_for_loop: for (circuits.items, 0 ..) |*circuit, i| {
                    for (circuit.keys()) |box_i| {
                        for (circuits.items, 0 ..) |other_circuit, k| {
                            if (i == k) continue;

                            if (other_circuit.contains(box_i)) {
                                compressed_any = true;

                                for (other_circuit.keys()) |key| circuit.put(allocator, key, {}) catch unreachable;

                                var removed = circuits.swapRemove(k);
                                removed.deinit(allocator);

                                break :outer_for_loop;
                            }
                        }
                    }
                }

                if (!compressed_any) break :compression_loop;
            }

            var biggest_circuits: [3]usize = .{0, 0, 0};

            for (circuits.items) |circuit| {
                const len = circuit.entries.len;

                var min_index: usize = 0;

                if (biggest_circuits[min_index] > biggest_circuits[1]) min_index = 1;
                if (biggest_circuits[min_index] > biggest_circuits[2]) min_index = 2;

                // I incorrectly wrote this without the if statement and spent a day scrutinizing every other part of the algorithm.
                if (len > biggest_circuits[min_index]) biggest_circuits[min_index] = len;
            }

            var product: u64 = 1;
            for (&biggest_circuits) |size| product *= size;

            return product;
        },
        .puzzle2 => {
            var circuit: std.AutoArrayHashMapUnmanaged(u16, void) = .empty;
            defer circuit.deinit(allocator);

            var pair_i: usize = 0;

            var loose_pairs: std.ArrayList(Pair) = .empty;
            defer loose_pairs.deinit(allocator);

            var loose_pairs_to_remove: std.ArrayList(usize) = .empty;
            defer loose_pairs_to_remove.deinit(allocator);

            circuit.put(allocator, pairs.items[pair_i].a, {}) catch unreachable;
            circuit.put(allocator, pairs.items[pair_i].b, {}) catch unreachable;

            pair_i += 1;

            while (circuit.entries.len != boxes.items.len) {
                const pair = pairs.items[pair_i];
                pair_i += 1;

                var added_to_circuit = false;

                if (circuit.contains(pair.a) or circuit.contains(pair.b)) {
                    circuit.put(allocator, pair.a, {}) catch unreachable;
                    circuit.put(allocator, pair.b, {}) catch unreachable;

                    added_to_circuit = true;

                    loose_pairs_to_remove.clearRetainingCapacity();

                    for (loose_pairs.items, 0 ..) |other_pair, i| {
                        if (circuit.contains(other_pair.a) or circuit.contains(other_pair.b)) {
                            circuit.put(allocator, other_pair.a, {}) catch unreachable;
                            circuit.put(allocator, other_pair.b, {}) catch unreachable;

                            loose_pairs_to_remove.append(allocator, i) catch unreachable;
                        }
                    }

                    loose_pairs.orderedRemoveMany(loose_pairs_to_remove.items);
                }

                if (!added_to_circuit) {
                    loose_pairs.append(allocator, pair) catch unreachable;
                }
            }

            const pair = pairs.items[pair_i - 1];

            const box_a = boxes.items[pair.a];
            const box_b = boxes.items[pair.b];

            return @as(u64, @intCast(box_a.x)) * @as(u64, @intCast(box_b.x));
        }
    }
}
