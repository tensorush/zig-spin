const std = @import("std");
const spin = @import("spin");

fn handler(_: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers{};
    headers.append(std.heap.c_allocator, .{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");

    var body = spin.http.Body{};
    var body_buf_writer = std.io.bufferedWriter(body.writer(std.heap.c_allocator));
    const body_writer = body_buf_writer.writer();

    if (spin.config.get("message")) |val| {
        defer std.heap.c_allocator.free(val);

        body_writer.print("Message: {s}\n", .{val}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");

        return .{ .headers = headers, .body = body };
    } else |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    }
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
