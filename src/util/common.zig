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

// todo 获取 json 值
