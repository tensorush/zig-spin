const std = @import("std");
const spin = @import("spin");

const Pet = struct {
    prey: ?[]const u8,
    name: []const u8,
    is_finicky: bool,
    id: i64,
};

fn handler(_: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers{};
    headers.append(std.heap.c_allocator, .{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");

    var body = spin.http.Body{};
    var body_buf_writer = std.io.bufferedWriter(body.writer(std.heap.c_allocator));
    const body_writer = body_buf_writer.writer();

    var db = spin.postgresql.Database{ .address = "host=localhost user=postgres dbname=spin_dev" };

    _ = db.query("INSERT INTO pets VALUES (4, 'Maya', ?, false);", &.{.{ .string = "Bananas" }}) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    const data = db.query("SELECT * FROM pets", &.{}) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    for (data.rows) |row| {
        body_writer.print("id = {d}, name = {s}, prey = {any}, is_finicky = {}\n", .{ row[0].int32, row[1].string, row[2].string, row[3].boolean }) catch @panic("OOM");
    }

    body_buf_writer.flush() catch @panic("OOM");

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
