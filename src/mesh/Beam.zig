const std = @import("std");
const utils = @import("../utils.zig");
const Matrix = @import("../Matrix.zig");
const Mesh = @import("Mesh.zig");
const MaterialProperties = @import("MaterialProperties.zig");
const mat3d = @import("../mat3d.zig");
const Mat3x3 = mat3d.Mat3x3;

const DEBUG = @import("../config.zig").DEBUG;

mat_props_idx: u32,
n0_idx: u32,
n1_idx: u32,
length: f64,
cross_area: f64, // fA
moment_x: f64, // fIy
moment_y: f64, // fIy
fJp: f64, // ?
fIp: f64, // ?

const Self = @This();

pub const format = @import("../utils.zig").structFormatFn(Self);

pub const BeamData = struct {
    E: f64, // Young's Modulus
    G: f64, // Shear Modulus
    A: f64, // Cross-sectional Area
    Iy: f64, // Moment of Inertia in y
    Iz: f64, // Moment of Inertia in z
    J: f64, // Torsional constant
    L: f64, // Length
};

///  fn calcLocakK(BeamData, Matrix) void
///
///  Calculates the Local Stiffness Matrix for a Beam element.
///
///  maps:
///  .{ E, G, A, Iy, Iz, J, L }
///
///  into:
///  ek =
///   1 [ EA/L,   0,          0,          0,      0,         0,         -EA/L,  0,          0,          0,      0,         0        ]
///   2 [ 0,      12EIz/L³,   0,          0,      0,         6EIz/L²,   0,      -12EIz/L³,  0,          0,      0,         6EIz/L²  ]
///   3 [ 0,      0,          12EIy/L³,   0,      -6EIy/L²,  0,         0,      0,          -12EIy/L³,  0,      -6EIy/L²,  0        ]
///   4 [ 0,      0,          0,          GJ/L,   0,         0,         0,      0,          0,          -GJ/L,  0,         0        ]
///   5 [ 0,      0,          -6EIy/L²,   0,      4EIy/L,    0,         0,      0,          6EIy/L²,    0,      2EIy/L,    0        ]
///   6 [ 0,      6EIz/L²,    0,          0,      0,         4EIz/L,    0,      -6EIz/L²,   0,          0,      0,         2EIz/L   ]
///   7 [ -EA/L,  0,          0,          0,      0,         0,         EA/L,   0,          0,          0,      0,         0        ]
///   8 [ 0,      -12EIz/L³,  0,          0,      0,         -6EIz/L²,  0,      12EIz/L³,   0,          0,      0,         -6EIz/L² ]
///   9 [ 0,      0,          -12EIy/L³,  0,      6EIy/L²,   0,         0,      0,          12EIy/L³,   0,      6EIy/L²,   0        ]
///  10 [ 0,      0,          0,          -GJ/L,  0,         0,         0,      0,          0,          GJ/L,   0,         0        ]
///  11 [ 0,      0,          -6EIy/L²,   0,      2EIy/L,    0,         0,      0,          6EIy/L²,    0,      4EIy/L,    0        ]
///  12 [ 0,      6EIz/L²,    0,          0,      0,         2EIz/L,    0,      -6EIz/L²,   0,          0,      0,         4EIz/L   ]
///       1       2           3           4       5          6          7       8           9          10      11         12
///
///  Writes the results into the Matrix ek. Clears ek.
///  Panics if ek is not 12x12.
///
pub fn calcLocalK(bd: BeamData, ek: Matrix) void {
    if (comptime DEBUG)
        if (ek.n_rows != 12 or ek.n_cols != 12) std.debug.panic(
            "Wrong size.\nek.n_rows: {}, ek.n_cols: {}",
            .{ ek.n_rows, ek.n_cols },
        );

    ek.reset();

    return for ([_]struct { idx: [2]u32, val: f64 }{
        //   1st col: (1, 1) EA/L, (7, 1) -EA/L
        .{ .idx = .{ 1, 1 }, .val = bd.E * bd.A / bd.L },
        .{ .idx = .{ 7, 1 }, .val = -bd.E * bd.A / bd.L },

        //   2nd col: (2, 2) 12EIz/L^3, (6, 2) 6EIz/L^2, (8, 2) -12EIz/L^3, (12, 2) 6EIz/L^2
        .{ .idx = .{ 2, 2 }, .val = 12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 6, 2 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 8, 2 }, .val = -12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 12, 2 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },

        //   3rd col: (3, 3) 12EIy/L^3, (5, 3) -6EIy/L^2, (9, 3) -12EIy/L^3, (11, 3) -6EIy/L^2
        .{ .idx = .{ 3, 3 }, .val = 12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 5, 3 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 9, 3 }, .val = -12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 11, 3 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },

        //   4th col: (4, 4) GJ/L, (10, 4) -GJ/L
        .{ .idx = .{ 4, 4 }, .val = bd.G * bd.J / bd.L },
        .{ .idx = .{ 10, 4 }, .val = -bd.G * bd.J / bd.L },

        //   5th col: (3, 5) -6EIy/L^2, (5, 5) 4EIy/L, (9, 5) 6EIy/L^2, (11, 5) 2EIy/L
        .{ .idx = .{ 3, 5 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 5, 5 }, .val = 4 * bd.E * bd.Iy / bd.L },
        .{ .idx = .{ 9, 5 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 11, 5 }, .val = 2 * bd.E * bd.Iy / bd.L },

        //   6th col: (2, 6) 6EIz/L^2, (6, 6) 4EIz/L, (8, 6) -6EIz/L^2, (12, 6) 2EIz/L
        .{ .idx = .{ 2, 6 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 6, 6 }, .val = 4 * bd.E * bd.Iz / bd.L },
        .{ .idx = .{ 8, 6 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 12, 6 }, .val = 2 * bd.E * bd.Iz / bd.L },

        //   7th col: (1, 7) -EA/L, (7, 7) EA/L
        .{ .idx = .{ 1, 7 }, .val = -bd.E * bd.A / bd.L },
        .{ .idx = .{ 7, 7 }, .val = bd.E * bd.A / bd.L },

        //   8th col: (2, 8) -12EIz/L^3, (6, 8) -6EIz/L^2, (8, 8) 12EIz/L^3, (12, 8) -6EIz/L^2
        .{ .idx = .{ 2, 8 }, .val = -12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 6, 8 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 8, 8 }, .val = 12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 12, 8 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },

        //   9th col: (3, 9) -12EIy/L^3, (5, 9) 6EIy/L^2, (9, 9) 12EIy/L^3, (11, 9) 6EIy/L^2
        .{ .idx = .{ 3, 9 }, .val = -12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 5, 9 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 9, 9 }, .val = 12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 11, 9 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },

        //  10th col: (4, 10) -GJ/L, (10, 10) GJ/L
        .{ .idx = .{ 4, 10 }, .val = -bd.G * bd.J / bd.L },
        .{ .idx = .{ 10, 10 }, .val = bd.G * bd.J / bd.L },

        //  11th col: (3, 11) -6EIy/L^2, (5, 11) 2EIy/L, (9, 11) 6EIy/L^2, (11, 11) 4EIy/L
        .{ .idx = .{ 3, 11 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 5, 11 }, .val = 2 * bd.E * bd.Iy / bd.L },
        .{ .idx = .{ 9, 11 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 11, 11 }, .val = 4 * bd.E * bd.Iy / bd.L },

        //  12th col: (2, 12) 6EIz/L^2, (6, 12) 2EIz/L, (8, 12) -6EIz/L^2, (12, 12) 4EIz/L
        .{ .idx = .{ 2, 12 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 6, 12 }, .val = 2 * bd.E * bd.Iz / bd.L },
        .{ .idx = .{ 8, 12 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 12, 12 }, .val = 4 * bd.E * bd.Iz / bd.L },
    }) |entry| ek.set(entry.idx[0], entry.idx[1], entry.val);
}

