const std = @import("std");

pub const Vec3 = @Vector(3, f64);
pub const Mat3x3 = [3]Vec3;

pub const id3x3 = Mat3x3{
    Vec3{ 1, 0, 0 },
    Vec3{ 0, 1, 0 },
    Vec3{ 0, 0, 1 },
};

pub fn cross(v: Vec3, w: Vec3) Vec3 {
    return Vec3{
        v[1] * w[2] - v[2] * w[1],
        v[2] * w[0] - v[0] * w[2],
        v[0] * w[1] - v[1] * w[0],
    };
}

pub fn multMv(m: Mat3x3, v: Vec3) Vec3 {
    return Vec3{
        m[0][0] * v[0] + m[1][0] * v[1] + m[2][0] * v[2],
        m[0][1] * v[0] + m[1][1] * v[1] + m[2][1] * v[2],
        m[0][2] * v[0] + m[1][2] * v[1] + m[2][2] * v[2],
    };
}

pub fn multMM(m1: Mat3x3, m2: Mat3x3) Mat3x3 {
    return Mat3x3{
        multMv(m1, m2[0]),
        multMv(m1, m2[1]),
        multMv(m1, m2[2]),
    };
}

pub fn transposeM(m: *Mat3x3) void {
    var tmp: f64 = undefined;
    for (
        [3]u2{ 0, 0, 1 },
        [3]u2{ 1, 2, 2 },
    ) |i, j| {
        tmp = m[j][i];
        m[j][i] = m[i][j];
        m[i][j] = tmp;
    }
}

const testing = std.testing;

test cross {
    for (
        [_]Vec3{ .{ 1, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 } },
        [_]Vec3{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 1, 0, 0 } },
        [_]Vec3{ .{ 0, 0, 0 }, .{ 0, 0, 1 }, .{ 0, 0, -1 } },
    ) |v, w, expected|
        try testing.expectEqual(expected, cross(v, w));
}

test multMv {
    const m = Mat3x3{
        Vec3{ 1, 4, 7 },
        Vec3{ 2, 5, 8 },
        Vec3{ 3, 6, 9 },
    };
    const v = Vec3{ 10, 20, 30 };
    try testing.expectEqual(Vec3{ 140, 320, 500 }, multMv(m, v));
}

test multMM {
    const m1 = Mat3x3{
        Vec3{ 1, 4, 7 },
        Vec3{ 2, 5, 8 },
        Vec3{ 3, 6, 9 },
    };

    const m2 = Mat3x3{
        Vec3{ 10, 13, 16 },
        Vec3{ 11, 14, 17 },
        Vec3{ 12, 15, 18 },
    };

    try testing.expectEqual(Mat3x3{
        Vec3{ 84, 201, 318 },
        Vec3{ 90, 216, 342 },
        Vec3{ 96, 231, 366 },
    }, multMM(m1, m2));
}

test transposeM {
    var m = Mat3x3{
        Vec3{ 1, 4, 7 },
        Vec3{ 2, 5, 8 },
        Vec3{ 3, 6, 9 },
    };

    transposeM(&m);

    try testing.expectEqual(Mat3x3{
        Vec3{ 1, 2, 3 },
        Vec3{ 4, 5, 6 },
        Vec3{ 7, 8, 9 },
    }, m);
}
