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

    utils.runSolution(u64, gpa, .day10, solve);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, comptime puzzle: utils.Puzzle) u64 {
    if (puzzle == .puzzle2) return 0;

    var button_presses: u64 = 0;

    var machines: std.ArrayList(Machine) = .empty;
    defer machines.deinit(allocator);

    var iterator = utils.lineIterator(input);

    while (iterator.next()) |line| {
        var machine: Machine = undefined;

        std.debug.assert(line[0] == '[');
        const lights_start = 1;
        const lights_end = std.mem.indexOfScalar(u8, line, ']') orelse unreachable;

        machine.lights_count = @intCast(lights_end - lights_start);

        machine.lights = .initEmpty();
        for (line[lights_start..lights_end], 0..) |state, i| {
            switch (state) {
                else => unreachable,
                '.' => {},
                '#' => machine.lights.set(i),
            }
        }

        machine.buttons = @splat(.initEmpty());
        var button_index: usize = 0;

        var int_start: usize = undefined;
        var int_end:   usize = lights_end + 2; // Also used as "current character".

        tokenizer: switch (line[int_end]) {
            else => unreachable,
            '(' => {
                int_start = int_end + 1;
                int_end = int_start + 1;
                continue :tokenizer line[int_end];
            },
            '0' ... '9' => {
                int_end += 1;
                continue :tokenizer line[int_end];
            },
            ',' => {
                const light_index = std.fmt.parseInt(u16, line[int_start..int_end], 10) catch unreachable;
                machine.buttons[button_index].set(light_index);

                int_start = int_end + 1;
                int_end = int_start + 1;

                continue :tokenizer line[int_end];
            },
            ')' => {
                const light_index = std.fmt.parseInt(u16, line[int_start..int_end], 10) catch unreachable;
                machine.buttons[button_index].set(light_index);
                button_index += 1;

                int_end += 2;

                continue :tokenizer line[int_end];
            },
            '{' => break :tokenizer,
        }

        machine.button_count = @intCast(button_index);

        var joltage_index: usize = 0;

        int_start = undefined;

        tokenizer: switch (line[int_end]) {
            else => unreachable,
            '{' => {
                int_start = int_end + 1;
                int_end = int_start + 1;
                continue :tokenizer line[int_end];
            },
            '0' ... '9' => {
                int_end += 1;
                continue :tokenizer line[int_end];
            },
            ',' => {
                const joltage = std.fmt.parseInt(u16, line[int_start..int_end], 10) catch unreachable;
                machine.joltages[joltage_index] = joltage;
                joltage_index += 1;

                int_start = int_end + 1;
                int_end = int_start + 1;

                continue :tokenizer line[int_end];
            },
            '}' => {
                const joltage = std.fmt.parseInt(u16, line[int_start..int_end], 10) catch unreachable;
                machine.joltages[joltage_index] = joltage;

                break :tokenizer;
            }
        }

        machines.append(allocator, machine) catch unreachable;
        // std.debug.print("{f}\n", .{machine});
    }

    for (machines.items) |machine| {
        // Each branch is initialized with the button corresponding to its index.
        // From there, a BFS is performed, where the new nodes are the buttons that have not been pressed.
        // Each button can be pressed at most once.
        var press_branches: [max_buttons]?Queue(BranchNode) = @splat(.empty);
        defer {
            for (0..machine.button_count) |i| {
                if (press_branches[i] != null) press_branches[i].?.deinit(allocator);
            }
        }

        for (0..machine.button_count) |i| {
            press_branches[i].?.append(allocator, .{
                .lights       = machine.buttons[i],
                .presses      = 1,
                .prev_pressed = undefined,
            }) catch unreachable;
            press_branches[i].?.list.items[0].prev_pressed[0] = @intCast(i);
        }

        branches_bfs: while (true) {
            for (0..machine.button_count) |i| {
                if (press_branches[i] == null) continue;
                const current = press_branches[i].?.pop() orelse unreachable;

                if (current.lights.eql(machine.lights)) {
                    button_presses += current.presses;
                    break :branches_bfs;
                } else if (current.presses == machine.button_count) {
                    press_branches[i].?.deinit(allocator);
                    press_branches[i] = null;
                }

                var remaining_buttons_mask: Machine.IndicatorLights = .initEmpty();

                for (0..machine.button_count) |new| {
                    var is_new = true;
                    for (current.prev_pressed[0..current.presses]) |prev| {
                        if (new == prev) {
                            is_new = false;
                            break;
                        }
                    }

                    if (is_new) {
                        const new_mask = machine.buttons[new];

                        remaining_buttons_mask.setUnion(new_mask);

                        var prev_pressed = current.prev_pressed;
                        prev_pressed[current.presses] = @intCast(new);

                        press_branches[i].?.append(allocator, .{
                            .lights       = current.lights.xorWith(new_mask),
                            .presses      = current.presses + 1,
                            .prev_pressed = prev_pressed,
                        }) catch unreachable;
                    }
                }
            }
        }
    }

    return button_presses;
}

const max_lights   = 16;
const max_buttons  = 16;
const max_joltages = 16;

const Machine = struct {
    lights_count: u8,
    lights:       IndicatorLights,
    buttons:      [max_buttons]IndicatorLights,
    button_count: u8,
    joltages:     [max_joltages]u16,

    pub const IndicatorLights = std.bit_set.IntegerBitSet(max_lights);

    /// Note: Bit index 0 is the rightmost bit, which is different from
    /// the indicator lights in the manual, where index 0 is the leftmost.
    /// This means the bit masks will look reversed from the expected order.
    pub fn format(self: *const Machine, writer: *std.Io.Writer) !void {
        try writer.writeAll("Machine{ [");

        try writer.printInt(self.lights.mask, 2, .lower, .{
            .width = self.lights_count,
            .fill = '0',
        });

        try writer.writeAll("]");

        for (self.buttons[0..self.button_count]) |button| {
            try writer.writeAll(" (");

            try writer.printInt(button.mask, 2, .lower, .{
                .width = self.lights_count,
                .fill = '0',
            });

            try writer.writeAll(")");
        }

        try writer.writeAll(" {");

        for (self.joltages[0..self.lights_count], 0..) |joltage, i| {
            if (i > 0) try writer.writeAll(",");
            try writer.print("{d}", .{joltage});
        }

        try writer.writeAll("}");

        try writer.writeAll(" }");
    }
};

fn Queue(T: type) type {
    return struct {
        const Self = @This();

        start: usize,
        list:  std.ArrayList(T),

        pub const empty: Self = .{.start = 0, .list = .empty};

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.list.deinit(allocator);
            self.* = undefined;
        }

        pub fn append(self: *Self, allocator: std.mem.Allocator, item: T) std.mem.Allocator.Error!void {
            try self.list.append(allocator, item);
        }

        pub fn pop(self: *Self) ?T {
            if (self.start >= self.list.items.len) return null;
            const item = self.list.items[self.start];
            self.start += 1;
            return item;
        }
    };
}

const BranchNode = struct {
    lights:       Machine.IndicatorLights,
    presses:      u16,
    prev_pressed: [max_buttons]u8,
};
