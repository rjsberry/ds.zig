const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "ds",
        .root_source_file = .{ .path = "lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const test_step = b.step("test", "Run library tests");

    const run_main_tests = b.addRunArtifact(b.addTest(.{
        .root_source_file = .{ .path = "lib.zig" },
        .target = target,
        .optimize = optimize,
    }));

    test_step.dependOn(&run_main_tests.step);
}
