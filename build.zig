const std = @import("std");

const Error = std.os.WriteError || std.fs.File.OpenError;

pub fn build(b: *std.Build) Error!void {
    const root_source_file = std.Build.FileSource.relative("src/spin.zig");

    // Module
    const spin_mod = b.addModule("spin", .{ .source_file = .{ .path = SRC_DIR ++ "spin.zig" } });

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "spin",
        .root_source_file = root_source_file,
        .target = b.standardTargetOptions(.{}),
        .optimize = .ReleaseSafe,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Docs
    const docs_step = b.step("docs", "Emit docs");

    const docs_install = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    docs_step.dependOn(&docs_install.step);
    b.default_step.dependOn(docs_step);

    // Examples
    const examples_step = b.step("example", "Install examples");

    inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
        const example = b.addExecutable(.{
            .name = EXAMPLE_NAME,
            .root_source_file = std.Build.FileSource.relative(EXAMPLES_DIR ++ EXAMPLE_NAME ++ "/main.zig"),
            .target = .{ .cpu_arch = .wasm32, .os_tag = .wasi },
            .optimize = .ReleaseSmall,
        });
        example.addModule("spin", spin_mod);

        const example_install = b.addInstallArtifact(example, .{});

        examples_step.dependOn(&example_install.step);
    }

    b.default_step.dependOn(examples_step);

    // Tests
    const tests_step = b.step("test", "Run tests");

    const tests = b.addTest(.{
        .root_source_file = root_source_file,
    });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    b.default_step.dependOn(tests_step);

    // Code coverage report
    const cov_step = b.step("cov", "Generate code coverage report");

    const cov_run = b.addSystemCommand(&.{ "kcov", "--clean", "--include-pattern=src/", "kcov-output" });
    cov_run.addArtifactArg(tests);

    cov_step.dependOn(&cov_run.step);
    b.default_step.dependOn(cov_step);

    // Lints
    const lints_step = b.step("lint", "Run lints");

    const lints = b.addFmt(.{
        .paths = &.{ EXAMPLES_DIR, SRC_DIR, "build.zig" },
        .check = true,
    });

    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}

const SRC_DIR = "src/";

const EXAMPLES_DIR = "examples/";

const EXAMPLE_NAMES = &.{
    "config",
};
