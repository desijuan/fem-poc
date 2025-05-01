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

    for (mesh.mat_props) |props| std.debug.print("{}", .{props});
    for (mesh.nodes) |node| std.debug.print("{}", .{node});
    for (mesh.beams) |beam| std.debug.print("{}", .{beam});
    for (mesh.bcs) |bc| std.debug.print("{}", .{bc});

    //
    // wip ...
    //
    const m_stiffness, const v_load, const v_sol = blk: {
        const n_nodes: u32 = @intCast(mesh.nodes.len);

        const K = try Matrix.init(gpa, n_nodes, n_nodes);
        errdefer K.deinit(gpa);
        const v = try Matrix.init(gpa, n_nodes, 1);
        errdefer v.deinit(gpa);
        const f = try Matrix.init(gpa, n_nodes, 1);
        errdefer f.deinit(gpa);

        break :blk [3]Matrix{ K, v, f };
    };
    defer for ([3]Matrix{ m_stiffness, v_load, v_sol }) |m| m.deinit(gpa);

    std.debug.print("{}", .{m_stiffness});
    std.debug.print("{}", .{v_load});
    std.debug.print("{}", .{v_sol});

    const m_ek, const v_ef = blk: {
        const n_eq: u32 = 12;

        const ek = try Matrix.init(gpa, n_eq, n_eq);
        errdefer ek.deinit(gpa);

        const ef = try Matrix.init(gpa, n_eq, 1);
        errdefer ef.deinit(gpa);

        break :blk [2]Matrix{ ek, ef };
    };
    defer for ([2]Matrix{ m_ek, v_ef }) |m| m.deinit(gpa);

    std.debug.print("{}", .{m_ek});
    std.debug.print("{}", .{v_ef});
}

comptime {
    _ = @import("utils.zig");
    _ = @import("Matrix.zig");
}
