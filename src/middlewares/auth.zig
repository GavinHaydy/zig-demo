const std = @import("std");
const zap = @import("zap");

const Allocator = std.mem.Allocator;

// The "Application Context"
pub const MyContext = struct {
    bearer_token: []const u8,
};

// We reply with this
const HTTP_RESPONSE_TEMPLATE: []const u8 =
    \\ <html><body>
    \\   {s} from ZAP on {s} (token {s} == {s} : {s})!!!
    \\ </body></html>
    \\
;

// Our simple endpoint that will be wrapped by the authenticator
pub const MyEndpoint = struct {
    // the slug
    path: []const u8,
    error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

    fn get_bearer_token(r: zap.Request) []const u8 {
        const auth_header = zap.Auth.extractAuthHeader(.Bearer, &r) orelse "Bearer (no token)";
        return auth_header[zap.Auth.AuthScheme.Bearer.str().len..];
    }

    // authenticated GET requests go here
    // we use the endpoint, the context, the arena, and try
    pub fn get(ep: *MyEndpoint, arena: Allocator, context: *MyContext, r: zap.Request) !void {
        const used_token = get_bearer_token(r);
        const response = try std.fmt.allocPrint(
            arena,
            HTTP_RESPONSE_TEMPLATE,
            .{ "Hello", ep.path, used_token, context.bearer_token, "OK" },
        );
        r.setStatus(.ok);
        try r.sendBody(response);
    }

    // we also catch the unauthorized callback
    // we use the endpoint, the context, the arena, and try
    pub fn unauthorized(ep: *MyEndpoint, arena: Allocator, context: *MyContext, r: zap.Request) !void {
        r.setStatus(.unauthorized);
        const used_token = get_bearer_token(r);
        const response = try std.fmt.allocPrint(
            arena,
            HTTP_RESPONSE_TEMPLATE,
            .{ "UNAUTHORIZED", ep.path, used_token, context.bearer_token, "NOT OK" },
        );
        try r.sendBody(response);
    }
};
