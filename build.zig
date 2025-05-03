const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("ulid", .{
        .root_source_file = b.path("src/ulid.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/ulid.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    const run_lib_tests = b.addRunArtifact(lib_tests);
    test_step.dependOn(&run_lib_tests.step);
}
