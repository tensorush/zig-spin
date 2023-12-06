const std = @import("std");

pub fn build(b: *std.Build) void {
    // Dependencies
    const spin_dep = b.dependency("spin", .{});
    const spin_art = spin_dep.artifact("spin");
    const spin_mod = spin_dep.module("spin");

    // Test
    const test_step = b.step("test", "Install test");

    const spin_up = b.option(bool, "up", "Run test") orelse false;

    if (spin_up) {
        const test_run = b.addSystemCommand(&.{ "spin", "build", "--up", "--listen", "localhost:9900" });
        test_step.dependOn(&test_run.step);
    } else {
        const exe = b.addExecutable(.{
            .name = "test",
            .root_source_file = std.Build.FileSource.relative("src/main.zig"),
            .target = .{ .cpu_arch = .wasm32, .os_tag = .wasi },
            .optimize = .ReleaseSmall,
        });
        exe.addModule("spin", spin_mod);
        exe.linkLibrary(spin_art);

        const test_install = b.addInstallArtifact(exe, .{});
        test_step.dependOn(&test_install.step);
    }

    b.default_step.dependOn(test_step);
}
