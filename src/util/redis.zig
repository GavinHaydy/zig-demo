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


    // -------- Hash 操作 --------
    pub fn hset(self: *RedisClient, hash: []const u8, field: []const u8, value: []const u8) !void {
        try self.client.send(void, .{ "HSET", hash, field, value });
    }

    pub fn hget(self: *RedisClient, hash: []const u8, field: []const u8) !?[]const u8 {
        return try self.client.sendAlloc(?[]const u8, self.allocator, .{ "HGET", hash, field });
    }


    // -------- List 操作 --------
    pub fn lpush(self: *RedisClient, list: []const u8, value: []const u8) !void {
        try self.client.send(void, .{ "LPUSH", list, value });
    }

    pub fn rpop(self: *RedisClient, list: []const u8) !?[]const u8 {
        return try self.client.sendAlloc(?[]const u8, self.allocator, .{ "RPOP", list });
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

    // ---- 通用 SET，支持可选过期 ----
    pub fn setEx(key: []const u8, value: []const u8, expire_seconds: ?i64) !void {
        const client = try ensureInit();
        if (expire_seconds) |sec| {
            try client.client.send(void, .{ "SET", key, value, "EX", sec });
        } else {
            try client.client.send(void, .{ "SET", key, value });
        }
    }

    // ---- 通用 GET ----
    pub fn get(key: []const u8) !?[]const u8 {
        const client = try ensureInit();
        return try client.client.sendAlloc(?[]const u8, client.allocator, .{ "GET", key });
    }

    // ---- 删除 ----
    pub fn del(key: []const u8) !void {
        const client = try ensureInit();
        try client.client.send(void, .{ "DEL", key });
    }

    // ---- 修改过期时间 ----
    pub fn expire(key: []const u8, seconds: i64) !void {
        const client = try ensureInit();
        try client.client.send(void, .{ "EXPIRE", key, seconds });
    }

    // 查看剩余过期时间 s 不存在为 -2
    pub fn ttl(key: []const u8) !i64 {
        const client = try ensureInit();
        // TTL 返回的是整数
    return try client.client.send(i64, .{ "TTL", key });
    }

    // 查看剩余过期时间 ms
    pub fn pttl(key: []const u8) !i64 {
        const client = try ensureInit();
        return try client.client.send(i64, .{ "PTTL", key });
    }

    // -------- Hash --------
    pub fn hset(hash: []const u8, field: []const u8, value: []const u8) !void {
        const client = try ensureInit();
        try client.hset(hash, field, value);
    }

    pub fn hget(hash: []const u8, field: []const u8) !?[]const u8 {
        const client = try ensureInit();
        return try client.hget(hash, field);
    }

    // -------- List --------
    pub fn lpush(list: []const u8, value: []const u8) !void {
        const client = try ensureInit();
        try client.lpush(list, value);
    }

    pub fn rpop(list: []const u8) !?[]const u8 {
        const client = try ensureInit();
        return try client.rpop(list);
    }

    pub fn lrange(list: []const u8, start: i64, stop: i64) ![]?[]const u8 {
        const client = try ensureInit();
        // 返回一个数组，每个元素是列表项
    return try client.client.sendAlloc([]?[]const u8, client.allocator, .{ "LRANGE", list, start, stop });
    }

    pub fn llen(list: []const u8) !i64 {
        const client = try ensureInit();
        return try client.client.send(i64, .{ "LLEN", list });
    }


    pub fn close() void {
        if (instance) |*c| {
            c.close();
            instance = null;
        }
    }
};

test "string" {
    try rds.setEx("test10", "gavin", 10);
    try rds.setEx("test_null", "gavin", null);
    const x = try rds.get("test_null");
    const test_str = try rds.get("test10");
    std.debug.print("{?s}\n", .{x});
    if (test_str) |t| {
        std.debug.print("{s}\n", .{t});
    }

    // 获取过期时间
    const ttl_s = try rds.ttl("test10");
    std.debug.print("{d}\n", .{ttl_s});

    rds.close();
}

test "hash" {
    try rds.hset("user:1", "name", "Alice");
    if (try rds.hget("user:1", "name")) |val| {
        std.debug.print("HGET user:1 name: {s}\n", .{val});
    }
}

test "list" {
    // push
    try rds.lpush("tasks", "task1");
    if (try rds.llen("tasks")) |val| {
        std.debug.print("RPOP tasks: {}\n", .{val});
    }

    // len
    const len = try rds.llen("tasks");
    std.debug.print("list: {d}\n", .{len});

    // lrange
    const all = try rds.lrange("tasks",0,-1);
    for (all) |task| {
        if (task) |val| { // task 是 ?[]const u8
        std.debug.print("val: {s}\n", .{val});
        }
    }

    // pop
    if (try rds.rpop("tasks")) |val| {
        std.debug.print("RPOP tasks: {s}\n", .{val});
    }

    // close
    rds.close();
}