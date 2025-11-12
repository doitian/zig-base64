const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{ .name = "zig-base64", .root_module = b.createModule(.{ .root_source_file = .{ .cwd_relative = "src/main.zig" }, .target = target, .optimize = optimize }) });
    exe.root_module.addAnonymousImport("base64", .{ .root_source_file = .{ .cwd_relative = "src/base64.zig" } });

    exe.addIncludePath(.{ .cwd_relative = "src" });
    b.installArtifact(exe);

    const unit_tests = b.addTest(.{ .root_module = b.createModule(.{ .root_source_file = .{ .cwd_relative = "src/base64.zig" }, .target = target, .optimize = optimize }) });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the CLI");
    run_step.dependOn(&run_cmd.step);
}
