const std = @import("std");

const C = @cImport({
    @cInclude("spin-http.h");
    @cInclude("wasi-outbound-http.h");
});

const URI_LEN: u16 = 1 << 8;
const BODY_LEN: u16 = 1 << 13;

const allocator = std.heap.page_allocator;

/// The application base path.
pub const HEADER_BASE_PATH = "spin-base-path";
/// The component route pattern matched, _excluding_ any wildcard indicator.
pub const HEADER_COMPONENT_ROOT = "spin-component-route";
/// The full URL of the request. This includes full host and scheme information.
pub const HEADER_FULL_URL = "spin-full-url";
/// The part of the request path that was matched by the route
/// (including the base and wildcard indicator if present).
pub const HEADER_MATCHED_ROUTE = "spin-matched-route";
/// The request path relative to the component route (including any base).
pub const HEADER_PATH_INFO = "spin-path-info";
/// The component route pattern matched, as written in the component manifest
/// (that is, _excluding_ the base, but including the wildcard indicator if present).
pub const HEADER_RAW_COMPONENT_ROOT = "spin-raw-component-route";
/// The client address for the request.
pub const HEADER_CLIENT_ADDR = "spin-client-addr";

const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
};

pub export fn spin_http_handle_http_request(req: *C.spin_http_request_t, res: *C.spin_http_response_t) void {
    var body: []u8 = undefined;

    if (req.body.is_some) {
        body.ptr = req.body.val.ptr;
        body.len = req.body.val.len;
    }

    const method = std.meta.intToEnum(Method, req.method) catch unreachable;
    _ = method;

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var headers = std.http.Headers.init(allocator);
    defer headers.deinit();

    var spin_headers: []C.spin_http_tuple2_string_string_t = undefined;

    spin_headers.ptr = req.headers.ptr;
    spin_headers.len = req.headers.len;

    for (spin_headers) |spin_header| {
        var name: []u8 = undefined;
        name.ptr = spin_header.f0.ptr;
        name.len = spin_header.f0.len;
        var value: []u8 = undefined;
        value.ptr = spin_header.f1.ptr;
        value.len = spin_header.f1.len;
        headers.append(name, value);
    }

    const uri = try std.Uri.parse(headers.getFirstValue(HEADER_FULL_URL).?);

    var r = try client.request(.GET, uri, headers, .{});
    defer r.deinit();

    try r.start();
    try r.wait();

    res.status = @as(u16, @intFromEnum(r.response.status));

    const headers_len = r.response.headers.list.items.len;

    var req_headers: C.spin_http_headers_t = undefined;
    if (headers_len > 0) {
        req_headers.len = headers_len;

        req_headers.ptr = @as(*C.spin_http_tuple2_string_string_t, C.malloc(headers_len * @sizeOf(C.spin_http_tuple2_string_string_t)));

        const req_headers_slice: C.spin_http_tuple2_string_string_t = undefined;

        req_headers_slice.ptr = req_headers.ptr;
        req_headers_slice.len = headers_len;

        for (r.response.headers.list.items, 0..) |field, i| {
            req_headers_slice[i] = C.spin_http_tuple2_string_string_t{
                .f0 = C.spin_http_string_t{ .ptr = field.name, .len = field.name.len },
                .f1 = C.spin_http_string_t{ .ptr = field.value, .len = field.value.len },
            };
        }

        res.headers = C.spin_http_option_headers_t{ .is_some = true, .val = req_headers };
    } else {
        res.headers = C.spin_http_option_headers_t{ .is_some = false };
    }

    const body_buf: [BODY_LEN]u8 = undefined;
    const body_len = try r.readAll(body_buf[0..]);

    if (body_len > 0) {
        var body_ptr = @as(*C.uint8_t, C.malloc(body_len));
        @memcpy(body_ptr, body_buf[0..body_len]);

        res.body = C.spin_http_option_body_t{ .is_some = true, .val = C.spin_http_body_t{ .ptr = body_ptr, .len = body_len } };
    } else {
        res.body = C.spin_http_option_body_t{ .is_some = false, .val = undefined };
    }
}

// pub fn send(req: *std.http.Client.Request) *std.http.Client.Response {
//     var spin_req: C.wasi_outbound_http_request_t = undefined;
//     var spin_res: C.wasi_outbound_http_response_t = undefined;

//     spin_req.method = @intFromEnum(req.method);

//     spin_req.uri = C.wasi_outbound_http_uri_t{ .ptr = req.uri, .len = URI_LEN };

//     spin_req.headers = toOutboundHeaders(req.Header);
//     spin_req.body = toOutboundReqBody(req.Body);

//     code = C.wasi_outbound_http_request(&spin_req, &spin_res);

//     return toResponse(&spin_res);
// }
