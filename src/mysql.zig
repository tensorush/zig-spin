//! MySQL component file containing manually maintained Zig bindings to the
//! auto-generated C bindings for Spin's MySQL API.

const std = @import("std");

const C = @cImport({
    @cInclude("outbound-mysql.h");
});

/// MySQL component's error set.
/// Error value order is preserved for integer casting.
pub const Error = error{
    Success,
    ConnectionFailed,
    BadParameter,
    QueryFailed,
    ValueConversionFailed,
    Other,
};

/// MySQL component's data value types.
/// Union tag order is preserved for integer casting.
pub const Value = union(enum) {
    boolean: bool,
    int8: i8,
    int16: i16,
    int32: i32,
    int64: i64,
    uint8: u8,
    uint16: u16,
    uint32: u32,
    uint64: u64,
    float32: f32,
    float64: f64,
    string: []const u8,
    binary: []const u8,
    null: void,
};

/// Query result as rows and columns.
pub const QueryResult = struct {
    rows: []const []const Value,
    cols: []const Column,
};

/// Query result column.
pub const Column = struct {
    type: std.meta.Tag(Value),
    name: []const u8,
};

/// Database instance with an address.
pub const Database = struct {
    address: []const u8,

    /// Execute query that doesn't return data, like INSERT or UPDATE.
    pub fn execute(self: Database, statement: []const u8, args: []const Value) Error!void {
        var c_result = C.outbound_mysql_expected_unit_mysql_error_t{};
        var c_address = toMysqlString(self.address);
        var c_statement = toMysqlString(statement);
        var c_args = toMysqlArgs(args);

        C.outbound_mysql_execute(&c_address, &c_statement, &c_args, &c_result);
        if (c_result.is_err) {
            return std.meta.tags(Error)[c_result.val.err.tag];
        }
    }

    /// Execute query and return data with user-owned data rows and columns.
    pub fn query(self: Database, statement: []const u8, args: []const Value) Error!QueryResult {
        var c_query_result = C.outbound_mysql_expected_row_set_mysql_error_t{};
        var c_address = toMysqlString(self.address);
        var c_statement = toMysqlString(statement);
        var c_args = toMysqlArgs(args);

        C.outbound_mysql_query(&c_address, &c_statement, &c_args, &c_query_result);
        if (c_query_result.is_err) {
            return std.meta.tags(Error)[c_query_result.val.err.tag];
        }

        return .{
            .rows = fromMysqlRows(c_query_result.val.ok.rows),
            .cols = fromMysqlCols(c_query_result.val.ok.columns),
        };
    }
};

fn toMysqlString(string: []const u8) C.outbound_mysql_string_t {
    return .{ .ptr = @constCast(string.ptr), .len = string.len };
}

fn toMysqlArgs(args: []const Value) C.outbound_mysql_list_parameter_value_t {
    if (args.len == 0) {
        return .{};
    }

    var c_args = std.heap.c_allocator.alloc(C.outbound_mysql_parameter_value_t, args.len) catch @panic("OOM");
    for (args, 0..) |arg, i| {
        c_args[i] = toMysqlArg(arg);
    }

    return .{ .ptr = c_args.ptr, .len = c_args.len };
}

fn toMysqlArg(arg: Value) C.outbound_mysql_parameter_value_t {
    var c_arg = C.outbound_mysql_parameter_value_t{};
    c_arg.tag = @intFromEnum(arg);

    switch (arg) {
        .boolean => |boolean| c_arg.val.boolean = boolean,
        .int8 => |int8| c_arg.val.int8 = int8,
        .int16 => |int16| c_arg.val.int16 = int16,
        .int32 => |int32| c_arg.val.int32 = int32,
        .int64 => |int64| c_arg.val.int64 = int64,
        .uint8 => |uint8| c_arg.val.uint8 = uint8,
        .uint16 => |uint16| c_arg.val.uint16 = uint16,
        .uint32 => |uint32| c_arg.val.uint32 = uint32,
        .uint64 => |uint64| c_arg.val.uint64 = uint64,
        .float32 => |float32| c_arg.val.floating32 = float32,
        .float64 => |float64| c_arg.val.floating64 = float64,
        .string => |string| c_arg.val.str = toMysqlString(string),
        .binary => |binary| c_arg.val.binary = .{ .ptr = @constCast(binary.ptr), .len = binary.len },
        .null => {},
    }

    return c_arg;
}

fn fromMysqlCols(c_cols: C.outbound_mysql_list_column_t) []const Column {
    var cols = std.heap.c_allocator.alloc(Column, c_cols.len) catch @panic("OOM");
    var c_cols_slice: []const C.outbound_mysql_column_t = undefined;
    c_cols_slice.ptr = c_cols.ptr;
    c_cols_slice.len = c_cols.len;

    for (c_cols_slice, 0..) |c_col, i| {
        cols[i].name.ptr = c_col.name.ptr;
        cols[i].name.len = c_col.name.len;
        cols[i].type = @enumFromInt(c_col.data_type);
    }

    return cols;
}

fn fromMysqlRows(c_rows: C.outbound_mysql_list_row_t) []const []const Value {
    var rows = std.heap.c_allocator.alloc([]const Value, c_rows.len) catch @panic("OOM");
    var c_rows_slice: []const C.outbound_mysql_row_t = undefined;
    c_rows_slice.ptr = c_rows.ptr;
    c_rows_slice.len = c_rows.len;

    for (c_rows_slice, 0..) |c_row, i| {
        rows[i] = fromMysqlRow(c_row);
    }

    return rows;
}

fn fromMysqlRow(c_row: C.outbound_mysql_row_t) []const Value {
    var row = std.heap.c_allocator.alloc(Value, c_row.len) catch @panic("OOM");
    var c_row_slice: []const C.outbound_mysql_db_value_t = undefined;
    c_row_slice.ptr = c_row.ptr;
    c_row_slice.len = c_row.len;

    for (c_row_slice, 0..) |c_value, i| {
        row[i] = fromMysqlValue(c_value);
    }

    return row;
}

fn fromMysqlValue(c_value: C.outbound_mysql_db_value_t) Value {
    return switch (@as(std.meta.Tag(Value), @enumFromInt(c_value.tag))) {
        .boolean => .{ .boolean = c_value.val.boolean },
        .int8 => .{ .int8 = c_value.val.int8 },
        .int16 => .{ .int16 = c_value.val.int16 },
        .int32 => .{ .int32 = c_value.val.int32 },
        .int64 => .{ .int64 = c_value.val.int64 },
        .uint8 => .{ .uint8 = c_value.val.uint8 },
        .uint16 => .{ .uint16 = c_value.val.uint16 },
        .uint32 => .{ .uint32 = c_value.val.uint32 },
        .uint64 => .{ .uint64 = c_value.val.uint64 },
        .float32 => .{ .float32 = c_value.val.floating32 },
        .float64 => .{ .float64 = c_value.val.floating64 },
        .string => blk: {
            var string: []const u8 = &.{};
            string.ptr = c_value.val.str.ptr;
            string.len = c_value.val.str.len;
            break :blk .{ .string = string };
        },
        .binary => blk: {
            var binary: []const u8 = &.{};
            binary.ptr = c_value.val.binary.ptr;
            binary.len = c_value.val.binary.len;
            break :blk .{ .binary = binary };
        },
        .null => .null,
    };
}
