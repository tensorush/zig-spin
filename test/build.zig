const std = @import("std");

pub fn build(b: *std.Build) void {
    // Dependencies
    const spin_dep = b.dependency("spin", .{});
    const spin_lib = spin_dep.artifact("spin");
    const spin_mod = spin_dep.module("spin");

    // Examples
    const examples_step = b.step("example", "Install examples");

    const spin_up = b.option(bool, "up", "Run examples") orelse false;

    if (spin_up) {
        const example_run = b.addSystemCommand(&.{ "spin", "build", "--up", "--listen", "localhost:9000" });
        examples_step.dependOn(&example_run.step);
    } else {
        const example = b.addExecutable(.{
            .name = "http-in",
            .root_source_file = std.Build.FileSource.relative("src/main.zig"),
            .target = .{ .cpu_arch = .wasm32, .os_tag = .wasi },
            .optimize = .ReleaseSmall,
        });
        example.linkLibrary(spin_lib);
        example.addModule("spin", spin_mod);

        const example_install = b.addInstallArtifact(example, .{});
        examples_step.dependOn(&example_install.step);
    }

    // Lints
    const lints_step = b.step("lint", "Run lints");

    const lints = b.addFmt(.{
        .paths = &.{ "src", "build.zig" },
        .check = true,
    });

    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}
