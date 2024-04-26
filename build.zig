const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = .ReleaseSmall;
    const root_source_file = b.path("src/spin.zig");
    const version = .{ .major = 0, .minor = 6, .patch = 2 };
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi });

    // Module
    const spin_mod = b.addModule("spin", .{
        .target = target,
        .link_libc = true,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    spin_mod.addCSourceFiles(.{ .root = b.path(INC_DIR), .files = WIT_C_FILES, .flags = WIT_C_FLAGS });
    spin_mod.addIncludePath(b.path(INC_DIR));

    // WIT C bindings
    const wit_step = b.step("wit", "Generate WIT C bindings");

    inline for (WIT_NAMES, WIT_IS_IMPORTS) |WIT_NAME, WIT_IS_IMPORT| {
        const wit_run = b.addSystemCommand(&.{
            "wit-bindgen",                     "c",
            if (WIT_IS_IMPORT) "-i" else "-e", WIT_DIR ++ WIT_NAME ++ ".wit",
            "--out-dir",                       INC_DIR,
        });

        wit_step.dependOn(&wit_run.step);
    }

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "spin",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    lib.addCSourceFiles(.{ .root = b.path(INC_DIR), .files = WIT_C_FILES, .flags = WIT_C_FLAGS });
    lib.addIncludePath(b.path(INC_DIR));
    lib.linkLibC();

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Documentation
    const doc_step = b.step("doc", "Emit documentation");

    const doc_install = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_subdir = "doc",
        .install_dir = .prefix,
    });

    doc_step.dependOn(&doc_install.step);
    b.default_step.dependOn(doc_step);

    // Example suite
    const examples_step = b.step("example", "Install example suite");

    const are_examples_up = b.option(bool, "up", "Run example suite") orelse false;

    if (are_examples_up) {
        var port = [4]u8{ '9', '0', '0', '0' };
        inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
            const example_run = b.addSystemCommand(&.{ "spin", "build", "--up", "--listen", "localhost:" ++ port });
            example_run.setCwd(b.path(EXAMPLES_DIR ++ EXAMPLE_NAME));
            port[3] += 1;

            examples_step.dependOn(&example_run.step);
        }
    } else {
        inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
            const example = b.addExecutable(.{
                .name = EXAMPLE_NAME,
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path(EXAMPLES_DIR ++ EXAMPLE_NAME ++ "/main.zig"),
            });
            example.root_module.addImport("spin", spin_mod);

            const example_install = b.addInstallArtifact(example, .{});
            examples_step.dependOn(&example_install.step);
        }
    }

    b.default_step.dependOn(examples_step);

    // Formatting checks
    const fmt_step = b.step("fmt", "Run formatting checks");

    const fmt = b.addFmt(.{
        .paths = &.{ "src/", "test/", "examples/", "build.zig", EXAMPLES_DIR },
        .check = true,
    });

    fmt_step.dependOn(&fmt.step);
    b.default_step.dependOn(fmt_step);
}

const WIT_DIR = "wit/";
const INC_DIR = "src/include/";
const EXAMPLES_DIR = "examples/";

const EXAMPLE_NAMES = &.{
    "http-out",
    "http-in",
    // "redis",
    "kvs",
    // "postgresql",
    // "mysql",
    "sqlite",
    "config",
};

const WIT_NAMES = &.{
    "wasi-outbound-http",
    "spin-http",
    // "outbound-redis",
    // "spin-redis",
    "key-value",
    // "outbound-pg",
    // "outbound-mysql",
    "sqlite",
    "spin-config",
};

const WIT_IS_IMPORTS = &[WIT_NAMES.len]bool{
    true,
    false,
    // false,
    // true,
    true,
    // true,
    // true,
    true,
    true,
};

const WIT_C_FILES = &[WIT_NAMES.len][]const u8{
    WIT_NAMES[0] ++ ".c",
    WIT_NAMES[1] ++ ".c",
    WIT_NAMES[2] ++ ".c",
    WIT_NAMES[3] ++ ".c",
    WIT_NAMES[4] ++ ".c",
    // WIT_NAMES[5] ++ ".c",
    // WIT_NAMES[6] ++ ".c",
    // WIT_NAMES[7] ++ ".c",
    // WIT_NAMES[8] ++ ".c",
};

const WIT_C_FLAGS = &.{
    "-Wno-unused-parameter",
    "-Wno-switch-bool",
};
