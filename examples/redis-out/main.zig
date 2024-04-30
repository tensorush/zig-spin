const std = @import("std");
const spin = @import("spin");

fn handler(_: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers.init(std.heap.c_allocator);
    headers.append(.{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");

    var body = spin.http.Body.init(std.heap.c_allocator);
    var body_buf_writer = std.io.bufferedWriter(body.writer());
    const body_writer = body_buf_writer.writer();

    var db = spin.redis.Database{ .address = "redis://127.0.0.1:6379" };

    db.publish("messages", "Hello Redis from Zig!") orelse {
        body_writer.print("Error\n", .{}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    body_buf_writer.flush() catch @panic("OOM");

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
