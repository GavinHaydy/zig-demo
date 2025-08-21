const zap = @import("zap");
const std = @import("std");

const Person = struct {
    name: []const u8,
    age: u32,
};

pub fn handleHello(r: zap.Request) !void {
    try r.sendJson("{\"msg\": \"hello\"}");
}

pub fn handlePost(r: zap.Request) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p = Person{
        .age = 18,
        .name = "GavinHaydy",
    };
    const result = try std.json.stringifyAlloc(allocator, p, .{});
    defer allocator.free(result);
    try r.sendJson(result);
}

pub fn handleGet(r: zap.Request) !void {
    return r.sendBody("{\"msg\": \"t\"}");
}