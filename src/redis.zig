//! Redis component file containing manually maintained Zig bindings to the
//! auto-generated C bindings for Spin's Redis API.

const std = @import("std");

const C = @cImport({
    @cInclude("spin-redis.h");
    @cInclude("outbound-redis.h");
});

/// User's handler function for the inbound Redis trigger.
pub var HANDLER: *const fn ([]const u8) bool = undefined;

/// Redis component's data value types.
/// Union tag order is preserved for integer casting.
pub const Value = union(enum) {
    null: void,
    status: []const u8,
    int64: i64,
    binary: []const u8,
};

/// Database instance with an address.
pub const Database = struct {
    address: []const u8,

    /// Execute command.
    pub fn execute(self: Database, command: []const u8, args: []const Value) ?[]Value {
        var c_result = C.outbound_redis_list_redis_result_t{};
        var c_address = toRedisString(self.address);
        var c_command = toRedisString(command);
        var c_args = toRedisArgs(args);

        const err = C.outbound_redis_execute(&c_address, &c_command, &c_args, &c_result);
        if (err > 0) {
            return null;
        }

        return fromRedisValues(&c_result);
    }

    /// Publish message to channel.
    pub fn publish(self: Database, channel: []const u8, payload: []const u8) ?void {
        var c_payload = C.outbound_redis_payload_t{ .ptr = @constCast(payload.ptr), .len = payload.len };
        var c_address = toRedisString(self.address);
        var c_channel = toRedisString(channel);

        const err = C.outbound_redis_publish(&c_address, &c_channel, &c_payload);
        if (err > 0) {
            return null;
        }
    }

    /// Retrieve value by key.
    pub fn get(self: Database, key: []const u8) ?[]const u8 {
        var c_payload = C.outbound_redis_payload_t{};
        var c_address = toRedisString(self.address);
        var c_key = toRedisString(key);

        const err = C.outbound_redis_get(&c_address, &c_key, &c_payload);
        if (err > 0) {
            return null;
        }

        var payload: []const u8 = &.{};
        payload.ptr = c_payload.ptr;
        payload.len = c_payload.len;
        return payload;
    }

    /// Set key to value, overwriting value if key already exists.
    pub fn set(self: Database, key: []const u8, payload: []const u8) ?void {
        var c_payload = C.outbound_redis_payload_t{ .ptr = payload.ptr, .len = payload.len };
        var c_address = toRedisString(self.address);
        var c_key = toRedisString(key);

        const err = C.outbound_redis_set(&c_address, &c_key, &c_payload);
        if (err > 0) {
            return null;
        }
    }

    /// Increment value by key.
    pub fn incr(self: Database, key: []const u8) ?i64 {
        var c_address = toRedisString(self.address);
        var c_key = toRedisString(key);
        var payload: i64 = undefined;

        const err = C.outbound_redis_incr(&c_address, &c_key, &payload);
        if (err > 0) {
            return null;
        }

        return payload;
    }

    /// Remove values by keys.
    pub fn del(self: Database, keys: []const []const u8) ?i64 {
        var c_address = toRedisString(self.address);
        var c_keys = toRedisStrings(keys);
        var payload: i64 = undefined;

        const err = C.outbound_redis_del(&c_address, &c_keys, &payload);
        if (err > 0) {
            return null;
        }

        return payload;
    }

    /// Add values to key set.
    pub fn sadd(self: Database, key: []const u8, values: []const []const u8) ?i64 {
        var c_address = toRedisString(self.address);
        var c_values = toRedisStrings(values);
        var c_key = toRedisString(key);
        var payload: i64 = undefined;

        const err = C.outbound_redis_sadd(&c_address, &c_key, &c_values, &payload);
        if (err > 0) {
            return null;
        }

        return payload;
    }

    /// Retrieve values of key set.
    pub fn smembers(self: Database, key: []const u8) ?[]const []const u8 {
        var c_payload = C.outbound_redis_list_string_t{};
        var c_address = toRedisString(self.address);
        var c_key = toRedisString(key);

        const err = C.outbound_redis_smembers(&c_address, &c_key, &c_payload);
        if (err > 0) {
            return null;
        }

        return fromRedisStrings(&c_payload);
    }

    /// Remove values from key set.
    pub fn srem(self: Database, key: []const u8, values: []const []const u8) ?i64 {
        var c_address = toRedisString(self.address);
        var c_values = toRedisStrings(values);
        var c_key = toRedisString(key);
        var payload: i64 = undefined;

        const err = C.outbound_redis_srem(&c_address, &c_key, &c_values, &payload);
        if (err > 0) {
            return null;
        }

        return payload;
    }
};

