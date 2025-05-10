const std = @import("std");
const mat3d = @import("mat3d.zig");
const Mat3x3 = mat3d.Mat3x3;
const Vec3 = mat3d.Vec3;

const c = @import("c.zig");

const DEBUG = @import("config.zig").DEBUG;

n_rows: u32,
n_cols: u32,
entries: []f64,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, n_rows: u32, n_cols: u32) error{OutOfMemory}!Self {
    const entries = try allocator.alloc(f64, n_rows * n_cols);
    @memset(entries, 0);

    return .{
        .n_rows = n_rows,
        .n_cols = n_cols,
        .entries = entries,
    };
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.entries);
}

pub fn itemsC(self: Self) [*c]f64 {
    return @ptrCast(self.entries.ptr);
}

pub fn reset(self: Self) void {
    @memset(self.entries, 0);
}

pub fn get(self: Self, i: u32, j: u32) f64 {
    if (comptime DEBUG) self.checkIndices(i, j);
    return self.entries[(j - 1) * self.n_rows + i - 1];
}

pub fn set(self: Self, i: u32, j: u32, value: f64) void {
    if (comptime DEBUG) self.checkIndices(i, j);
    self.entries[(j - 1) * self.n_rows + i - 1] = value;
}

pub fn addTo(self: Self, i: u32, j: u32, value: f64) void {
    if (comptime DEBUG) self.checkIndices(i, j);
    self.entries[(j - 1) * self.n_rows + i - 1] += value;
}

pub fn setEntries(self: Self, entries: []const f64) void {
    if (comptime DEBUG) if (entries.len != self.entries.len)
        std.debug.panic("entries = {} and self.entries = {} are different", .{ entries.len, self.entries.len });

    @memcpy(self.entries, entries);
}

pub fn format(
    self: Self,
    comptime fmt: []const u8,
    _: std.fmt.FormatOptions,
    out_stream: anytype,
) !void {
    if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);

    for (0..self.n_rows) |i| {
        try std.fmt.format(out_stream, "{d:3}: [{e:7.2}", .{ i + 1, self.entries[i] });
        for (1..self.n_cols) |j| try std.fmt.format(out_stream, " {e:7.2}", .{self.entries[j * self.n_rows + i]});
        try std.fmt.format(out_stream, " ]\n", .{});
    }
}

pub fn sub3x3(self: Self, di: u32, dj: u32) Mat3x3 {
    const start = 3 * dj * self.n_cols + 3 * di;
    const stride = self.n_cols;

    return Mat3x3{
        @as(*const [3]f64, @ptrCast(&self.entries[start + 0 * stride])).*,
        @as(*const [3]f64, @ptrCast(&self.entries[start + 1 * stride])).*,
        @as(*const [3]f64, @ptrCast(&self.entries[start + 2 * stride])).*,
    };
}

pub fn copySub3x3(self: Self, di: u32, dj: u32, m: Mat3x3) void {
    const start = 3 * dj * self.n_cols + 3 * di;
    const stride = self.n_cols;

    @as(*[3]f64, @ptrCast(&self.entries[start + 0 * stride])).* = m[0];
    @as(*[3]f64, @ptrCast(&self.entries[start + 1 * stride])).* = m[1];
    @as(*[3]f64, @ptrCast(&self.entries[start + 2 * stride])).* = m[2];
}

pub fn solveCholesky(m: Self, f: Self) error{LapackeError}!void {
    if (comptime DEBUG) // Check sizes
        if (m.n_cols != m.n_rows)
            std.debug.panic("Matrix m is not square!\nm.n_rows = {}, m.n_cols{}", .{ m.n_rows, m.n_cols })
        else if (f.n_rows != m.n_rows)
            std.debug.panic("f.n_rows = {} != {}", .{ f.n_rows, m.n_rows })
        else if (f.n_cols != 1)
            std.debug.panic("f.n_cols = {} != 1", .{f.n_cols});

    if (comptime DEBUG) // Check symmetry of m
        for (2..@intCast(m.n_rows + 1)) |ui| {
            const i: u32 = @intCast(ui);

            for (1..i) |uj| {
                const j: u32 = @intCast(uj);

                if (m.get(i, j) != m.get(j, i))
                    std.debug.panic("Asymmetry at ({}, {})\n", .{ i, j });
            }
        };

    const N: i32 = @intCast(m.n_rows);

    const info_decomp = c.LAPACKE_dpotrf(c.LAPACK_COL_MAJOR, 'L', N, m.itemsC(), N);
    if (info_decomp != 0) {
        std.debug.print("LAPACKE_dpotrf error {}\n", .{info_decomp});
        return error.LapackeError;
    }

    const info_solve = c.LAPACKE_dpotrs(c.LAPACK_COL_MAJOR, 'L', N, 1, m.itemsC(), N, f.itemsC(), N);
    if (info_decomp != 0) {
        std.debug.print("LAPACKE_dpotrs error {}\n", .{info_solve});
        return error.LapackeError;
    }
}

