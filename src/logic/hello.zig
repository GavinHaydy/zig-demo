const zap = @import("zap");

pub fn handleHello(r: zap.Request) !void {
    try r.sendJson("{\"msg\": \"hello\"}");
}
