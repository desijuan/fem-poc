const Vec3 = @import("../mat3d.zig").Vec3;

node_idx: u32,
type: BCType,

const BCType = union(enum) {
    Support: void,
    Force: Vec3,
};

pub const format = @import("../utils.zig").structFormatFn(@This());
