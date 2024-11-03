const std = @import("std");

pub const desired_element_size = 0.5;
pub const gravity = Vect3{ .x = 0, .y = 0, .z = -9.8 };

material_properties: []MaterialProperties,
nodes: []Vect3,
beams: []Beam,
bcs: []BeamBC,

const Self = @This();

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.material_properties);
    allocator.free(self.nodes);
    allocator.free(self.beams);
    allocator.free(self.bcs);
}

pub const MaterialProperties = struct {
    elasticity_modulus: f64, // fE [N/m^2]
    shear_modulus: f64, // fG [N/m^2]
    density: f64, // fRho [kg/m^3]
};

pub const Vect3 = struct {
    x: f64,
    y: f64,
    z: f64,
};

pub const Beam = struct {
    material_props_index: u32,
    n0_index: u32,
    n1_index: u32,
    cross_area: f64, // fA
    moment_x: f64, // fIz
    moment_y: f64, // fIy
    fJp: f64, // ?
    fIp: f64, // ?
};

pub const BeamBC = struct {
    node_index: u32,
    beam_index: u32,
    type0: BCType,
    type1: BCType,
    type2: BCType,
    type3: BCType,
    type4: BCType,
    type5: BCType,
    value0: f64,
    value1: f64,
    value2: f64,
    value3: f64,
    value4: f64,
    value5: f64,
};

const BCType = enum {
    None,
    Force,
    Support,
    StringSupport,
};
