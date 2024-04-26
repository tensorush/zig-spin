//! Config component file containing manual conversions between Zig and Spin HTTP objects
//! through the auto-generated C bindings for the inbound and outbound HTTP APIs.

const std = @import("std");

const C = @cImport({
    @cInclude("spin-config.h");
});

/// Config component's error set.
/// Error value order is preserved for integer casting.
pub const Error = error{
    Provider,
    InvalidKey,
    InvalidSchema,
    Other,
};

/// Retrieves the user-owned config value corresponding to the given key for the current component.
/// The config key must match one defined in the component manifest.
pub fn get(key: []const u8) Error![]const u8 {
    var c_key = C.spin_config_string_t{ .ptr = @constCast(@ptrCast(key.ptr)), .len = key.len };
    var c_str: C.spin_config_expected_string_error_t = undefined;

    C.spin_config_get_config(&c_key, &c_str);
    defer C.spin_config_expected_string_error_free(&c_str);

    if (c_str.is_err) {
        return std.meta.tags(Error)[c_str.val.err.tag];
    }

    var c_str_ok: []const u8 = undefined;
    c_str_ok.ptr = c_str.val.ok.ptr;
    c_str_ok.len = c_str.val.ok.len;

    return std.heap.c_allocator.dupe(u8, c_str_ok) catch @panic("OOM");
}
