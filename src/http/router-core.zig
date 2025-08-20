const std = @import("std");
const zap = @import("zap");

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

    pub fn handleInternal(self: *Router, r: zap.Request) !void {
        if (r.path) |path| {
            const len = self.entries.items.len;
            for (0..len) |i| {
                const p = self.entries.items[i];
                if (std.mem.eql(u8, p, path)) {
                    if (self.handlers.items[i]) |h| {
                        try h(r);
                        return;
                    }
                }
            }
            try r.sendJson("{\"error\":\"not found\"}");
        } else {
            try r.sendJson("{\"error\":\"no path\"}");
        }
    }
};


pub var router: Router = undefined;

pub fn handle(r: zap.Request) anyerror!void {
    try router.handleInternal(r);
}