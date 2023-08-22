const std = @import("std");

pub fn build(b: *std.Build) void {
    const root_source_file = std.Build.FileSource.relative(SRC_DIR ++ "spin.zig");

    // Module
    const spin_mod = b.addModule("spin", .{ .source_file = root_source_file });

    // WIT bindings
    const wit_step = b.step("wit", "Generate WIT bindings for C guest modules");

    inline for (WIT_FILES, 0..) |WIT_FILE, i| {
        const wit_run = b.addSystemCommand(&.{ "wit-bindgen", "c", if (WIT_IS_IMPORTS[i]) "-i" else "-e", WIT_FILE, "--out-dir", SRC_DIR });

        wit_step.dependOn(&wit_run.step);
    }

    b.default_step.dependOn(wit_step);

    // Examples
    const examples_step = b.step("example", "Install examples");

    inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
        const example = b.addExecutable(.{
            .name = EXAMPLE_NAME,
            .root_source_file = std.Build.FileSource.relative(EXAMPLES_DIR ++ EXAMPLE_NAME ++ "/main.zig"),
            .target = .{ .cpu_arch = .wasm32, .os_tag = .wasi },
            .optimize = .ReleaseSmall,
        });
        example.addCSourceFile(.{ .file = .{ .path = SRC_DIR ++ EXAMPLE_NAME ++ ".c" }, .flags = EXAMPLES_FLAGS });
        example.addIncludePath(.{ .path = SRC_DIR });
        example.addModule("spin", spin_mod);
        example.linkLibC();

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

const WIT_DIR = "wit/";

const WIT_FILES = &.{
    WIT_DIR ++ "spin-config.wit",
    WIT_DIR ++ "spin-http.wit",
    WIT_DIR ++ "wasi-outbound-http.wit",
};

const WIT_IS_IMPORTS = &[WIT_FILES.len]bool{
    true,
    false,
    true,
};

const EXAMPLES_DIR = "examples/";

const EXAMPLE_NAMES = &.{
    "spin-config",
    "spin-http",
};

const EXAMPLES_FLAGS = &.{
    "-Wno-unused-parameter",
    "-Wno-switch-bool",
};
