const std = @import("std");
const spin = @import("spin");

const BODY_CAP: u8 = 1 << 7;
const STARTUP =
    \\ CREATE TABLE pets (id INT PRIMARY KEY, name VARCHAR(100) NOT NULL, prey VARCHAR(100), is_finicky BOOL NOT NULL);
    \\ INSERT INTO pets VALUES (1, 'Splodge', NULL, false);
    \\ INSERT INTO pets VALUES (2, 'Kiki', 'Cicadas', false);
    \\ INSERT INTO pets VALUES (3, 'Slats', 'Temptations', true);
;

const Pet = struct {
    id: i64,
    name: []const u8,
    prey: ?[]const u8,
    is_finicky: bool,
};

fn handler(_: spin.http.Request) spin.http.Response {
    var headers = std.http.Headers.init(std.heap.wasm_allocator);
    headers.append("Content-Type", "text/plain") catch unreachable;

    var body = std.ArrayListUnmanaged(u8).initCapacity(std.heap.wasm_allocator, BODY_CAP) catch unreachable;
    var buf_writer = std.io.bufferedWriter(body.writer(std.heap.wasm_allocator));
    const writer = buf_writer.writer();

    var db = spin.sqlite.Database.open("default") catch |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };
    defer db.close();

    _ = db.execute("REPLACE INTO pets VALUES (4, 'Maya', ?, false);", &.{.{ .string = "bananas" }}) catch |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    const data = db.execute("SELECT * FROM pets", &.{}) catch |err| {
        writer.print("Error: {s}\n", .{@errorName(err)}) catch unreachable;
        buf_writer.flush() catch unreachable;
        return .{ .headers = headers, .body = body, .status = .internal_server_error };
    };

    for (data.rows) |row| {
        writer.print("id = {d}, name = {s}, prey = {any}, is_finicky = {d}\n", .{ row[0].int, row[1].string, row[2].string, row[3].int }) catch unreachable;
    }

    buf_writer.flush() catch unreachable;
    return .{ .body = body, .headers = headers };
}

pub fn main() void {
    spin.http.HANDLER = &handler;
}
