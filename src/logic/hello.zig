const zap = @import("zap");
const std = @import("std");
const common = @import("../util/common.zig");
const jwt = @import("../util/jwt.zig");

const Person = struct {
    name: []const u8,
    age: u32,
};

pub fn handleHello(r: zap.Request) !void {
    try r.sendJson("{\"msg\": \"hello\"}");
}

pub fn handleLogin(r: zap.Request) !void {
    const loginForm = struct {
        name: []const u8,
        age: u64,
    };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const loginInfo = try std.json.parseFromSlice(
        std.json.Value,
        std.heap.page_allocator,
        r.body.?,
        .{}
    );
    defer loginInfo.deinit();
    const userInfo = try common.fromJson(loginForm, loginInfo.value);
    // std.debug.print("\n{s}\n", .{userInfo.name});
    const now = std.time.timestamp();
    const calime = .{
        .userID = userInfo.name,
        .iat = now,
        .exp = now + 3600,
    };
    const token = try jwt.genereteJWT(calime, "test");

    const rspInit = .{
        .token = token,
        .exp = now + 3600,
    };
    const result = try std.json.stringifyAlloc(allocator, rspInit, .{});
    defer allocator.free(result);

    try r.sendJson(result);
}

pub fn handleGet(r: zap.Request) !void {
    return r.sendBody("{\"msg\": \"t\"}");
}