const std = @import("std");
const redis = @import("okredis");
const Client = redis.Client;


pub const RedisClient = struct {
    client: Client,
    allocator: std.mem.Allocator, // ✅ 加上 allocator 字段

    pub fn init(allocator: std.mem.Allocator,connection: std.net.Stream, user:?[]const u8,pass: []const u8) !RedisClient {
        var client: Client = undefined;
        try Client.init(&client, connection, .{
            .auth = .{
                .user = user,
                .pass = pass,
            }
        });

        return RedisClient{
            .client = client,
            .allocator = allocator,
        };
    }

    pub fn close(self: *RedisClient) void {
        self.client.close();
    }

    pub fn set(self: *RedisClient, key: []const u8, value: []const u8) !void {
        try self.client.send(void, .{ "SET", key, value });
    }

    pub fn get(self: *RedisClient, key: []const u8) !?[]const u8 {
        return try self.client.sendAlloc(  ?[]const u8, self.allocator, .{ "GET", key });
    }

};

/// ---- 全局 Redis 单例（懒加载） ----
pub const rds = struct {
    var instance: ?RedisClient = null;
    // var lock: std.Thread.Mutex = std.Thread.Mutex.create(); // Zig 最新版初始化
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;

    fn ensureInit() !*RedisClient {

        if (instance == null) {
            // 这里写死配置，也可以改成读 config
            gpa = std.heap.GeneralPurposeAllocator(.{}){};
            const allocator = gpa.allocator();

            const addr = try std.net.Address.parseIp4("127.0.0.1", 6380);
            const connection = try std.net.tcpConnectToAddress(addr);

            instance = try RedisClient.init(allocator,connection,null,"mypassword");
        }
        return &instance.?;
    }

    pub fn set(key: []const u8, value: []const u8) !void {
        const client = try ensureInit();
        try client.set(key, value);
    }

    pub fn get(key: []const u8) !?[]const u8 {
        const client = try ensureInit();
        return try client.get(key);
    }

    pub fn close() void {
        if (instance) |*c| {
            c.close();
            instance = null;
        }
    }
};

test "rds" {
    try rds.set("hello", "world");
    if (try rds.get("hello")) |val| {
        std.debug.print("Got: {s}\n", .{val});
    }
    rds.close();
}