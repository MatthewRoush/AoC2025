const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const day = b.option(AdventDay, "day", "Indicates the puzzle solution to build.") orelse .all;

    const run_step = b.step("run", "Run any puzzle solutions that were built.");

    const utils_module = b.createModule(.{
        .root_source_file = b.path("src/utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    var puzzle_artifacts_buffer: [12]*std.Build.Step.Compile = undefined;
    var puzzle_artifacts = std.ArrayList(std.meta.Child(@TypeOf(puzzle_artifacts_buffer))).initBuffer(&puzzle_artifacts_buffer);

    const days = if (day == .all) std.meta.fieldNames(AdventDay) else &.{@tagName(day)};

    for (days) |name| {
        if (std.mem.eql(u8, name, "all")) continue;

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.pathJoin(&.{"src", name, "main.zig"})),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{.name = "utils", .module = utils_module},
                },
            }),
        });

        puzzle_artifacts.appendAssumeCapacity(exe);

        b.installArtifact(exe);
    }

    for (puzzle_artifacts.items) |artifact| {
        const puzzle_run_step = b.addRunArtifact(artifact);

        puzzle_run_step.setCwd(b.path("."));

        run_step.dependOn(&puzzle_run_step.step);
    }
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
    // day9,
    // day10,
    // day11,
    // day12,
    all,
};
