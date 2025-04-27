const std = @import("std");

pub inline fn evalLine(x: f64, x0: f64, y0: f64, x1: f64, y1: f64) f64 {
    return (x - x0) * (y1 - y0) / (x1 - x0) + y0;
}

pub fn structFormatFn(comptime T: type) fn (
    self: T,
    comptime fmt: []const u8,
    _: std.fmt.FormatOptions,
    out_stream: anytype,
) anyerror!void {
    comptime {
        const typeInfo: std.builtin.Type = @typeInfo(T);

        if (typeInfo != .@"struct") {
            @compileError("Expecting a Struct type, got " ++ @tagName(typeInfo));
        }
    }

    return struct {
        fn format(
            self: T,
            comptime fmt: []const u8,
            _: std.fmt.FormatOptions,
            out_stream: anytype,
        ) anyerror!void {
            if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);

            try std.fmt.format(out_stream, "{s} {{\n", .{@typeName(T)});
            inline for (@typeInfo(T).@"struct".fields) |field| {
                try std.fmt.format(out_stream, "   {s}: {},\n", .{ field.name, @field(self, field.name) });
            }
            try std.fmt.format(out_stream, "}}\n", .{});
        }
    }.format;
}
