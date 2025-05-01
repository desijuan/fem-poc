const std = @import("std");
const utils = @import("utils.zig");
const WoodPole = @import("WoodPole.zig");
const Matrix = @import("Matrix.zig");
const Mesh = @import("mesh/Mesh.zig");

pub fn main() !void {
    var gpa_instance = std.heap.DebugAllocator(.{ .safety = true }){};
    defer _ = gpa_instance.deinit();

    const gpa = gpa_instance.allocator();

    const pole = WoodPole{
        .height = 1.036e1,
        .bottom_diameter = 2.911e-1,
        .top_diameter = 1.86e-1,
        .fiber_strength = 5.52e7,
        .modulus_of_elasticity = 1.468e10,
        .shear_modulus = 1e9,
        .density = 5.4463e2,
    };

    std.debug.print("{}", .{pole});

    const mesh: Mesh = try pole.buildMesh(gpa);
    defer mesh.deinit(gpa);

    //
    // wip ...
    //
    const m_K, const v_f, const v_v = blk: {
        const n_nodes: u32 = @intCast(mesh.nodes.len * 6);

        const K = try Matrix.init(gpa, n_nodes, n_nodes);
        errdefer K.deinit(gpa);
        const v = try Matrix.init(gpa, n_nodes, 1);
        errdefer v.deinit(gpa);
        const f = try Matrix.init(gpa, n_nodes, 1);
        errdefer f.deinit(gpa);

        break :blk [3]Matrix{ K, v, f };
    };
    defer for ([3]Matrix{ m_K, v_f, v_v }) |m| m.deinit(gpa);

    const m_ek, const v_ef = blk: {
        const n_eq: u32 = 12;

        const ek = try Matrix.init(gpa, n_eq, n_eq);
        errdefer ek.deinit(gpa);

        const ef = try Matrix.init(gpa, n_eq, 1);
        errdefer ef.deinit(gpa);

        break :blk [2]Matrix{ ek, ef };
    };
    defer for ([2]Matrix{ m_ek, v_ef }) |m| m.deinit(gpa);

    {
        var eq_idxs: [12]u32 = undefined;
        @memset(&eq_idxs, 0);

        for (0..mesh.beams.len) |idx| {
            defer {
                for ([_]Matrix{ m_ek, v_ef }) |m| m.reset();
                @memset(&eq_idxs, 0);
            }

            const beam_idx: u32 = @intCast(idx);

            try mesh.calcLocalKforBeam(beam_idx, m_ek, v_ef);

            std.debug.print("m_ek:\n{}", .{m_ek});

            mesh.getEquationIndicesForBeam(beam_idx, &eq_idxs);

            std.debug.print("eq_idxs: {any}\n", .{eq_idxs});

            for (1..7) |i| {
                const ieq: u32 = eq_idxs[i - 1];
                for (1..7) |j| {
                    const jeq: u32 = eq_idxs[j - 1];
                    try m_K.addTo(ieq, jeq, try m_ek.get(i, j));
                }
            }
        }
    }

    std.debug.print("m_K:\n{}", .{m_K});
}

comptime {
    _ = @import("utils.zig");
    _ = @import("Matrix.zig");
}
