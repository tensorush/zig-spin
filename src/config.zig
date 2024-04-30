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
    var c_key = C.spin_config_string_t{ .ptr = @constCast(key.ptr), .len = key.len };
    var c_value = C.spin_config_expected_string_error_t{};

    C.spin_config_get_config(&c_key, &c_value);
    if (c_value.is_err) {
        return std.meta.tags(Error)[c_value.val.err.tag];
    }

    var value: []const u8 = &.{};
    value.ptr = c_value.val.ok.ptr;
    value.len = c_value.val.ok.len;
    return value;
}
