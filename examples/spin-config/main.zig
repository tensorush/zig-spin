const std = @import("std");
const config = @import("spin").config;

const C = @cImport({
    @cInclude("spin-config.h");
});

const log = std.log.scoped(.config);

const Error = std.os.WriteError;

pub fn main() Error!void {
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    try writer.writeAll("content-type: text/plain\n\n");

    const key_ptr: [*c]u8 = @constCast("message");

    const res = config.get(key_ptr, 7);

    try writer.print("message: {}\n", .{res.val.ok});

    // switch (res) {
    //     .ok => |str| try writer.print("message: {s}\n", .{str}),
    //     .err => |err| switch (err) {
    //         .invalid_schema => log.err("Invalid schema: {s}", .{err.invalid_schema}),
    //         .invalid_key => log.err("Invalid key: {s}", .{err.invalid_key}),
    //         .provider => log.err("Provider: {s}", .{err.provider}),
    //         .other => log.err("Other: {s}", .{err.other}),
    //     },
    // }

    try buf_writer.flush();
}
