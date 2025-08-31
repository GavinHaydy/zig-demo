const Pool = @import("pg").Pool;
// const Opts = @import("pg").Pool.Opts;
const std = @import("std");

const Allocator = std.mem.Allocator;
pub fn dal(alloctor: Allocator) !*Pool {
    const pool = try Pool.init(alloctor, .{
        .size = 5,
        .connect = .{
            .port = 5433,
            .host = "127.0.0.1",
        },
        .auth = .{
            .username = "postgres",
            .database = "ghrun",
            .password = "GavinHaydy2779",
            .timeout = 10_000,
        }
    });

    return pool;
}