const std = @import("std");
const spin = @import("spin");

fn handler(req: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers.init(std.heap.c_allocator);
    headers.append(.{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");

    var body = spin.http.Body.init(std.heap.c_allocator);
    var body_buf_writer = std.io.bufferedWriter(body.writer());
    const body_writer = body_buf_writer.writer();

    const req1 = spin.http.Request{ .uri = "https://random-data-api.fermyon.app/animals/json" };
    const res1 = spin.http.send(req1) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    body_writer.print("== REQUEST 1 ==\n  URI: {s}\n  Content-Type: {s}\n  Body: {s}\n", .{ req1.uri, res1.headers.items[0].value, res1.body.items }) catch @panic("OOM");

    const req2 = spin.http.Request{ .method = .POST, .uri = "https://postman-echo.com/post", .headers = headers, .body = req.body };
    const res2 = spin.http.send(req2) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    body_writer.print("== REQUEST 2 ==\n  URI: {s}\n  Content-Type: {s}\n  Body: {s}\n", .{ req2.uri, res2.headers.items[0].value, res2.body.items }) catch @panic("OOM");

    headers.append(.{ .name = "foo", .value = "bar" }) catch @panic("OOM");

    var req3_body = spin.http.Body.init(std.heap.c_allocator);
    req3_body.appendSlice("All your codebase are belong to us!\n") catch @panic("OOM");

    const req3 = spin.http.Request{ .method = .PUT, .uri = "https://postman-echo.com/put", .headers = headers, .body = req3_body };
    const res3 = spin.http.send(req3) catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    body_writer.print("== REQUEST 3 ==\n  URI: {s}\n  Content-Type: {s}\n  Body: {s}\n", .{ req3.uri, res3.headers.items[0].value, res3.body.items }) catch @panic("OOM");

    const req4 = spin.http.Request{ .uri = "https://fermyon.com" };
    _ = spin.http.send(req4) catch |err| {
        body_writer.print("== REQUEST 4 ==\n  URI: {s}\n  Cannot send HTTP request: {s}\n", .{ req4.uri, @errorName(err) }) catch @panic("OOM");
    };

    body_buf_writer.flush() catch @panic("OOM");

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
