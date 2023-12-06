const std = @import("std");

pub fn build(b: *std.Build) void {
    // Dependencies
    const spin_dep = b.dependency("spin", .{});
    const spin_art = spin_dep.artifact("spin");
    const spin_mod = spin_dep.module("spin");

    // Executable
    const exe_step = b.step("exe", "Run executable");

    const spin_up = b.option(bool, "up", "Run tests") orelse false;

    if (spin_up) {
        const exe_run = b.addSystemCommand(&.{ "spin", "build", "--up", "--listen", "localhost:9900" });
        exe_step.dependOn(&exe_run.step);
    } else {
        const exe = b.addExecutable(.{
            .name = "spin-test",
            .root_source_file = std.Build.FileSource.relative("src/main.zig"),
            .target = .{ .cpu_arch = .wasm32, .os_tag = .wasi },
            .optimize = .ReleaseSmall,
        });
        exe.addModule("spin", spin_mod);
        exe.linkLibrary(spin_art);

        const exe_install = b.addInstallArtifact(exe, .{});
        exe_step.dependOn(&exe_install.step);
    }

    b.default_step.dependOn(exe_step);
}
