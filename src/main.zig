//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const zap = @import("zap");
const Router = @import("http/router-core.zig");
// const auth = @import("middlewares/auth.zig");
const buildRouter = @import("http/router.zig").buildRouter;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    Router.router = try buildRouter(allocator);

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = Router.handle,
        .log = true,
    });
    try listener.listen();

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 1,
    });
}