fn checkIndices(self: Self, i: u32, j: u32) void {
    if (i < 1 or i > self.n_rows)
        std.debug.panic("Row idx i = {} out of bounds [1, {}]", .{ i, self.n_rows });
    if (j < 1 or j > self.n_cols)
        std.debug.panic("Col idx j = {} out of bounds [1, {}]", .{ j, self.n_cols });
}

const testing = std.testing;

fn expectNotEqual(comptime T: type, expected: T, actual: T) !void {
    if (actual == expected) {
        std.debug.print("Values are equal: expected {}, found {}\n", .{ expected, actual });
        return error.TestExpectedNotEqual;
    }
}

test init {
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    for (0..9) |i| try testing.expectEqual(0, m.entries[i]);
}

test reset {
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    for (m.entries) |entry| try expectNotEqual(f64, 0, entry);

    m.reset();

    for (m.entries) |entry| try testing.expectEqual(0, entry);
}

test get {
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    try testing.expectEqual(1.0, m.get(1, 1));
    try testing.expectEqual(2.0, m.get(1, 2));
    try testing.expectEqual(3.0, m.get(1, 3));
    try testing.expectEqual(4.0, m.get(2, 1));
    try testing.expectEqual(7.0, m.get(3, 1));
    try testing.expectEqual(9.0, m.get(3, 3));
    try testing.expectEqual(5.0, m.get(2, 2));
}

test set {
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    m.set(3, 3, 99.0);
    m.set(2, 2, 7.75);

    try testing.expectEqual(1.0, m.get(1, 1));
    try testing.expectEqual(2.0, m.get(1, 2));
    try testing.expectEqual(99.0, m.get(3, 3));
    try testing.expectEqual(7.75, m.get(2, 2));
}

test addTo {
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    m.addTo(1, 1, 99.0);
    m.addTo(2, 2, 7.75);

    try testing.expectEqual(100.0, m.get(1, 1));
    try testing.expectEqual(2.0, m.get(1, 2));
    try testing.expectEqual(9.0, m.get(3, 3));
    try testing.expectEqual(12.75, m.get(2, 2));
}

test format {
    const expected =
        \\  1: [ 1.00e0  2.00e0  3.00e0 ]
        \\  2: [ 4.00e0  5.00e0  6.00e0 ]
        \\  3: [ 7.00e0  8.00e0  9.00e0 ]
        \\
    ;
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    var line_buffer: [expected.len]u8 = undefined;
    var fbs: std.io.FixedBufferStream([]u8) = std.io.fixedBufferStream(&line_buffer);

    try fbs.writer().print("{}", .{m});

    try testing.expectEqualSlices(u8, expected, fbs.getWritten());
}

test sub3x3 {
    const ta = testing.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    const m3x3 = m.sub3x3(0, 0);

    for ([3]u32{ 1, 2, 3 }) |i| for ([3]u32{ 1, 2, 3 }) |j| try testing.expectEqual(m.get(i, j), m3x3[j - 1][i - 1]);
}

test "Cholesky 1x1" {
    const ta = testing.allocator;

    var m = try init(ta, 1, 1);
    defer m.deinit(ta);
    m.setEntries(&.{4.0}); // K = 4

    var f = try init(testing.allocator, 1, 1);
    defer f.deinit(ta);
    f.setEntries(&.{4.0}); // f = 4

    try solveCholesky(m, f);

    try testing.expectEqual(1, f.entries[0]);
}

test "Cholesky 3x3" {
    const ta = testing.allocator;

    var m = try init(ta, 3, 3);
    defer m.deinit(ta);

    // [   4,  12, -16 ]
    // [  12,  37, -43 ]
    // [ -16, -43,  98 ]

    m.setEntries(&.{ 4, 12, -16, 12, 37, -43, -16, -43, 98 });

    var f = try init(ta, 3, 1);
    defer f.deinit(ta);

    f.setEntries(&.{ 0, 6, 39 });

    try solveCholesky(m, f);

    try testing.expectEqualSlices(f64, &.{ 1, 1, 1 }, f.entries);
}
