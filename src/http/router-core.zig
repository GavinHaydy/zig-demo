const std = @import("std");
const zap = @import("zap");
const common = @import("../util/common.zig");

pub const Handler = *const fn (r: zap.Request) anyerror!void;

pub const Method = enum { GET, POST, PUT, DELETE };

pub const Router = struct {
    entries: std.ArrayList([]const u8),
    handlers: std.ArrayList(?Handler),
    methods: std.ArrayList(Method),

    pub fn init(allocator: std.mem.Allocator) Router {
        return Router{
            .entries = std.ArrayList([]const u8).init(allocator),
            .handlers = std.ArrayList(?Handler).init(allocator),
            .methods = std.ArrayList(Method).init(allocator),
        };
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

        if (r.body) |body| {
            std.debug.print("comptime fmt: []const u8 {s}\n", .{body});
        }


        const path = r.path orelse {
            try r.sendJson("{\"error\":\"no path\"}");
            return;
        };

        // 转换解构的method
        const reqM = try parseMethod(r.method.?);

        var path_found = false;

        for (0..self.entries.items.len) |i| {
            const p = self.entries.items[i];
            const m = self.methods.items[i];
            const h = self.handlers.items[i];

            if (std.mem.eql(u8, path, p)) {
                path_found = true;
                if (reqM == m) {
                    if (h) |handler| {
                        try handler(r);
                        return;
                    }
                }
            }
        }

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
