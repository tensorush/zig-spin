//! Key-value store component file containing manually maintained Zig bindings to the
//! auto-generated C bindings for Spin's key-value store API.

const std = @import("std");

const C = @cImport({
    @cInclude("key-value.h");
});

/// Key-value store component's error set.
/// Error value order is preserved for integer casting.
pub const Error = error{
    StoreTableFull,
    NoSuchStore,
    AccessDenied,
    InvalidStore,
    NoSuchKey,
    Io,
};

/// Store instance with a handle.
pub const Store = struct {
    handle: u32,

    /// Open store connection.
    pub fn open(name: []const u8) Error!Store {
        var c_conn: C.key_value_expected_store_error_t = undefined;

        var c_name = toStoreString(name);
        C.key_value_open(&c_name, &c_conn);

        if (c_conn.is_err) {
            return std.meta.tags(Error)[c_conn.val.err.tag];
        }

        return .{ .handle = c_conn.val.ok };
    }

    /// Close store connection.
    pub fn close(self: Store) void {
        C.key_value_close(self.handle);
    }

    /// Retrieve user-owned value from store.
    pub fn get(self: Store, key: []const u8) Error![]const u8 {
        var c_value: C.key_value_expected_list_u8_error_t = undefined;
        var c_key = toStoreString(key);

        C.key_value_get(self.handle, &c_key, &c_value);

        if (c_value.is_err) {
            return std.meta.tags(Error)[c_value.val.err.tag];
        }

        var value: []const u8 = undefined;
        value.ptr = c_value.val.ok.ptr;
        value.len = c_value.val.ok.len;
        return value;
    }

    /// Set key with value in store.
    pub fn set(self: Store, key: []const u8, value: []const u8) Error!void {
        var c_value = C.key_value_list_u8_t{ .ptr = @constCast(value.ptr), .len = value.len };
        var c_err: C.key_value_expected_unit_error_t = undefined;
        var c_key = toStoreString(key);

        C.key_value_set(self.handle, &c_key, &c_value, &c_err);

        if (c_err.is_err) {
            return std.meta.tags(Error)[c_err.val.err.tag];
        }
    }

    /// Remove value from store.
    pub fn exists(self: Store, key: []const u8) Error!bool {
        var c_exists: C.key_value_expected_bool_error_t = undefined;
        var c_key = toStoreString(key);

        C.key_value_exists(self.handle, &c_key, &c_exists);

        if (c_exists.is_err) {
            return std.meta.tags(Error)[c_exists.val.err.tag];
        }

        return c_exists.val.ok;
    }

    /// Retrieve user-owned slice of all keys from store.
    pub fn getKeys(self: Store) Error![]const []const u8 {
        var c_keys: C.key_value_expected_list_string_error_t = undefined;

        C.key_value_get_keys(self.handle, &c_keys);

        if (c_keys.is_err) {
            return std.meta.tags(Error)[c_keys.val.err.tag];
        }

        return fromStoreStringList(c_keys.val.ok);
    }

    /// Remove value from store.
    pub fn delete(self: Store, key: []const u8) Error!void {
        var c_err: C.key_value_expected_unit_error_t = undefined;
        var c_key = toStoreString(key);

        C.key_value_delete(self.handle, &c_key, &c_err);

        if (c_err.is_err) {
            return std.meta.tags(Error)[c_err.val.err.tag];
        }
    }
};

fn toStoreString(string: []const u8) C.key_value_string_t {
    return .{ .ptr = @constCast(@ptrCast(string.ptr)), .len = string.len };
}

fn fromStoreStringList(c_string_list: C.key_value_list_string_t) []const []const u8 {
    var string_list = std.heap.c_allocator.alloc([]const u8, c_string_list.len) catch @panic("OOM");
    var c_string_list_slice: []const C.key_value_string_t = undefined;
    c_string_list_slice.ptr = c_string_list.ptr;
    c_string_list_slice.len = c_string_list.len;

    for (c_string_list_slice, 0..) |c_string, i| {
        string_list[i].ptr = c_string.ptr;
        string_list[i].len = c_string.len;
    }

    return string_list;
}
