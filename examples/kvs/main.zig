const std = @import("std");
const spin = @import("spin");

fn handler(req: spin.http.Request) spin.http.Response {
    var headers = spin.http.Headers.init(std.heap.c_allocator);
    headers.append(.{ .name = "Content-Type", .value = "text/plain" }) catch @panic("OOM");

    var body = spin.http.Body.init(std.heap.c_allocator);
    var body_buf_writer = std.io.bufferedWriter(body.writer());
    const body_writer = body_buf_writer.writer();

    var store = spin.kvs.Store.open("default") catch |err| {
        body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
        body_buf_writer.flush() catch @panic("OOM");
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };
    defer store.close();

    switch (req.method) {
        .GET => {
            const value = store.get(req.uri) catch |err| {
                body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
                body_buf_writer.flush() catch @panic("OOM");
                return .{ .headers = headers, .body = body, .status = .internal_server_error };
            };
            body_writer.print("== GET ==\n  Key: {s}\n  Value: {s}\n", .{ req.uri, value }) catch @panic("OOM");
        },
        .POST => {
            store.set(req.uri, req.body.items) catch |err| {
                body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
                body_buf_writer.flush() catch @panic("OOM");
                return .{ .headers = headers, .body = body, .status = .internal_server_error };
            };
            body_writer.print("== POST ==\n  Key: {s}\n  Value: {s}\n", .{ req.uri, req.body.items }) catch @panic("OOM");
        },
        .DELETE => {
            store.delete(req.uri) catch |err| {
                body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
                body_buf_writer.flush() catch @panic("OOM");
                return .{ .headers = headers, .body = body, .status = .internal_server_error };
            };
            body_writer.print("== DELETE ==\n  Key: {s}\n", .{req.uri}) catch @panic("OOM");
        },
        .HEAD => {
            const does_exist = store.exists(req.uri) catch |err| {
                body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
                body_buf_writer.flush() catch @panic("OOM");
                return .{ .headers = headers, .body = body, .status = .internal_server_error };
            };
            body_writer.print("== HEAD ==\n  Key: {s}\n  Status: {}\n", .{ req.uri, does_exist }) catch @panic("OOM");
        },
        .OPTIONS => {
            const keys = store.getKeys() catch |err| {
                body_writer.print("Error: {s}\n", .{@errorName(err)}) catch @panic("OOM");
                body_buf_writer.flush() catch @panic("OOM");
                return .{ .headers = headers, .body = body, .status = .internal_server_error };
            };
            body_writer.print("== OPTIONS ==\n", .{}) catch @panic("OOM");

            for (keys, 1..) |key, i| {
                body_writer.print("  Key {d}: {s}\n", .{ i, key }) catch @panic("OOM");
            }
        },
        else => body_writer.print("== {s} ==\n  Unknown method\n", .{@tagName(req.method)}) catch @panic("OOM"),
    }

    body_buf_writer.flush() catch @panic("OOM");

    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
