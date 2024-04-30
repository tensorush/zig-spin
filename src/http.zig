//! HTTP component file containing manually maintained Zig bindings to the
//! auto-generated C bindings for Spin's inbound and outbound HTTP APIs.

const std = @import("std");

const C = @cImport({
    @cInclude("spin-http.h");
    @cInclude("wasi-outbound-http.h");
});

/// Full URL of the request, including full host and scheme information.
pub const FULL_URL_HEADER = "spin-full-url";
/// Application base path.
pub const BASE_PATH_HEADER = "spin-base-path";
/// Request path relative to the component route, including any base.
pub const PATH_INFO_HEADER = "spin-path-info";
/// Client address for the request.
pub const CLIENT_ADDR_HEADER = "spin-client-addr";
/// Route-matched part of the request path,
/// including the base and wildcard indicator if present.
pub const MATCHED_ROUTE_HEADER = "spin-matched-route";
/// Component route pattern matched, excluding any wildcard indicator.
pub const COMPONENT_ROOT_HEADER = "spin-component-route";
/// Component route pattern matched, as defined in the component manifest,
/// excluding the base, but including the wildcard indicator if present.
pub const RAW_COMPONENT_ROOT_HEADER = "spin-raw-component-route";

/// User's handler function for the inbound HTTP request trigger.
pub var HANDLER: *const fn (Request) Response = undefined;

/// HTTP request or response body.
pub const Body = std.ArrayList(u8);
/// HTTP request or response headers.
pub const Headers = std.ArrayList(Header);

/// HTTP component's error set.
/// Error value order is preserved for integer casting.
pub const Error = error{
    Success,
    DestinationNotAllowed,
    InvalidUrl,
    RequestError,
    RuntimeError,
    TooManyRequests,
};

/// HTTP request method.
/// Enum tag order is preserved for integer casting.
pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
};

/// HTTP request or response header.
pub const Header = std.http.Header;

/// HTTP request.
pub const Request = struct {
    headers: Headers = Headers.init(std.heap.c_allocator),
    body: Body = Body.init(std.heap.c_allocator),
    uri: []const u8 = &.{},
    method: Method = .GET,
};

/// HTTP response.
pub const Response = struct {
    headers: Headers = Headers.init(std.heap.c_allocator),
    body: Body = Body.init(std.heap.c_allocator),
    status: std.http.Status = .ok,
};

/// Exported to be called from auto-generated C bindings for Spin's inbound HTTP API.
pub export fn spin_http_handle_http_request(c_req: *C.spin_http_request_t, c_res: *C.spin_http_response_t) void {
    var req = Request{ .method = @enumFromInt(c_req.method) };

    if (c_req.body.is_some) {
        req.body.items.ptr = c_req.body.val.ptr;
        req.body.items.len = c_req.body.val.len;
    }

    req.headers.ensureTotalCapacity(c_req.headers.len) catch @panic("OOM");
    defer req.headers.deinit();

    var c_req_headers: []const C.spin_http_tuple2_string_string_t = &.{};
    c_req_headers.ptr = c_req.headers.ptr;
    c_req_headers.len = c_req.headers.len;

    var header = Header{
        .name = &.{},
        .value = &.{},
    };
    for (c_req_headers) |c_req_header| {
        header.name.ptr = c_req_header.f0.ptr;
        header.name.len = c_req_header.f0.len;
        header.value.ptr = c_req_header.f1.ptr;
        header.value.len = c_req_header.f1.len;
        req.headers.appendAssumeCapacity(header);
        if (std.mem.eql(u8, FULL_URL_HEADER, header.name)) {
            req.uri = header.value;
        }
    }

    const res = HANDLER(req);
    c_res.status = @as(u16, @intFromEnum(res.status));

    if (res.headers.items.len > 0) {
        var c_res_header_tuples = std.heap.c_allocator.alloc(C.spin_http_tuple2_string_string_t, res.headers.items.len) catch @panic("OOM");

        for (res.headers.items, 0..) |res_header, i| {
            c_res_header_tuples[i] = .{
                .f0 = .{ .ptr = @constCast(res_header.name.ptr), .len = res_header.name.len },
                .f1 = .{ .ptr = @constCast(res_header.value.ptr), .len = res_header.value.len },
            };
        }

        c_res.headers = .{ .is_some = true, .val = .{ .ptr = c_res_header_tuples.ptr, .len = c_res_header_tuples.len } };
    } else {
        c_res.headers = .{ .is_some = false };
    }

    if (res.body.items.len > 0) {
        c_res.body = .{ .is_some = true, .val = .{ .ptr = @constCast(res.body.items.ptr), .len = res.body.items.len } };
    } else {
        c_res.body = .{ .is_some = false };
    }
}

/// Send HTTP request and return corresponding HTTP response.
/// Request destination must be explicitly allowed in component manifest.
pub fn send(req: Request) Error!Response {
    var c_res = C.wasi_outbound_http_response_t{};
    var c_req = C.wasi_outbound_http_request_t{};

    c_req.method = @intFromEnum(req.method);
    c_req.uri = .{ .ptr = @constCast(req.uri.ptr), .len = req.uri.len };

    if (req.headers.items.len > 0) {
        var c_req_headers = std.heap.c_allocator.alloc(C.wasi_outbound_http_tuple2_string_string_t, req.headers.items.len) catch @panic("OOM");

        for (req.headers.items, 0..) |req_header, i| {
            c_req_headers[i] = .{
                .f0 = .{ .ptr = @constCast(req_header.name.ptr), .len = req_header.name.len },
                .f1 = .{ .ptr = @constCast(req_header.value.ptr), .len = req_header.value.len },
            };
        }

        c_req.headers.ptr = c_req_headers.ptr;
        c_req.headers.len = c_req_headers.len;
    }

    if (req.body.items.len > 0) {
        c_res.body = .{ .is_some = true, .val = .{ .ptr = req.body.items.ptr, .len = req.body.items.len } };
    } else {
        c_res.body = .{ .is_some = false };
    }

    const status_code = C.wasi_outbound_http_request(&c_req, &c_res);
    if (status_code > 0 and status_code < 5) {
        return std.meta.tags(Error)[status_code];
    }

    var res = Response{ .status = @enumFromInt(c_res.status) };

    if (c_res.body.is_some) {
        res.body.items.ptr = c_res.body.val.ptr;
        res.body.items.len = c_res.body.val.len;
    }

    if (c_res.headers.is_some) {
        res.headers.ensureTotalCapacity(c_res.headers.val.len + 1) catch @panic("OOM");
        res.headers.appendAssumeCapacity(.{ .name = "Content-Type", .value = "text/plain" });

        var c_res_headers: []const C.wasi_outbound_http_tuple2_string_string_t = &.{};
        c_res_headers.ptr = c_res.headers.val.ptr;
        c_res_headers.len = c_res.headers.val.len;

        var header = Header{
            .name = &.{},
            .value = &.{},
        };
        for (c_res_headers) |c_res_header| {
            header.name.ptr = c_res_header.f0.ptr;
            header.name.len = c_res_header.f0.len;
            header.value.ptr = c_res_header.f1.ptr;
            header.value.len = c_res_header.f1.len;
            res.headers.appendAssumeCapacity(header);
        }
    }

    return res;
}
