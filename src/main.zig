const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils.zig");
const macros = @import("macros.zig");
const WoodPole = @import("WoodPole.zig");
const Matrix = @import("Matrix.zig");
const Mesh = @import("mesh/Mesh.zig");

const DPRINT = macros.DPRINT;

const Gpa = @import("allocator.zig").Gpa(builtin.mode);

pub fn main() !void {
    defer if (comptime @hasDecl(Gpa, "deinit"))
        std.debug.print("da_deinit: {}\n", .{Gpa.deinit()});

    const gpa = Gpa.allocator();

    const pole = WoodPole{
        .height = 1.036e1,
        .bottom_diameter = 2.911e-1,
        .top_diameter = 1.86e-1,
        .fiber_strength = 5.52e7,
        .modulus_of_elasticity = 1.468e10,
        .shear_modulus = 1e9,
        .density = 5.4463e2,
    };

    DPRINT("{}", .{pole});

    const mesh: Mesh = try pole.buildMesh(gpa);
    defer mesh.deinit(gpa);

    DPRINT("{}", .{mesh.mat_props[0]});
    DPRINT("{}", .{mesh.beams[0]});

    const m_K, const v_f, const v_v = blk: {
        const n_eqs: u32 = @intCast(mesh.nodes.len * 6);

        const K = try Matrix.init(gpa, n_eqs, n_eqs);
        errdefer K.deinit(gpa);
        const v = try Matrix.init(gpa, n_eqs, 1);
        errdefer v.deinit(gpa);
        const f = try Matrix.init(gpa, n_eqs, 1);
        errdefer f.deinit(gpa);

        break :blk [3]Matrix{ K, v, f };
    };
    defer for ([3]Matrix{ m_K, v_f, v_v }) |m| m.deinit(gpa);

    const m_ek, const v_ef = blk: {
        const n_dofs: u32 = Mesh.DOFS;

        const ek = try Matrix.init(gpa, n_dofs, n_dofs);
        errdefer ek.deinit(gpa);

        const ef = try Matrix.init(gpa, n_dofs, 1);
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

            DPRINT("beam_idx: {}\n", .{beam_idx});

            mesh.calcLocalKforBeam(beam_idx, m_ek, v_ef);

            DPRINT("m_ek:\n{}", .{m_ek});

            //
            // TODO: Accumular (m_ek, v_ef) en (m_K, v_f).
            //
            // TODO: Revisar lo que sigue.
            //

            mesh.getEquationIndicesForBeam(beam_idx, &eq_idxs);

            DPRINT("eq_idxs: {any}\n", .{eq_idxs});

            for (1..7) |i| {
                const ieq: u32 = eq_idxs[i - 1];
                for (1..7) |j| {
                    const jeq: u32 = eq_idxs[j - 1];
                    m_K.addTo(ieq, jeq, m_ek.get(@intCast(i), @intCast(j)));
                }
            }
        }
    }

    // std.debug.print("m_K:\n{}", .{m_K});
}

comptime {
    _ = @import("utils.zig");
    _ = @import("Matrix.zig");
    _ = @import("mesh/Beam.zig");
}
