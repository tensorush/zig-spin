const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi });
    const root_source_file = std.Build.LazyPath.relative(SRC_DIR ++ "spin.zig");
    const optimize = .ReleaseSmall;

    // Module
    const spin_mod = b.addModule("spin", .{ .root_source_file = root_source_file });

    // WIT C bindings
    const wit_step = b.step("wit", "Generate WIT C bindings for guest modules");

    inline for (WIT_NAMES, WIT_IS_IMPORTS) |WIT_NAME, WIT_IS_IMPORT| {
        const wit_run = b.addSystemCommand(&.{
            "wit-bindgen",                     "c",
            if (WIT_IS_IMPORT) "-i" else "-e", WIT_DIR ++ WIT_NAME ++ ".wit",
            "--out-dir",                       INC_DIR,
        });

        wit_step.dependOn(&wit_run.step);
    }

    const wit_headers_install = b.addWriteFiles();

    inline for (WIT_C_HEADERS) |WIT_C_HEADER| {
        _ = wit_headers_install.addCopyFileToSource(.{ .path = WIT_C_HEADER }, WIT_C_HEADER);
    }

    wit_step.dependOn(&wit_headers_install.step);

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "spin",
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 0, .minor = 6, .patch = 1 },
    });
    lib.addCSourceFiles(.{ .files = WIT_C_FILES, .flags = WIT_C_FLAGS });
    lib.addIncludePath(.{ .path = INC_DIR });
    lib.step.dependOn(wit_step);
    lib.linkLibC();

    for (WIT_C_HEADERS) |WIT_C_HEADER| {
        lib.installHeader(WIT_C_HEADER, std.fs.path.basename(WIT_C_HEADER));
    }

    b.installArtifact(lib);
    lib_step.dependOn(&lib.step);
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

    const spin_up = b.option(bool, "up", "Run examples") orelse false;

    if (spin_up) {
        var port = [_]u8{ '9', '0', '0', '0' };
        inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
            const example_run = b.addSystemCommand(&.{ "spin", "build", "--up", "--listen", "localhost:" ++ port });
            example_run.setCwd(.{ .path = EXAMPLES_DIR ++ EXAMPLE_NAME });
            port[3] += 1;

            examples_step.dependOn(&example_run.step);
        }
    } else {
        inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
            const example = b.addExecutable(.{
                .name = EXAMPLE_NAME,
                .root_source_file = std.Build.LazyPath.relative(EXAMPLES_DIR ++ EXAMPLE_NAME ++ "/main.zig"),
                .target = target,
                .optimize = optimize,
            });
            example.addCSourceFiles(.{ .files = WIT_C_FILES, .flags = WIT_C_FLAGS });
            example.addIncludePath(.{ .path = INC_DIR });
            example.root_module.addImport("spin", spin_mod);
            example.step.dependOn(wit_step);
            example.linkLibC();

            const example_install = b.addInstallArtifact(example, .{});
            examples_step.dependOn(&example_install.step);
        }
    }

    b.default_step.dependOn(examples_step);

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

const INC_DIR = "include/";

const EXAMPLES_DIR = "examples/";

const EXAMPLE_NAMES = &.{
    "http-out",
    "http-in",
    // "redis",
    // "kvs",
    // "postgresql",
    // "mysql",
    "sqlite",
    "config",
    // "llm",
};

const WIT_NAMES = &.{
    "wasi-outbound-http",
    "spin-http",
    // "outbound-redis",
    // "spin-redis",
    // "key-value",
    // "outbound-pg",
    // "outbound-mysql",
    "sqlite",
    "spin-config",
    // "llm",
};

const WIT_IS_IMPORTS = &[WIT_NAMES.len]bool{
    true,
    false,
    // false,
    // true,
    // true,
    // true,
    // true,
    true,
    true,
    // true,
};

const WIT_C_FILES = &[WIT_NAMES.len][]const u8{
    INC_DIR ++ WIT_NAMES[0] ++ ".c",
    INC_DIR ++ WIT_NAMES[1] ++ ".c",
    INC_DIR ++ WIT_NAMES[2] ++ ".c",
    INC_DIR ++ WIT_NAMES[3] ++ ".c",
    // INC_DIR ++ WIT_NAMES[4] ++ ".c",
    // INC_DIR ++ WIT_NAMES[5] ++ ".c",
    // INC_DIR ++ WIT_NAMES[6] ++ ".c",
    // INC_DIR ++ WIT_NAMES[7] ++ ".c",
    // INC_DIR ++ WIT_NAMES[8] ++ ".c",
    // INC_DIR ++ WIT_NAMES[9] ++ ".c",
};

const WIT_C_HEADERS = &[WIT_NAMES.len][]const u8{
    INC_DIR ++ WIT_NAMES[0] ++ ".h",
    INC_DIR ++ WIT_NAMES[1] ++ ".h",
    INC_DIR ++ WIT_NAMES[2] ++ ".h",
    INC_DIR ++ WIT_NAMES[3] ++ ".h",
    // INC_DIR ++ WIT_NAMES[4] ++ ".h",
    // INC_DIR ++ WIT_NAMES[5] ++ ".h",
    // INC_DIR ++ WIT_NAMES[6] ++ ".h",
    // INC_DIR ++ WIT_NAMES[7] ++ ".h",
    // INC_DIR ++ WIT_NAMES[8] ++ ".h",
    // INC_DIR ++ WIT_NAMES[9] ++ ".h",
};

const WIT_C_FLAGS = &.{
    "-Wno-unused-parameter",
    "-Wno-switch-bool",
};
