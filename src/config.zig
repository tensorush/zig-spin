const std = @import("std");

const C = @cImport({
    @cInclude("spin-config.h");
});

pub const Error = union(enum) {
    invalid_schema: []u8,
    invalid_key: []u8,
    provider: []u8,
    other: []u8,
};

pub const Result = union(enum) {
    err: Error,
    ok: []u8,
};

pub fn get(key_ptr: [*c]u8, key_len: usize) C.spin_config_expected_string_error_t {
    var res: C.spin_config_expected_string_error_t = undefined;

    var spin_key = C.spin_config_string_t{ .ptr = key_ptr, .len = key_len };
    defer C.spin_config_expected_string_error_free(&res);
    defer C.spin_config_string_free(&spin_key);

    C.spin_config_get_config(&spin_key, &res);

    return res;
}
