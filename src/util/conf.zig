const std = @import("std");
const Ymlz = @import("ymlz").Ymlz;
const Types = @import("../model/conf.zig").Conf;

pub const ConfResult = struct {
    ymlz: Ymlz(Types),
    result: Types,
};

pub fn conf(file: []const u8) !ConfResult {
    const allo = std.heap.page_allocator;
    var ymlz = try Ymlz(Types).init(allo);

    const yml_path = try std.fs.cwd().realpathAlloc(
        allo,
        file,
    );
    defer allo.free(yml_path);



    const result = try ymlz.loadFile(yml_path);
    return ConfResult{
        .ymlz = ymlz,
        .result = result,
    };
}

test "t" {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // defer _ = gpa.deinit();
    //
    // const args = try std.process.argsAlloc(allocator);
    // defer std.process.argsFree(allocator, args);
    //
    // if (args.len < 2) {
    //     return error.NoPathArgument;
    // }


    // const yml_location = args[1];
    const yml_location = "src/file.yml";
    // 必须用var 否则 类型错误
    var result = try conf(yml_location);
    defer result.ymlz.deinit(result.result);
    std.debug.print("Tester: {any}\n", .{result.result});
    for (result.result.foods) |food| {
        std.debug.print("==={s}\n", .{food});
    }
}