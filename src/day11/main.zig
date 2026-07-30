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

    utils.runSolution(u64, gpa, .day11, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    var device_pool: std.ArrayList(Device) = .empty;
    defer device_pool.deinit(allocator);

    var you_index: u16 = invalid_index; // Only for puzzle 1.
    var svr_index: u16 = invalid_index; // Only for puzzle 2.
    var dac_index: u16 = invalid_index; // Only for puzzle 2.
    var fft_index: u16 = invalid_index; // Only for puzzle 2.
    var out_index: u16 = invalid_index;

    {
        var temporary_mapping_of_devices_to_indices: std.HashMapUnmanaged([3]u8, u16, ThreeByteBufferHashMapContext, std.hash_map.default_max_load_percentage) = .empty;
        defer temporary_mapping_of_devices_to_indices.deinit(allocator);

        var iterator = utils.lineIterator(input);

        while (iterator.next()) |line| {
            const device_id: [3]u8 = line[0..3].*;

            var gop_device = temporary_mapping_of_devices_to_indices.getOrPut(allocator, device_id) catch unreachable;
            if (!gop_device.found_existing) {
                device_pool.append(allocator, .{
                    .id             = device_id,
                    .inputs         = undefined,
                    .inputs_len     = 0,
                    .outputs        = undefined,
                    .outputs_len    = 0,
                    .paths_to_end   = 0,
                    .already_walked = false,
                    .depth          = 0,
                }) catch unreachable;

                gop_device.value_ptr.* = @intCast(device_pool.items.len - 1);
            }

            const device_index: u16 = gop_device.value_ptr.*;
            gop_device = undefined; // Don't use after this point.

            if      (you_index == invalid_index and std.mem.eql(u8, &device_id, "you")) {you_index = device_index;}
            else if (svr_index == invalid_index and std.mem.eql(u8, &device_id, "svr")) {svr_index = device_index;}
            else if (dac_index == invalid_index and std.mem.eql(u8, &device_id, "dac")) {dac_index = device_index;}
            else if (fft_index == invalid_index and std.mem.eql(u8, &device_id, "fft")) {fft_index = device_index;}

            var start: usize = 5;

            while (start < line.len) : (start += 4) {
                const other_id: [3]u8 = line[start..][0..3].*;

                var gop_other = temporary_mapping_of_devices_to_indices.getOrPut(allocator, other_id) catch unreachable;
                if (!gop_other.found_existing) {
                    device_pool.append(allocator, .{
                        .id             = other_id,
                        .inputs         = undefined,
                        .inputs_len     = 0,
                        .outputs        = undefined,
                        .outputs_len    = 0,
                        .paths_to_end   = 0,
                        .already_walked = false,
                        .depth          = 0,
                    }) catch unreachable;

                    gop_other.value_ptr.* = @intCast(device_pool.items.len - 1);
                }

                const other_index = gop_other.value_ptr.*;
                gop_other = undefined; // Don't use after this point.

                if (out_index == invalid_index and std.mem.eql(u8, &other_id, "out")) out_index = other_index;

                // Connect other device to the current device.
                const other_input_len_ptr = &device_pool.items[other_index].inputs_len;
                device_pool.items[other_index].inputs[other_input_len_ptr.*] = device_index;
                other_input_len_ptr.* += 1;

                // Connect the current device to the other device.
                const device_output_len_ptr = &device_pool.items[device_index].outputs_len;
                device_pool.items[device_index].outputs[device_output_len_ptr.*] = other_index;
                device_output_len_ptr.* += 1;
            }
        }
    }

    // Pointers to items in 'device_pool' are now stable from here.

    std.debug.assert(out_index != invalid_index);

    var node_stack: std.ArrayList(PathNode) = .empty;
    defer node_stack.deinit(allocator);

    switch (puzzle) {
        .puzzle1 => {
            std.debug.assert(you_index != invalid_index);

            node_stack.append(allocator, .{
                .device          = &device_pool.items[you_index],
                .path_walked     = undefined,
                .path_walked_len = 0,
            }) catch unreachable;

            while (node_stack.items.len > 0) {
                const current_node = node_stack.pop().?;

                for (current_node.device.outputs[0..current_node.device.outputs_len]) |output_index| {
                    const output_device = &device_pool.items[output_index];

                    if (output_index == out_index) {
                        std.debug.assert(current_node.device.outputs_len == 1);

                        // This node goes to the 'out' node, so this is the end. Now go though the 'path_walked' array and
                        // increase the 'paths_to_end' of those devices by one.

                        current_node.device.paths_to_end = 1;
                        current_node.device.already_walked = true;

                        for (current_node.path_walked[0..current_node.path_walked_len]) |parent_device| {
                            parent_device.paths_to_end += 1;
                            parent_device.already_walked = true;
                        }
                    } else {
                        if (output_device.already_walked) {
                            // This output node has already been processed, so just take its 'paths_to_end' count and
                            // add that to the current device and the devices in the 'path_walked' array.

                            current_node.device.paths_to_end += output_device.paths_to_end;

                            for (current_node.path_walked[0..current_node.path_walked_len]) |parent_device| {
                                parent_device.paths_to_end += output_device.paths_to_end;
                                parent_device.already_walked = true;
                            }
                        } else {
                            var output_path_walked = current_node.path_walked;
                            output_path_walked[current_node.path_walked_len] = current_node.device;

                            node_stack.append(allocator, .{
                                .device          = output_device,
                                .path_walked     = output_path_walked,
                                .path_walked_len = current_node.path_walked_len + 1,
                            }) catch unreachable;
                        }
                    }
                }
            }

            return device_pool.items[you_index].paths_to_end;
        },
        .puzzle2 => {
            std.debug.assert(svr_index != invalid_index);
            std.debug.assert(dac_index != invalid_index);
            std.debug.assert(fft_index != invalid_index);

            // 'svr' never has inputs.
            std.debug.assert(device_pool.items[svr_index].inputs_len == 0);

            {
                var device_stack: std.ArrayList(*Device) = .empty;
                defer device_stack.deinit(allocator);

                device_stack.append(allocator, &device_pool.items[svr_index]) catch unreachable;

                while (device_stack.items.len > 0) {
                    const current_device = device_stack.pop().?;

                    for (current_device.outputs[0..current_device.outputs_len]) |output_index| {
                        const output_device = &device_pool.items[output_index];

                        if (output_device.depth != 0) continue;

                        output_device.depth = current_device.depth + 1;
                        device_stack.append(allocator, output_device) catch unreachable;
                    }
                }
            }

            const dac = &device_pool.items[dac_index];
            const fft = &device_pool.items[fft_index];

            std.debug.assert(dac.depth != fft.depth);

            const top_device_index, const bottom_device_index = if (dac.depth < fft.depth)
                .{dac_index, fft_index}
            else
                .{fft_index, dac_index};

            const paths_svr_to_top    = findPathsFromNodeToLowerNode(allocator, &node_stack, &device_pool, svr_index,           top_device_index);
            const paths_top_to_bottom = findPathsFromNodeToLowerNode(allocator, &node_stack, &device_pool, top_device_index,    bottom_device_index);
            const paths_bottom_to_out = findPathsFromNodeToLowerNode(allocator, &node_stack, &device_pool, bottom_device_index, out_index);

            return paths_svr_to_top * paths_top_to_bottom * paths_bottom_to_out;
        },
    }
}

