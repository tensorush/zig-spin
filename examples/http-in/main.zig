const std = @import("std");
const spin = @import("spin");

const BODY_CAP: u8 = 1 << 7;

fn handler(req: spin.http.Request) spin.http.Response {
    var headers = std.http.Headers.init(std.heap.wasm_allocator);
    headers.append("Content-Type", "text/plain") catch unreachable;
    headers.append("foo", "bar") catch unreachable;

    var body = std.ArrayListUnmanaged(u8).initCapacity(std.heap.wasm_allocator, BODY_CAP) catch unreachable;
    var buf_writer = std.io.bufferedWriter(body.writer(std.heap.wasm_allocator));
    const writer = buf_writer.writer();

    writer.print("== REQUEST ==\nURL: {s}\nMethod:  {}\nHeaders:\n", .{ req.url, req.method }) catch unreachable;

    for (req.headers.list.items) |header| {
        writer.print("  {s}: {s}\n", .{ header.name, header.value }) catch unreachable;
    }

    writer.writeAll("== RESPONSE ==\nHello Fermyon!\n") catch unreachable;

    buf_writer.flush() catch unreachable;

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
