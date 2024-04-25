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
    columns: [][]const u8,
    rows: [][]Value,
};

/// Database instance with a handle.
pub const Database = struct {
    handle: u32,

    /// Open database connection.
    pub fn open(name: []const u8) Error!Database {
        var c_conn: C.sqlite_expected_connection_error_t = undefined;

        var c_name = sqliteStr(name);
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

        var c_statement = sqliteStr(statement);
        var c_args = try toSqliteListValue(args);

        C.sqlite_execute(self.handle, &c_statement, &c_args, &c_query_result);

        if (c_query_result.is_err) {
            return std.meta.tags(Error)[c_query_result.val.err.tag];
        }

        return .{
            .columns = try fromSqliteListString(c_query_result.val.ok.columns),
            .rows = fromSqliteListRowResult(c_query_result.val.ok.rows),
        };
    }
};

fn sqliteStr(str: []const u8) C.sqlite_string_t {
    return .{ .ptr = @constCast(@ptrCast(str.ptr)), .len = str.len };
}

fn toSqliteListValue(values: []const Value) Error!C.sqlite_list_value_t {
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
        .int => {
            c_value.val.integer = value.int;
        },
        .real => {
            c_value.val.real = value.real;
        },
        .text => {
            c_value.val.text = sqliteStr(value.text);
        },
        .blob => {
            c_value.val.blob = .{ .ptr = @constCast(value.blob.ptr), .len = value.blob.len };
        },
        .nil => {},
    }

    return c_value;
}

fn fromSqliteListString(c_list_string: C.sqlite_list_string_t) Error![][]const u8 {
    var c_list_string_slice: []C.sqlite_string_t = undefined;
    c_list_string_slice.ptr = c_list_string.ptr;
    c_list_string_slice.len = c_list_string.len;
    var list_string: [][]const u8 = undefined;
    var string: []u8 = undefined;

    for (c_list_string_slice, 0..) |c_string, i| {
        string.ptr = c_string.ptr;
        string.len = c_string.len;
        list_string[i] = std.heap.c_allocator.dupe(u8, string) catch @panic("OOM");
    }

    return list_string;
}

fn fromSqliteListRowResult(c_list_row_result: C.sqlite_list_row_result_t) [][]Value {
    var c_list_row_result_slice: []C.sqlite_row_result_t = undefined;
    c_list_row_result_slice.ptr = c_list_row_result.ptr;
    c_list_row_result_slice.len = c_list_row_result.len;
    var list_row_result: [][]Value = undefined;

    for (c_list_row_result_slice, 0..) |item, i| {
        list_row_result[i] = fromSqliteListValue(item.values);
    }

    return list_row_result;
}

fn fromSqliteListValue(c_list_value: C.sqlite_list_value_t) []Value {
    var c_list_value_slice: []C.sqlite_value_t = undefined;
    c_list_value_slice.ptr = c_list_value.ptr;
    c_list_value_slice.len = c_list_value.len;
    var list_value: []Value = undefined;

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
            var text: []u8 = undefined;
            text.ptr = @ptrCast(c_value.val.text.ptr);
            text.len = c_value.val.text.len;
            break :blk .{ .text = text };
        },
        .blob => blk: {
            var blob: []u8 = undefined;
            blob.ptr = c_value.val.blob.ptr;
            blob.len = c_value.val.blob.len;
            break :blk .{ .blob = blob };
        },
        .nil => .nil,
    };
}
