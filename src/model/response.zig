const StatusCode = @import("../enums/http.zig").StatusCode;
const std = @import("std");

pub fn Response(comptime T: type) type {
    return struct {
        code: u16,
        msg: []const u8,
        data: T,
    };
}
pub fn Result(comptime T: type, resp: Response(T)) ![]const u8 {
    // 此方式会导致内存无法释放
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allo = gpa.allocator();

    // 序列化
    return try std.json.stringifyAlloc(std.heap.page_allocator, resp, .{});

}


// 定义一个空数据类型，用于没有data返回的情况
const EmptyData = struct {};

/// 成功响应，无数据
pub fn success(comptime T: type) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.ok),
        .msg = StatusCode.ok.toString(),
        .data = EmptyData{}, // T类型，但我们不关心，用undefined占位
    };
}

/// 成功响应, 带 msg
pub fn successWithMsg(comptime T: type, msg: []const u8) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.ok),
        .msg = msg,
        .data = EmptyData{},
    };
}

/// 成功响应，带数据
pub fn successWithData(comptime T: type, data: T) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.ok),
        .msg = StatusCode.ok.toString(),
        .data = data,
    };
}

pub fn successFull(comptime T: type, msg: []const u8, data: T) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.ok),
        .msg = msg,
        .data = data,
    };
}

/// 失败响应，无数据
pub fn fail(comptime T: type) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.bad_request),
        .msg = StatusCode.bad_request.toString(),
        .data = EmptyData{},
    };
}

/// 失败响应, 带 msg
pub fn failWithMsg(comptime T: type, msg: []const u8) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.bad_request),
        .msg = msg,
        .data = EmptyData{},
    };
}

/// 失败响应，带数据
pub fn failWithData(comptime T: type, data: T) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.bad_request),
        .msg = StatusCode.bad_request.toString(),
        .data = data,
    };
}

pub fn failFull(comptime T: type, msg: []const u8, data: T) Response(T) {
    return Response(T){
        .code = @intFromEnum(StatusCode.bad_request),
        .msg = msg,
        .data = data,
    };
}



test "Response" {
    // --- 定义具体的 data 结构体 ---
    const User = struct {
        name: []const u8,
        age: i32,
    };
    // 实例化一个包含 User 数据的 Response 类型
    const UserResponse = Response(User);

    const user_data = User{
        .name = "Alice",
        .age = 30,
    };

    // 创建一个完整的响应对象
    const login_response = UserResponse{
        .code = @intFromEnum(StatusCode.ok),
        .msg = "Success",
        .data = user_data,
    };

    std.debug.print("响应状态码: {d}\n", .{login_response.code});
    std.debug.print("响应消息: {s}\n", .{login_response.msg});
    std.debug.print("数据: 姓名={s}, 年龄={d}\n", .{login_response.data.name, login_response.data.age});
}

test "Result" {
    const User = struct {
        name: []const u8,
        age: u8,
    };

    const resp = Response(User){
        .code = @intFromEnum(StatusCode.ok),
        .msg = "成功",
        .data = User{ .name = "Alice", .age = 30 },
    };

    const json_bytes = try Result(User, resp);
    // 调用后需要释放内存
    defer std.heap.page_allocator.free(json_bytes);
}