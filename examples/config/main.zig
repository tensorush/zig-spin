const std = @import("std");
const spin = @import("spin");

const BODY_LEN: u16 = 1 << 12;

fn handler(_: spin.http.Request) spin.http.Response {
    var headers = std.http.Headers.init(std.heap.wasm_allocator);
    headers.append("Content-Type", "text/plain") catch unreachable;

    var body = std.ArrayListUnmanaged(u8).initCapacity(std.heap.wasm_allocator, BODY_LEN) catch unreachable;
    var buf_writer = std.io.bufferedWriter(body.writer(std.heap.wasm_allocator));
    const writer = buf_writer.writer();

    if (spin.config.get("message")) |val| {
        writer.print("Message: {s}\n", .{val}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body };
    } else |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    }
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