/// Rotation matrix
///
/// x -> z
/// y -> y
/// z -> -x
///
const rot90xz = Mat3x3{
    .{ 0, 0, 1 },
    .{ 0, 1, 0 },
    .{ -1, 0, 0 },
};

pub fn rotate(eK: Matrix) void {
    for (utils.range(u2, 0, 4)) |r| for (utils.range(u2, 0, 4)) |s| {
        // Copy eK.sub(s, t) into sub3x3
        var sub3x3: Mat3x3 = eK.sub3x3(r, s);

        // Conjugate sub3x3 by rot
        var rot = rot90xz;
        sub3x3 = mat3d.multMM(rot, sub3x3);
        mat3d.transposeM(&rot);
        sub3x3 = mat3d.multMM(sub3x3, rot);

        // Copy sub3x3 back into eK.sub(s, t)
        eK.copySub3x3(r, s, sub3x3);
    };
}

pub fn accumLocalK(n0_idx: u32, n1_idx: u32, gK: Matrix, eK: Matrix) void {
    for ( // (n0, n0), (n0, n1), (n1, n0), (n1, n1)
        [4]u32{ 0, 0, 6, 6 },
        [4]u32{ 0, 6, 0, 6 },
    ) |is, js| for (utils.range(u32, 1, 7)) |i| for (utils.range(u32, 1, 7)) |j|
        gK.addTo(
            i + (6 - is) * n0_idx + is * n1_idx,
            j + (6 - js) * n0_idx + js * n1_idx,
            eK.get(i + is, j + js),
        );
}

