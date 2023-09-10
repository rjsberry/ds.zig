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

    var module = b.createModule(.{ .source_file = .{ .path = "lib.zig" } });

    const test_step = b.step("test", "Run library tests");

    const main_test = b.addTest(.{
        .root_source_file = .{ .path = "tests/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    main_test.addModule("ds", module);

    const run_main_tests = b.addRunArtifact(main_test);
    test_step.dependOn(&run_main_tests.step);
}
