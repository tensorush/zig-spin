const std = @import("std");
const spin = @import("spin");

const Pet = struct {
    prey: ?[]const u8,
    name: []const u8,
    is_finicky: bool,
    id: i64,
};

fn handler(_: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers.init(std.heap.c_allocator);
    headers.append(.{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");

    var body = spin.http.Body.init(std.heap.c_allocator);
    var body_buf_writer = std.io.bufferedWriter(body.writer());
    const body_writer = body_buf_writer.writer();

    var db = spin.sqlite.Database.open("default") catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };
    defer db.close();

    _ = db.execute("REPLACE INTO pets VALUES (4, 'Maya', ?, false);", &.{.{ .blob = "Bananas" }}) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    const data = db.execute("SELECT * FROM pets", &.{}) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    for (data.rows) |row| {
        body_writer.print("id = {d}, name = {s}, prey = {any}, is_finicky = {d}\n", .{ row[0].int, row[1].text, row[2].text, row[3].int }) catch @panic("OOM");
    }

    body_buf_writer.flush() catch @panic("OOM");

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
