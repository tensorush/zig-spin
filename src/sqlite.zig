//! SQLite component file containing manually maintained Zig bindings to the
//! auto-generated C bindings for Spin's SQLite API.

const std = @import("std");

const C = @cImport({
    @cInclude("sqlite.h");
});

/// SQLite component's error set.
/// Error value order is preserved for integer casting.
pub const Error = error{
    NoSuchDatabase,
    AccessDenied,
    InvalidConnection,
    DatabaseFull,
    Io,
};

/// SQLite component's data value types.
/// Union tag order is preserved for integer casting.
pub const Value = union(enum) {
    int: i64,
    real: f64,
    text: []const u8,
    blob: []const u8,
    nil: void,
};

/// Data as rows and columns.
pub const Data = struct {
    cols: []const []const u8,
    rows: []const []const Value,
};

/// Database instance with a handle.
pub const Database = struct {
    handle: u32,

    /// Open database connection.
    pub fn open(name: []const u8) Error!Database {
        var c_conn: C.sqlite_expected_connection_error_t = undefined;

        var c_name = toSqliteString(name);
        C.sqlite_open(&c_name, &c_conn);

        if (c_conn.is_err) {
            return std.meta.tags(Error)[c_conn.val.err.tag];
        }

        return .{ .handle = c_conn.val.ok };
    }

    /// Close database connection.
    pub fn close(self: Database) void {
        C.sqlite_close(self.handle);
    }

    /// Execute query and return data with user-owned columns.
    pub fn execute(self: Database, statement: []const u8, args: []const Value) Error!Data {
        var c_query_result: C.sqlite_expected_query_result_error_t = undefined;
        defer C.sqlite_expected_query_result_error_free(&c_query_result);

        var c_statement = toSqliteString(statement);
        var c_args = toSqliteListValue(args);

        C.sqlite_execute(self.handle, &c_statement, &c_args, &c_query_result);

        if (c_query_result.is_err) {
            return std.meta.tags(Error)[c_query_result.val.err.tag];
        }

        return .{
            .cols = fromSqliteListString(c_query_result.val.ok.columns),
            .rows = fromSqliteListRowResult(c_query_result.val.ok.rows),
        };
    }
};

fn toSqliteString(string: []const u8) C.sqlite_string_t {
    return .{ .ptr = @constCast(@ptrCast(string.ptr)), .len = string.len };
}

fn toSqliteListValue(values: []const Value) C.sqlite_list_value_t {
    if (values.len == 0) {
        return .{};
    }

    var c_values = std.heap.c_allocator.alloc(C.sqlite_value_t, values.len) catch @panic("OOM");

    for (values, 0..) |value, i| {
        c_values[i] = toSqliteValue(value);
    }

    return .{ .ptr = c_values.ptr, .len = c_values.len };
}

fn toSqliteValue(value: Value) C.sqlite_value_t {
    var c_value: C.sqlite_value_t = undefined;
    c_value.tag = @intFromEnum(value);

    switch (value) {
        .int => c_value.val.integer = value.int,
        .real => c_value.val.real = value.real,
        .text => c_value.val.text = toSqliteString(value.text),
        .blob => c_value.val.blob = .{ .ptr = @constCast(value.blob.ptr), .len = value.blob.len },
        .nil => {},
    }

    return c_value;
}

fn fromSqliteListString(c_string_list: C.sqlite_list_string_t) []const []const u8 {
    var string_list = std.heap.c_allocator.alloc([]const u8, c_string_list.len) catch @panic("OOM");
    var c_string_list_slice: []const C.sqlite_string_t = undefined;
    c_string_list_slice.ptr = c_string_list.ptr;
    c_string_list_slice.len = c_string_list.len;
    var string: []const u8 = undefined;

    for (c_string_list_slice, 0..) |c_string, i| {
        string.ptr = c_string.ptr;
        string.len = c_string.len;
        string_list[i] = std.heap.c_allocator.dupe(u8, string) catch @panic("OOM");
    }

    return string_list;
}

fn fromSqliteListRowResult(c_list_row_result: C.sqlite_list_row_result_t) []const []const Value {
    var list_row_result = std.heap.c_allocator.alloc([]const Value, c_list_row_result.len) catch @panic("OOM");
    var c_list_row_result_slice: []const C.sqlite_row_result_t = undefined;
    c_list_row_result_slice.ptr = c_list_row_result.ptr;
    c_list_row_result_slice.len = c_list_row_result.len;

    for (c_list_row_result_slice, 0..) |item, i| {
        list_row_result[i] = fromSqliteListValue(item.values);
    }

    return list_row_result;
}

fn fromSqliteListValue(c_list_value: C.sqlite_list_value_t) []const Value {
    var list_value = std.heap.c_allocator.alloc(Value, c_list_value.len) catch @panic("OOM");
    var c_list_value_slice: []const C.sqlite_value_t = undefined;
    c_list_value_slice.ptr = c_list_value.ptr;
    c_list_value_slice.len = c_list_value.len;

    for (c_list_value_slice, 0..) |item, i| {
        list_value[i] = fromSqliteValue(item);
    }

    return list_value;
}

fn fromSqliteValue(c_value: C.sqlite_value_t) Value {
    return switch (@as(std.meta.Tag(Value), @enumFromInt(c_value.tag))) {
        .int => .{ .int = c_value.val.integer },
        .real => .{ .real = c_value.val.real },
        .text => blk: {
            var text: []const u8 = undefined;
            text.ptr = @ptrCast(c_value.val.text.ptr);
            text.len = c_value.val.text.len;
            break :blk .{ .text = std.heap.c_allocator.dupe(u8, text) catch @panic("OOM") };
        },
        .blob => blk: {
            var blob: []const u8 = undefined;
            blob.ptr = c_value.val.blob.ptr;
            blob.len = c_value.val.blob.len;
            break :blk .{ .blob = std.heap.c_allocator.dupe(u8, blob) catch @panic("OOM") };
        },
        .nil => .nil,
    };
}