const t = std.testing;

inline fn pair(i: comptime_int, j: comptime_int) u64 {
    comptime return (i << 32) | j;
}

test calcLocalK {
    const ta = t.allocator;

    const eK = try Matrix.init(ta, 12, 12);
    defer eK.deinit(ta);

    calcLocalK(BeamData{
        .E = 2.0,
        .G = 5.0,
        .A = 3.0,
        .Iy = 11.0,
        .Iz = 17.0,
        .J = 23.0,
        .L = 7.0,
    }, eK);

    for (1..12 + 1) |ui| for (1..12 + 1) |uj| {
        const i: u32 = @intCast(ui);
        const j: u32 = @intCast(uj);

        const value: f64 = switch ((@as(u64, i) << 32) | @as(u64, j)) {
            pair(1, 1) => 2.0 * 3.0 / 7.0,
            pair(7, 1) => -2.0 * 3.0 / 7.0,

            pair(2, 2) => 12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(6, 2) => 6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(8, 2) => -12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(12, 2) => 6.0 * 2.0 * 17.0 / (7.0 * 7.0),

            pair(3, 3) => 12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(5, 3) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(9, 3) => -12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(11, 3) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),

            pair(4, 4) => 5.0 * 23.0 / 7.0,
            pair(10, 4) => -5.0 * 23.0 / 7.0,

            pair(3, 5) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(5, 5) => 4.0 * 2.0 * 11.0 / 7.0,
            pair(9, 5) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(11, 5) => 2.0 * 2.0 * 11.0 / 7.0,

            pair(2, 6) => 6.0 * 2.0 * 17 / (7.0 * 7.0),
            pair(6, 6) => 4.0 * 2.0 * 17 / 7.0,
            pair(8, 6) => -6.0 * 2.0 * 17 / (7.0 * 7.0),
            pair(12, 6) => 2.0 * 2.0 * 17 / 7.0,

            pair(1, 7) => -2.0 * 3.0 / 7.0,
            pair(7, 7) => 2.0 * 3.0 / 7.0,

            pair(2, 8) => -12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(6, 8) => -6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(8, 8) => 12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(12, 8) => -6.0 * 2.0 * 17.0 / (7.0 * 7.0),

            pair(3, 9) => -12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(5, 9) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(9, 9) => 12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(11, 9) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),

            pair(4, 10) => -5.0 * 23.0 / 7.0,
            pair(10, 10) => 5.0 * 23.0 / 7.0,

            pair(3, 11) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(5, 11) => 2.0 * 2.0 * 11.0 / 7.0,
            pair(9, 11) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(11, 11) => 4.0 * 2.0 * 11.0 / 7.0,

            pair(2, 12) => 6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(6, 12) => 2.0 * 2.0 * 17.0 / 7.0,
            pair(8, 12) => -6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(12, 12) => 4.0 * 2.0 * 17.0 / 7.0,

            else => 0.0,
        };

        try t.expectEqual(value, eK.get(i, j));
    };
}

