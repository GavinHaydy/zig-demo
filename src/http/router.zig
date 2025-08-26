const std = @import("std");
const Router = @import("router-core.zig").Router;
const hello = @import("../logic//hello.zig");
const jwtInterceptor = @import("../middlewares/jwtInterceptor.zig");

pub fn buildRouter(allocator: std.mem.Allocator) !Router {
    var router = Router.init(allocator);
    try router.addInterceptor(jwtInterceptor.jwtInterceptor);
    try router.addWhitelistAny("/login");

    try router.get("/hello", hello.handleHello);
    try router.post("/login", hello.handleLogin);
    try router.get("/test",hello.handleGet);

    return router;
}
