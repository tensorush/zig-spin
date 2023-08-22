const std = @import("std");
const http = @import("spin").http;

const log = std.log.scoped(.config);

const Error = std.os.WriteError;

pub fn main() Error!void {
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    try writer.writeAll("content-type: text/plain\n\n");

    const key_ptr: [*c]u8 = @constCast("message");

    const res = http.spin_http_handle_http_request(key_ptr, 7);

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





func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.Header().Set("foo", "bar")

		fmt.Fprintln(w, "== REQUEST ==")
		fmt.Fprintln(w, "URL:    ", r.URL)
		fmt.Fprintln(w, "Method: ", r.Method)
		fmt.Fprintln(w, "Headers:")
		for k, v := range r.Header {
			fmt.Fprintf(w, "  %q: %q \n", k, v[0])
		}

		body, err := io.ReadAll(r.Body)
		if err != nil {
			fmt.Fprintln(w, "Body Error: ", err)
		} else {
			fmt.Fprintln(w, "Body:   ", string(body))
		}

		fmt.Fprintln(w, "== RESPONSE ==")
		fmt.Fprintln(w, "Hello Fermyon!")
	})
}
