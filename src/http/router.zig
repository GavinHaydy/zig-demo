const std = @import("std");
const Router = @import("router-core.zig").Router;
const hello = @import("../logic//hello.zig");

pub fn buildRouter(allocator: std.mem.Allocator) !Router {
    var router = Router.init(allocator);
    try router.get("/hello", hello.handleHello);

    return router;
}
