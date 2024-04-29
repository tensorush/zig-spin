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
    null: void,
};

/// Data as rows and columns.
pub const Data = struct {
    rows: []const []const Value,
    cols: []const []const u8,
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

    /// Execute query and return data with user-owned data rows and columns.
    pub fn execute(self: Database, statement: []const u8, args: []const Value) Error!Data {
        var c_query_result: C.sqlite_expected_query_result_error_t = undefined;
        defer C.sqlite_expected_query_result_error_free(&c_query_result);

        var c_statement = toSqliteString(statement);
        var c_args = toSqliteArgs(args);

        C.sqlite_execute(self.handle, &c_statement, &c_args, &c_query_result);

        if (c_query_result.is_err) {
            return std.meta.tags(Error)[c_query_result.val.err.tag];
        }

        return .{
            .rows = fromSqliteRows(c_query_result.val.ok.rows),
            .cols = fromSqliteCols(c_query_result.val.ok.columns),
        };
    }
};

fn toSqliteString(string: []const u8) C.sqlite_string_t {
    return .{ .ptr = @constCast(@ptrCast(string.ptr)), .len = string.len };
}

fn toSqliteArgs(args: []const Value) C.sqlite_list_value_t {
    if (args.len == 0) {
        return .{};
    }

    var c_args = std.heap.c_allocator.alloc(C.sqlite_value_t, args.len) catch @panic("OOM");
    for (args, 0..) |arg, i| {
        c_args[i] = toSqliteArg(arg);
    }

    return .{ .ptr = c_args.ptr, .len = c_args.len };
}

fn toSqliteArg(arg: Value) C.sqlite_value_t {
    var c_arg: C.sqlite_value_t = undefined;
    c_arg.tag = @intFromEnum(arg);

    switch (arg) {
        .int => |int| c_arg.val.integer = int,
        .real => |real| c_arg.val.real = real,
        .text => |text| c_arg.val.text = toSqliteString(text),
        .blob => |blob| c_arg.val.blob = .{ .ptr = @constCast(blob.ptr), .len = blob.len },
        .null => {},
    }

    return c_arg;
}

fn fromSqliteCols(c_cols: C.sqlite_list_string_t) []const []const u8 {
    var cols = std.heap.c_allocator.alloc([]const u8, c_cols.len) catch @panic("OOM");
    var c_cols_slice: []const C.sqlite_string_t = undefined;
    c_cols_slice.ptr = c_cols.ptr;
    c_cols_slice.len = c_cols.len;

    var col: []const u8 = undefined;
    for (c_cols_slice, 0..) |c_col, i| {
        col.ptr = c_col.ptr;
        col.len = c_col.len;
        cols[i] = std.heap.c_allocator.dupe(u8, col) catch @panic("OOM");
    }

    return cols;
}

fn fromSqliteRows(c_rows: C.sqlite_list_row_result_t) []const []const Value {
    var rows = std.heap.c_allocator.alloc([]const Value, c_rows.len) catch @panic("OOM");
    var c_rows_slice: []const C.sqlite_row_result_t = undefined;
    c_rows_slice.ptr = c_rows.ptr;
    c_rows_slice.len = c_rows.len;

    for (c_rows_slice, 0..) |c_row, i| {
        rows[i] = fromSqliteRow(c_row.values);
    }

    return rows;
}

fn fromSqliteRow(c_row: C.sqlite_list_value_t) []const Value {
    var row = std.heap.c_allocator.alloc(Value, c_row.len) catch @panic("OOM");
    var c_row_slice: []const C.sqlite_value_t = undefined;
    c_row_slice.ptr = c_row.ptr;
    c_row_slice.len = c_row.len;

    for (c_row_slice, 0..) |c_value, i| {
        row[i] = fromSqliteValue(c_value);
    }

    return row;
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
        .null => .null,
    };
}