const invalid_index: u16 = 9999;

const Device = struct {
    id:             [3]u8,
    inputs:         [40]u16,
    inputs_len:     u8,
    outputs:        [40]u16,
    outputs_len:    u8,
    paths_to_end:   u32,
    already_walked: bool,
    /// Measured from the 'svr' node, only used for puzzle 2.
    depth:          u8,
};

const PathNode = struct {
    device:          *Device,
    path_walked:     [32]*Device,
    path_walked_len: u8,
};

fn findPathsFromNodeToLowerNode(
    allocator:   std.mem.Allocator,
    node_stack:  *std.ArrayList(PathNode),
    device_pool: *const std.ArrayList(Device),
    start_index: u16,
    end_index:   u16
) u64 {
    // Clear previous state
    node_stack.clearRetainingCapacity();
    for (device_pool.items) |*device| {
        device.already_walked = false;
    }

    // Will not search below this level.
    const end_depth = device_pool.items[end_index].depth;

    node_stack.append(allocator, .{
        .device          = &device_pool.items[start_index],
        .path_walked     = undefined,
        .path_walked_len = 0,
    }) catch unreachable;

    while (node_stack.items.len > 0) {
        const current_node = node_stack.pop().?;

        for (current_node.device.outputs[0..current_node.device.outputs_len]) |output_index| {
            if (output_index == end_index) {
                // This node goes to the end node, so this is the end. Now go though the 'path_walked' array and
                // increase the 'paths_to_end' of those devices by one.

                current_node.device.paths_to_end = 1;
                current_node.device.already_walked = true;

                for (current_node.path_walked[0..current_node.path_walked_len]) |parent_device| {
                    parent_device.paths_to_end += 1;
                    parent_device.already_walked = true;
                }
            } else {
                const output_device = &device_pool.items[output_index];

                // This device is a sibling to the end device, so stop walking this path.
                if (output_device.depth == end_depth) continue;

                std.debug.assert(output_device.depth < end_depth);

                if (output_device.already_walked) {
                    // This output node has already been processed, so just take its 'paths_to_end' count and
                    // add that to the current device and the devices in the 'path_walked' array.

                    current_node.device.paths_to_end += output_device.paths_to_end;

                    for (current_node.path_walked[0..current_node.path_walked_len]) |parent_device| {
                        parent_device.paths_to_end += output_device.paths_to_end;
                        parent_device.already_walked = true;
                    }
                } else {
                    var output_path_walked = current_node.path_walked;
                    output_path_walked[current_node.path_walked_len] = current_node.device;

                    node_stack.append(allocator, .{
                        .device          = output_device,
                        .path_walked     = output_path_walked,
                        .path_walked_len = current_node.path_walked_len + 1,
                    }) catch unreachable;
                }
            }
        }
    }

    return device_pool.items[start_index].paths_to_end;
}

const ThreeByteBufferHashMapContext = struct {
    pub fn eql(self: @This(), a: [3]u8, b: [3]u8) bool {
        _ = self;
        return a[0] == b[0] and
               a[1] == b[1] and
               a[2] == b[2];
    }

    pub fn hash(self: @This(), k: [3]u8) u64 {
        _ = self;
        const int: u24 = @bitCast(k);
        return std.hash.int(@as(u64, int));
    }
};
