const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const day = b.option(AdventDay, "day", "Indicates the puzzle solution to build.") orelse .all;

    const run_step = b.step("run", "Run any puzzle solutions that were built.");

    _ = target;
    _ = optimize;
    _ = day;
    _ = run_step;
}

const AdventDay = enum {
    day1,
    day2,
    day3,
    day4,
    day5,
    day6,
    day7,
    day8,
    day9,
    day10,
    day11,
    day12,
    all,
};
