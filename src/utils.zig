const std = @import("std");

const R = struct { x0: f64, y0: f64, x1: f64, y1: f64 };

pub inline fn evalLine(x: f64, r: R) f64 {
    return (x - r.x0) * (r.y1 - r.y0) / (r.x1 - r.x0) + r.y0;
}

pub inline fn range(comptime T: type, comptime start: comptime_int, comptime end: comptime_int) [end - start]T {
    comptime {
        if (start >= end) {
            @compileError("start must be strictly less than end");
        }

        var array: [end - start]T = undefined;

        for (0..array.len) |i|
            array[i] = start + i;

        return array;
    }
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

const t = std.testing;

test evalLine {
    const r = R{ .x0 = 0.0, .y0 = 0.0, .x1 = 1.0, .y1 = 2.0 };

    try t.expectEqual(0.0, evalLine(0.0, r));
    try t.expectEqual(1.0, evalLine(0.5, r));
    try t.expectEqual(2.0, evalLine(1.0, r));
}

test range {
    const v = range(u32, 11, 21);

    try t.expectEqual(10, v.len);
    try t.expectEqual(11, v[0]);
    try t.expectEqual(20, v[9]);
}
