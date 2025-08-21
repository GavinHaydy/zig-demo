const std = @import("std");

/// 判断字符串是否在字符串数组中
pub fn containsStr(haystack: []const []const u8, needle: []const u8) bool {
    for (haystack) |s| {
        if (std.mem.eql(u8, s, needle)) {
            return true;
        }
    }
    return false;
}

/// 判断枚举值是否在数组中
pub fn containsEnum(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |item| {
        if (item == needle) {
            return true;
        }
    }
    return false;
}

// 转json
pub fn fromJson(comptime T: type, value: std.json.Value) !T {
    const info = @typeInfo(T);
    if (info != .@"struct") @compileError("fromJson only works on structs");

    var result: T = undefined;

    inline for (info.@"struct".fields) |field| {
        const ftype = field.type;
        const fname = field.name;

        const jsonVal = value.object.get(fname) orelse
            return error.MissingField;

        switch (@typeInfo(ftype)) {
            .int => {
                @field(result, fname) = @intCast(jsonVal.integer);
            },
            .float => {
                @field(result, fname) = @floatCast(jsonVal.float);
            },
            .bool => {
                @field(result, fname) = jsonVal.bool;
            },
            .pointer => {
                // ✅ 特殊处理 string (即 []const u8)
                if (ftype == []const u8) {
                    @field(result, fname) = jsonVal.string;
                } else {
                    @compileError("Unsupported pointer type: " ++ @typeName(ftype));
                }
            },
            .array => {
                @compileError("Array fields not supported yet: " ++ @typeName(ftype));
            },
            else => @compileError("Unsupported type in fromJson: " ++ @typeName(ftype)),
        }
    }

    return result;
}