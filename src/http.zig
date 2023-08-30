//! HTTP component file containing manually maintained Zig bindings to the
//! auto-generated C bindings for Spin's inbound and outbound HTTP APIs.

const std = @import("std");

const C = @cImport({
    @cInclude("spin-http.h");
    @cInclude("wasi-outbound-http.h");
});

/// Full URL of the request, including full host and scheme information.
pub const FULL_URL = "spin-full-url";
/// Application base path.
pub const BASE_PATH = "spin-base-path";
/// Request path relative to the component route, including any base.
pub const PATH_INFO = "spin-path-info";
/// Client address for the request.
pub const CLIENT_ADDR = "spin-client-addr";
/// Route-matched part of the request path,
/// including the base and wildcard indicator if present.
pub const MATCHED_ROUTE = "spin-matched-route";
/// Component route pattern matched, excluding any wildcard indicator.
pub const COMPONENT_ROOT = "spin-component-route";
/// Component route pattern matched, as defined in the component manifest,
/// excluding the base, but including the wildcard indicator if present.
pub const RAW_COMPONENT_ROOT = "spin-raw-component-route";

const ERROR_TAGS = std.meta.tags(Error);

/// HTTP component's error set.
/// Value order is maintained for integer casting.
pub const Error = error{
    Unused,
    UnallowedDestination,
    InvalidUrl,
    BadRequest,
    BadRuntime,
};

/// Handler function for the inbound HTTP request trigger.
pub var HANDLER: *const fn (Request) Response = undefined;

/// HTTP request.
pub const Request = struct {
    body: std.ArrayListUnmanaged(u8) = undefined,
    headers: std.http.Headers = undefined,
    url: []const u8 = undefined,
    method: Method,
};

/// HTTP response.
pub const Response = struct {
    body: std.ArrayListUnmanaged(u8) = undefined,
    headers: std.http.Headers = undefined,
    status: std.http.Status = .ok,
};

/// Supported HTTP methods.
/// Value order is maintained for integer casting.
pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
};

/// Exported to be called from the auto-generated C bindings for Spin's inbound HTTP API.
pub export fn spin_http_handle_http_request(c_req: *C.spin_http_request_t, c_res: *C.spin_http_response_t) void {
    var req = Request{ .method = std.meta.intToEnum(Method, c_req.method) catch unreachable };

    if (c_req.body.is_some) {
        req.body.items.ptr = c_req.body.val.ptr;
        req.body.items.len = c_req.body.val.len;
    }

    req.headers = std.http.Headers.init(std.heap.wasm_allocator);

    var c_req_headers: []C.spin_http_tuple2_string_string_t = undefined;
    c_req_headers.ptr = c_req.headers.ptr;
    c_req_headers.len = c_req.headers.len;

    var value: []u8 = undefined;
    var name: []u8 = undefined;
    for (c_req_headers) |c_req_header| {
        name.ptr = c_req_header.f0.ptr;
        name.len = c_req_header.f0.len;
        value.ptr = c_req_header.f1.ptr;
        value.len = c_req_header.f1.len;
        req.headers.append(name, value) catch unreachable;
        if (std.mem.eql(u8, FULL_URL, name)) {
            req.url = value;
        }
    }

    const res = HANDLER(req);

    c_res.status = @as(u16, @intFromEnum(res.status));

    const headers_len = res.headers.list.items.len;

    if (headers_len > 0) {
        var res_headers = std.heap.wasm_allocator.alloc(C.spin_http_tuple2_string_string_t, headers_len) catch unreachable;

        for (res.headers.list.items, 0..) |header, i| {
            res_headers[i] = C.spin_http_tuple2_string_string_t{
                .f0 = C.spin_http_string_t{ .ptr = @constCast(@ptrCast(header.name.ptr)), .len = header.name.len },
                .f1 = C.spin_http_string_t{ .ptr = @constCast(@ptrCast(header.value.ptr)), .len = header.value.len },
            };
        }

        var c_res_headers: C.spin_http_headers_t = undefined;
        c_res_headers.ptr = @ptrCast(res_headers.ptr);
        c_res_headers.len = res_headers.len;

        c_res.headers = C.spin_http_option_headers_t{ .is_some = true, .val = c_res_headers };
    } else {
        c_res.headers = C.spin_http_option_headers_t{ .is_some = false, .val = undefined };
    }

    if (res.body.items.len > 0) {
        var body = std.heap.wasm_allocator.alloc(u8, res.body.items.len) catch unreachable;
        @memcpy(body, res.body.items[0..]);

        c_res.body = C.spin_http_option_body_t{ .is_some = true, .val = C.spin_http_body_t{ .ptr = body.ptr, .len = body.len } };
    } else {
        c_res.body = C.spin_http_option_body_t{ .is_some = false, .val = undefined };
    }
}

/// Sends the given HTTP request and returns the corresponding HTTP response.
/// The request destination must be explicitly allowed in the component manifest.
pub fn send(req: Request) Error!Response {
    var c_res: C.wasi_outbound_http_response_t = undefined;
    var c_req: C.wasi_outbound_http_request_t = undefined;

    c_req.method = @intFromEnum(req.method);
    c_req.uri = C.wasi_outbound_http_uri_t{ .ptr = @constCast(@ptrCast(req.url.ptr)), .len = req.url.len };

    if (req.headers.list.items.len > 0) {
        c_req.headers.len = req.headers.list.items.len;

        var c_req_headers = std.heap.wasm_allocator.alloc(C.wasi_outbound_http_tuple2_string_string_t, req.headers.list.items.len) catch unreachable;

        for (req.headers.list.items, 0..) |req_header, i| {
            c_req_headers[i].f0 = C.wasi_outbound_http_string_t{ .ptr = @constCast(@ptrCast(req_header.name.ptr)), .len = req_header.name.len };
            c_req_headers[i].f1 = C.wasi_outbound_http_string_t{ .ptr = @constCast(@ptrCast(req_header.value.ptr)), .len = req_header.value.len };
        }

        c_req.headers.ptr = c_req_headers.ptr;
    }

    if (req.body.items.len > 0) {
        c_req.body.is_some = true;
        c_req.body.val = C.wasi_outbound_http_body_t{ .ptr = @ptrCast(req.body.items.ptr), .len = req.body.items.len };
    } else {
        c_req.body.is_some = false;
    }

    const status_code = C.wasi_outbound_http_request(&c_req, &c_res);
    if (status_code > 0 and status_code < 5) {
        return ERROR_TAGS[status_code];
    }

    var res = Response{ .status = std.meta.intToEnum(std.http.Status, c_res.status) catch unreachable };

    if (c_res.body.is_some) {
        res.body.items.ptr = @ptrCast(c_res.body.val.ptr);
        res.body.items.len = c_res.body.val.len;
    }

    if (c_res.headers.is_some) {
        res.headers = std.http.Headers.init(std.heap.wasm_allocator);
        res.headers.append("Content-Type", "text/plain") catch unreachable;

        var c_res_headers: []C.wasi_outbound_http_tuple2_string_string_t = undefined;
        c_res_headers.ptr = c_res.headers.val.ptr;
        c_res_headers.len = c_res.headers.val.len;

        var name: []u8 = undefined;
        var value: []u8 = undefined;
        for (c_res_headers) |c_res_header| {
            name.ptr = c_res_header.f0.ptr;
            name.len = c_res_header.f0.len;
            value.ptr = c_res_header.f1.ptr;
            value.len = c_res_header.f1.len;
            res.headers.append(name, value) catch unreachable;
        }
    }

    return res;
}
