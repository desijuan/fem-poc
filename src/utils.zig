const std = @import("std");

pub fn print(val: anytype) void {
    const T = @TypeOf(val);
    const typeInfo: std.builtin.Type = @typeInfo(T);

    if (typeInfo != .Struct) {
        @compileError("Expecting a Struct type, got " ++ @tagName(typeInfo));
    }

    std.debug.print("{s} {{\n", .{@typeName(T)});
    inline for (typeInfo.Struct.fields) |field| {
        std.debug.print("   {s}: {},\n", .{ field.name, @field(val, field.name) });
    }
    std.debug.print("}}\n", .{});
}

pub inline fn evalLine(x: f64, x0: f64, y0: f64, x1: f64, y1: f64) f64 {
    return (x - x0) * (y1 - y0) / (x1 - x0) + y0;
}
