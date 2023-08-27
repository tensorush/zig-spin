const std = @import("std");

// pub const kvs = @import("kvs.zig");
pub const http = @import("http.zig");
// pub const redis = @import("redis.zig");
pub const config = @import("config.zig");

pub var HANDLER: *const fn (http.Request) http.Response = undefined;

test {
    std.testing.refAllDecls(@This());
}
