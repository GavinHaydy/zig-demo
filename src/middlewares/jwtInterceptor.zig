const zap = @import("zap");
const std = @import("std");
const jwt = @import("../util/jwt.zig");
const Enums = @import("../enums/http.zig");


pub fn jwtInterceptor(r: zap.Request) bool {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // std.debug.print("{}", .{r});

    const token =r.getHeader("authorization") orelse "";
    if (std.mem.eql(u8, token, "")) {
        const bef_r = .{
            .code= @intFromEnum(Enums.StatusCode.unauthorized),
            .msg = Enums.StatusCode.unauthorized.toString(),
            .data = {}
        };

        const result = std.json.stringifyAlloc(allocator, bef_r, .{}) catch {
            r.sendJson("{\"code\":401,\"msg\":\"Unauthorized\"}") catch {};
            return false;
        };
        defer allocator.free(result);

        _ = r.sendJson(result) catch {};
        return false;
    }

    const userId =try jwt.parseToken(token);
    if (std.mem.eql(u8, userId, "")) {
        const rsp = .{
          .code = @intFromEnum(Enums.StatusCode.unauthorized),
            .msg = Enums.StatusCode.unauthorized.toString(),
            .data = {},
        };

        const result = std.json.stringifyAlloc(allocator, rsp, .{}) catch {
            r.sendJson("{\"code\":401,\"msg\":\"Unauthorized\"}") catch {};
            return false;
        };
        defer allocator.free(result);

        _ = r.sendJson(result) catch {};
        return false;
    }


    return true;
    // return try jwt.verifyJwt(token,"test");
}
