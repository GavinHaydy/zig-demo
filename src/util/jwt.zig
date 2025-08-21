const std = @import("std");
const jwt = @import("zig-jwt");

pub fn genereteJWT(claims: anytype,key: []const u8) ![]const u8 {
    const alloc = std.heap.page_allocator;

    const token = jwt.SigningMethodHS256.init(alloc).sign(claims, key);
    return token;
}

pub fn parseToken(token_string: []const u8) ![]const u8 {
    const alloc = std.heap.page_allocator;

    var token = jwt.Token.init(alloc);
    token.parse(token_string);

    const claims = token.getClaims() catch {
        return ""; // 如果解析 claims 出错，也返回空字符串
    };

    // const claims = try token.getClaims();
    const user_val = claims.value.object.get("userID") orelse null;

    if (user_val != null and !std.mem.eql(u8, user_val.?.string, "")) {
        return user_val.?.string;
    } else {
        return "";
    }
}


test "example" {
    const claime = .{
        .iss = "Gavin",
        .sub = "userName",
        .iat = std.time.timestamp(), // 当前时间戳
        .exp = std.time.timestamp() + 3600,
    };
    try genereteJWT(claime, "key");
}

test "parseToken" {
    const token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySUQiOiJHYXZpbiIsImlhdCI6MTc1NTc5NzM4NCwiZXhwIjoxNzU1ODAwOTg0fQ.7vUEDIYUtzJTjlsM2dmrdUlwsNHWaGuD2T_B_JfyuDw";
    try parseToken(token);
}