/// Exported to be called from auto-generated C bindings for Spin's inbound Redis API.
pub export fn spin_redis_handle_redis_message(c_payload: *C.spin_redis_payload_t) C.spin_redis_error_t {
    var payload: []const u8 = &.{};
    payload.ptr = c_payload.ptr;
    payload.len = c_payload.len;
    return @intFromBool(HANDLER(payload));
}

fn toRedisString(string: []const u8) C.outbound_redis_string_t {
    return .{ .ptr = @constCast(string.ptr), .len = string.len };
}

fn toRedisStrings(strings: []const []const u8) C.outbound_redis_list_string_t {
    if (strings.len == 0) {
        return .{};
    }

    var c_strings = std.heap.c_allocator.alloc(C.outbound_redis_string_t, strings.len) catch @panic("OOM");
    for (strings, 0..) |string, i| {
        c_strings[i] = toRedisString(string);
    }

    return .{ .ptr = c_strings.ptr, .len = c_strings.len };
}

fn fromRedisStrings(c_strings: *C.outbound_redis_list_string_t) []const []const u8 {
    var strings = std.heap.c_allocator.alloc([]const u8, c_strings.len) catch @panic("OOM");
    var c_strings_slice: []const C.sqlite_string_t = &.{};
    c_strings_slice.ptr = c_strings.ptr;
    c_strings_slice.len = c_strings.len;

    for (c_strings_slice, 0..) |c_string, i| {
        strings[i].ptr = c_string.ptr;
        strings[i].len = c_string.len;
    }

    return strings;
}

fn toRedisArg(arg: Value) C.outbound_redis_redis_parameter_t {
    var c_arg = C.outbound_redis_redis_parameter_t{};
    c_arg.tag = @intFromEnum(arg) - 2;

    switch (arg) {
        .int64 => |int64| c_arg.val.int64 = int64,
        .binary => |binary| c_arg.val.binary = .{ .ptr = @constCast(binary.ptr), .len = binary.len },
        else => @panic("Unsupported argument type"),
    }

    return c_arg;
}

fn toRedisArgs(args: []const Value) C.outbound_redis_list_redis_parameter_t {
    if (args.len == 0) {
        return .{};
    }

    var c_args = std.heap.c_allocator.alloc(C.outbound_redis_redis_parameter_t, args.len) catch @panic("OOM");
    for (args, 0..) |arg, i| {
        c_args[i] = toRedisArg(arg);
    }

    return .{ .ptr = c_args.ptr, .len = c_args.len };
}

fn fromRedisValue(c_value: C.outbound_redis_redis_result_t) Value {
    return switch (@as(std.meta.Tag(Value), @enumFromInt(c_value.tag))) {
        .null => .null,
        .status => blk: {
            var status: []const u8 = &.{};
            status.ptr = c_value.val.status.ptr;
            status.len = c_value.val.status.len;
            break :blk .{ .status = status };
        },
        .int64 => .{ .int64 = c_value.val.int64 },
        .binary => blk: {
            var binary: []const u8 = &.{};
            binary.ptr = c_value.val.binary.ptr;
            binary.len = c_value.val.binary.len;
            break :blk .{ .binary = binary };
        },
    };
}

fn fromRedisValues(c_values: C.outbound_redis_list_redis_result_t) []const Value {
    var values = std.heap.c_allocator.alloc(Value, c_values.len) catch @panic("OOM");
    var c_values_slice: []const C.sqlite_value_t = &.{};
    c_values_slice.ptr = c_values.ptr;
    c_values_slice.len = c_values.len;

    for (c_values_slice, 0..) |c_value, i| {
        values[i] = fromRedisValue(c_value);
    }

    return values;
}
