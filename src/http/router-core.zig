const std = @import("std");
const zap = @import("zap");
const common = @import("../util/common.zig");

pub const Handler = *const fn (r: zap.Request) anyerror!void;

pub const Method = enum { GET, POST, PUT, DELETE };


// 新增：拦截器类型（true 放行 / false 拦截并已响应）
const InterceptorFn = *const fn (r: zap.Request) bool;

// 新增：白名单键（method = null 表示该 path 任意方法都白名单）
const RouteKey = struct {
    path: []const u8,
    method: ?Method, // null => any method
};

pub const Router = struct {
    entries: std.ArrayList([]const u8),
    handlers: std.ArrayList(?Handler),
    methods: std.ArrayList(Method),
    interceptors: std.ArrayList(InterceptorFn),
    whitelist: std.ArrayList(RouteKey),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Router {
        return Router{
            .entries = std.ArrayList([]const u8).init(allocator),
            .handlers = std.ArrayList(?Handler).init(allocator),
            .methods = std.ArrayList(Method).init(allocator),
            .interceptors = std.ArrayList(InterceptorFn).init(allocator),
            .whitelist = std.ArrayList(RouteKey).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Router) void {
        self.entries.deinit();
        self.methods.deinit();
        self.handlers.deinit();
        self.interceptors.deinit();
        self.whitelist.deinit();
    }

    // ✅ 添加全局拦截器
    pub fn addInterceptor(self: *Router, i: InterceptorFn) !void {
        try self.interceptors.append(i);
    }

    // ✅ 添加白名单（method = null 表示所有方法）
    pub fn addWhitelist(self: *Router, path: []const u8, method: ?Method) !void {
        try self.whitelist.append(.{ .path = path, .method = method });
    }
    // 便捷：只按 path 加白名单（所有方法）
    pub fn addWhitelistAny(self: *Router, path: []const u8) !void {
        try self.addWhitelist(path, null);
    }

    fn isWhitelisted(self: *Router, path: []const u8, method: Method) bool {
        for (self.whitelist.items) |w| {
            if (std.mem.eql(u8, w.path, path)) {
                if (w.method == null or w.method.? == method) return true;
            }
        }
        return false;
    }

    pub fn register(self: *Router, method: Method, path: []const u8, handler: Handler) !void {
        try self.entries.append(path);
        try self.handlers.append(handler);
        try self.methods.append(method);
    }

    pub fn get(self: *Router, path: []const u8, handler: Handler) !void {
        try self.register(.GET, path, handler);
    }

    pub fn post(self: *Router, path: []const u8, handler: Handler) !void {
        try self.register(.POST, path, handler);
    }

    pub fn put(self: *Router, path: []const u8, handler: Handler) !void {
        try self.register(.PUT, path, handler);
    }

    pub fn del(self: *Router, path: []const u8, handler: Handler) !void {
        try self.register(.DELETE, path, handler);
    }

    pub fn handleInternal(self: *Router, r: zap.Request) !void {
        std.debug.print("comptime fmt: []const u8-------{}", .{r});

        if (r.body) |body| {
            std.debug.print("comptime fmt: []const u8 {s}\n", .{body});
        }


        std.debug.print("==1\n", .{});
        const path = r.path orelse {
            std.debug.print("comptime fmt: []const u8", .{});
            try r.sendJson("{\"error\":\"no path\"}");
            return;
        };
        // 转换解构的method
        const reqM = try parseMethod(r.method.?);
        // 👇 白名单外的请求才跑全局拦截器链
        if (!self.isWhitelisted(path, reqM)) {
            std.debug.print("---{s}---", .{path});
            for (self.interceptors.items) |icp| {
                // if (!icp(&r)) return; // 被拦截器拦下且已响应
                // const rConst: *zap.Request = &r;
                if (!icp(r)) return; // 被拦截器拦下且已响应
            }
        }

        var path_found = false;

        for (0..self.entries.items.len) |i| {
            const p = self.entries.items[i];
            const m = self.methods.items[i];
            const h = self.handlers.items[i];
            std.debug.print("==5 path={s} reqM={} m={}\n", .{path, reqM, m});
            if (std.mem.eql(u8, path, p)) {
                path_found = true;
                if (reqM == m) {
                    if (h) |handler| {
                        std.debug.print("==5.1 调用 handler\n", .{});
                        // try handler(r);
                        // if (handler_err) |e| {
                        //     std.debug.print("handler 返回 error: {}\n", .{e});
                        // }
                        handler(r) catch |e| {
                            std.debug.print("handler 返回error: {}\n", .{e});
                        };
                        return;
                    }
                }
            }
        }
        std.debug.print("==6\n", .{});
        if (path_found) {
            try r.sendJson("{\"error\":\"method err\"}");
        } else {
            try r.sendJson("{\"error\":\"no path\"}");
        }
    }
};

pub var router: Router = undefined;

pub fn handle(r: zap.Request) anyerror!void {
    try router.handleInternal(r);
}

// ---------- 辅助函数：字符串转 Method enum ----------
fn parseMethod(s: []const u8) !Method {
    if (std.mem.eql(u8, s, "GET")) return .GET;
    if (std.mem.eql(u8, s, "POST")) return .POST;
    if (std.mem.eql(u8, s, "PUT")) return .PUT;
    if (std.mem.eql(u8, s, "DELETE")) return .DELETE;
    return error.InvalidMethod;
}
