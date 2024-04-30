const std = @import("std");
const spin = @import("spin");

fn handler(req: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers.init(std.heap.c_allocator);
    headers.append(.{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");
    headers.append(.{ .name = "foo", .value = "bar" }) catch @panic("OOM");

    var body = spin.http.Body.init(std.heap.c_allocator);
    var body_buf_writer = std.io.bufferedWriter(body.writer());
    const body_writer = body_buf_writer.writer();

    body_writer.print("== REQUEST ==\nURI: {s}\nMethod: {s}\nHeaders:\n", .{ req.uri, @tagName(req.method) }) catch @panic("OOM");

    for (req.headers.items) |header| {
        body_writer.print("  {s}: {s}\n", .{ header.name, header.value }) catch @panic("OOM");
    }

    body_writer.writeAll("== RESPONSE ==\nHello Fermyon!\n") catch @panic("OOM");

    body_buf_writer.flush() catch @panic("OOM");

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
