const std = @import("std");
const spin = @import("spin");

const BODY_LEN: u16 = 1 << 12;

fn handler(req: spin.http.Request) spin.http.Response {
    var headers = std.http.Headers.init(std.heap.wasm_allocator);
    headers.append("Content-Type", "text/plain") catch unreachable;

    var body = std.ArrayListUnmanaged(u8).initCapacity(std.heap.wasm_allocator, BODY_LEN) catch unreachable;
    var buf_writer = std.io.bufferedWriter(body.writer(std.heap.wasm_allocator));
    const writer = buf_writer.writer();

    const req1 = spin.http.Request{ .method = .GET, .url = "https://random-data-api.fermyon.app/animals/json" };
    const res1 = spin.http.send(req1) catch |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    writer.print("Request 1:\n  URL: {s}\n  Content-Type: {s}\n  Body: {s}\n\n", .{ req1.url, res1.headers.getFirstValue("content-type").?, res1.body.items }) catch unreachable;

    const req2 = spin.http.Request{ .method = .POST, .url = "https://postman-echo.com/post", .headers = headers, .body = req.body };
    const res2 = spin.http.send(req2) catch |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    writer.print("Request 2:\n  URL: {s}\n  Content-Type: {s}\n  Body: {s}\n\n", .{ req2.url, res2.headers.getFirstValue("content-type").?, res2.body.items }) catch unreachable;

    headers.append("foo", "bar") catch unreachable;
    var req3_body = std.ArrayListUnmanaged(u8).initCapacity(std.heap.wasm_allocator, BODY_LEN) catch unreachable;
    req3_body.appendSliceAssumeCapacity("All your codebase are belong to us!\n");

    const req3 = spin.http.Request{ .method = .PUT, .url = "https://postman-echo.com/put", .headers = headers, .body = req3_body };
    const res3 = spin.http.send(req3) catch |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    writer.print("Request 3:\n  URL: {s}\n  Content-Type: {s}\n  Body: {s}\n\n", .{ req3.url, res3.headers.getFirstValue("content-type").?, res3.body.items }) catch unreachable;

    const req4 = spin.http.Request{ .method = .GET, .url = "https://fermyon.com" };
    _ = spin.http.send(req4) catch |err| {
        writer.print("Request 4:\n  URL: {s}\n  Cannot send HTTP request: {s}\n", .{ req4.url, @errorName(err) }) catch unreachable;
    };

    buf_writer.flush() catch unreachable;

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
