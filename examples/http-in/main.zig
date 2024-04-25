const std = @import("std");
const spin = @import("spin");

fn handler(req: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers{};
    headers.append(std.heap.c_allocator, .{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");
    headers.append(std.heap.c_allocator, .{ .name = "foo", .value = "bar" }) catch @panic("OOM");

    var body = spin.http.Body{};
    var body_buf_writer = std.io.bufferedWriter(body.writer(std.heap.c_allocator));
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
