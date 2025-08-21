const std = @import("std");
const jwt = @import("zig-jwt");

pub fn genereteJWT(claims: anytype,key: []const u8) ![]const u8 {
    const alloc = std.heap.page_allocator;

    const token = jwt.SigningMethodHS256.init(alloc).sign(claims, key);
    return token;
}

// pub fn parseToken(token_string: []const u8) ![]const u8 {
//     const alloc = std.heap.page_allocator;
//
//
// }