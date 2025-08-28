const zap = @import("zap");
const std = @import("std");
const jwt = @import("../util/jwt.zig");


pub fn jwtInterceptor(r: zap.Request) bool {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // std.debug.print("{}", .{r});

    const token =r.getHeader("authorization") orelse "";
    if (std.mem.eql(u8, token, "")) {
        const bef_r = .{
            .code=200,
            .status=false,
            .msg = "token 没传",
        };

        const result = std.json.stringifyAlloc(allocator, bef_r, .{}) catch {
            r.sendJson("{\"code\":500,\"msg\":\"oom\"}") catch {};
            return false;
        };
        defer allocator.free(result);

        _ = r.sendJson(result) catch {};
        return false;
    }

    return true;
    // return try jwt.verifyJwt(token,"test");
}
