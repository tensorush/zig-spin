//! Config component file containing manual conversions between Zig and Spin HTTP objects
//! through the auto-generated C bindings for the inbound and outbound HTTP APIs.

const std = @import("std");

const C = @cImport({
    @cInclude("spin-config.h");
});

const ERROR_TAGS = std.meta.tags(Error);

/// Config component's error set.
/// Value order is maintained for integer casting.
pub const Error = error{
    Provider,
    InvalidKey,
    InvalidSchema,
    Other,
};

/// Retrieves the config value corresponding to the given key for the current component.
/// The config key must match one defined in the component manifest.
pub fn get(key: []const u8) Error![]const u8 {
    var c_key = C.spin_config_string_t{ .ptr = @constCast(@ptrCast(key.ptr)), .len = key.len };
    var c_value: C.spin_config_expected_string_error_t = undefined;

    C.spin_config_get_config(&c_key, &c_value);

    defer C.spin_config_expected_string_error_free(&c_value);
    defer C.spin_config_string_free(&c_key);

    if (c_value.is_err) {
        return ERROR_TAGS[c_value.val.err.tag];
    }

    var c_ok_slice: []u8 = undefined;
    c_ok_slice.ptr = c_value.val.ok.ptr;
    c_ok_slice.len = c_value.val.ok.len;

    const value = std.heap.wasm_allocator.alloc(u8, c_value.val.ok.len) catch unreachable;
    @memcpy(value, c_ok_slice);

    return value;
}
