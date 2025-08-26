const std = @import("std");
const jwt = @import("zig-jwt");
const common = @import("common.zig");

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

const calimsT = struct {
    userID: []const u8,
    iat: i64,
    exp: i64,
};

pub fn verifyJwt(token_str: []const u8, key: []const u8) !bool {
    const alloc = std.heap.page_allocator;

    var token = jwt.Token.init(alloc);
    token.parse(token_str);
    defer token.deinit();

    const x = token.claims;
    if (x.len == 0) return false; //解析失败
    std.debug.print("{s}\n", .{x});
    // to json value 解析异常直接返回false
    const parsed = std.json.parseFromSlice(std.json.Value, alloc, x, .{}) catch {
        return false;
    };
    defer parsed.deinit();
    const calims = try common.fromJson(calimsT, parsed.value);


    const new_sig = jwt.SigningMethodHS256.init(alloc).sign(calims, key) catch return false;

    return std.mem.eql(u8, new_sig, token_str);
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