test rotate {
    const ta = t.allocator;

    const actual = try Matrix.init(ta, 12, 12);
    defer actual.deinit(ta);

    // Maxima
    //
    // m: genmatrix(lambda([i, j], (i-1)*12 + j), 12, 12);
    //
    for (utils.range(u8, 1, 13)) |i| for (utils.range(u8, 1, 13)) |j|
        actual.set(i, j, @floatFromInt((i - 1) * 12 + j));

    rotate(actual);

    const expected = try Matrix.init(ta, 12, 12);
    defer expected.deinit(ta);

    // Maxima
    //
    // rot3: matrix([0, 0, -1], [0, 1, 0], [1, 0, 0]);
    // rot: zeromatrix(12, 12);
    // for k:0 thru 3 do (
    //     for i:1 thru 3 do (
    //         for j:1 thru 3 do (
    //             rot[3*k + i, 3*k + j]: rot3[i, j]
    //         )
    //     )
    // );
    // expected: rot.m.transpose(rot);
    // genmatrix(lambda([i, j], expected[remainder(i-1, 12) + 1, quotient(i-1, 12) + 1]), 144, 1);
    //
    // zig fmt: off
    expected.setEntries(&[144]f64{
          27,  -15,   -3,   63,  -51,  -39,    99,  -87,  -75,   135,  -123,  -111,
         -26,   14,    2,  -62,   50,   38,   -98,   86,   74,  -134,   122,   110,
         -25,   13,    1,  -61,   49,   37,   -97,   85,   73,  -133,   121,   109,
          30,  -18,   -6,   66,  -54,  -42,   102,  -90,  -78,   138,  -126,  -114,
         -29,   17,    5,  -65,   53,   41,  -101,   89,   77,  -137,   125,   113,
         -28,   16,    4,  -64,   52,   40,  -100,   88,   76,  -136,   124,   112,
          33,  -21,   -9,   69,  -57,  -45,   105,  -93,  -81,   141,  -129,  -117,
         -32,   20,    8,  -68,   56,   44,  -104,   92,   80,  -140,   128,   116,
         -31,   19,    7,  -67,   55,   43,  -103,   91,   79,  -139,   127,   115,
          36,  -24,  -12,   72,  -60,  -48,   108,  -96,  -84,   144,  -132,  -120,
         -35,   23,   11,  -71,   59,   47,  -107,   95,   83,  -143,   131,   119,
         -34,   22,   10,  -70,   58,   46,  -106,   94,   82,  -142,   130,   118,
    });
    // zig fmt: on

    try t.expectEqualSlices(f64, expected.entries, actual.entries);
}

test accumLocalK {
    const ta = t.allocator;

    const gK = try Matrix.init(ta, 18, 18);
    defer gK.deinit(ta);

    const eK = try Matrix.init(ta, 12, 12);
    defer eK.deinit(ta);

    @memset(eK.entries, 2);
    accumLocalK(0, 1, gK, eK);

    @memset(eK.entries, 3);
    accumLocalK(1, 2, gK, eK);

    @memset(eK.entries, -1);
    accumLocalK(0, 2, gK, eK);

    try t.expectEqual(1, gK.get(1, 1));
    try t.expectEqual(5, gK.get(9, 9));
    try t.expectEqual(2, gK.get(18, 18));
    try t.expectEqual(-1, gK.get(1, 18));
    try t.expectEqual(-1, gK.get(18, 1));
}
