const std = @import("std");
const spin = @import("spin");

fn handler(payload: []const u8) bool {
    std.io.getStdOut().writer().print("== PAYLOAD ==\n{s}\n", .{payload}) catch @panic("OOM");
    return true;
}

pub fn main() void {
    _ = spin.http;
    spin.redis.HANDLER = &handler;
}
