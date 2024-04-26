const std = @import("std");

pub fn build(b: *std.Build) void {
    // Dependencies
    const spin_dep = b.dependency("spin", .{});
    const spin_mod = spin_dep.module("spin");

    // Package test
    const test_step = b.step("test", "Install test");

    const is_test_up = b.option(bool, "up", "Run test") orelse false;

    if (is_test_up) {
        const test_run = b.addSystemCommand(&.{ "spin", "build", "--up", "--listen", "localhost:9900" });
        test_step.dependOn(&test_run.step);
    } else {
        const exe = b.addExecutable(.{
            .name = "test",
            .optimize = .ReleaseSmall,
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi }),
        });
        exe.root_module.addImport("spin", spin_mod);

        const test_install = b.addInstallArtifact(exe, .{});
        test_step.dependOn(&test_install.step);
    }

    b.default_step.dependOn(test_step);
}
