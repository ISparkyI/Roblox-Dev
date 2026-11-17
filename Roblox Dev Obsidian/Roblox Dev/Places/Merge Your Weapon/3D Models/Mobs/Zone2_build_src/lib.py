import bpy, bmesh, math
from mathutils import Vector, Euler, Matrix

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

MATS = {}
def mat(name, hexcol, emit=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new("MYW_" + name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    h = hexcol.lstrip('#')
    srgb = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    b.inputs["Base Color"].default_value = (*lin, 1)
    b.inputs["Roughness"].default_value = 1.0
    if emit > 0:
        b.inputs["Emission Color"].default_value = (*lin, 1)
        b.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = (*lin, 1)
    MATS[name] = m
    return m

class Obj:
    """collects boxes (and simple prisms) into one mesh object with per-face materials"""
    def __init__(self, name, bevel=0.03):
        self.name = name; self.bm = bmesh.new(); self.mats = []; self.bevel = bevel
    def _mi(self, m):
        if m not in self.mats: self.mats.append(m)
        return self.mats.index(m)
    def box(self, m, c, s, rot=(0, 0, 0), taper=None):
        """m material, c centre (x,y,z), s size; rot degrees (x,y,z); taper = (sx_top, sy_top) scale of the +Z face"""
        mi = self._mi(m)
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        vs = res['verts']
        for v in vs:
            x, y, z = v.co
            if taper and z > 0: x *= taper[0]; y *= taper[1]
            v.co = Vector((x * s[0], y * s[1], z * s[2]))
        R = Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix()
        for v in vs: v.co = R @ v.co + Vector(c)
        faces = {f for v in vs for f in v.link_faces}
        for f in faces: f.material_index = mi
        return self
    def cyl(self, m, c, r, h, axis='Z', seg=8, rot=(0, 0, 0)):
        mi = self._mi(m)
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=h)
        vs = res['verts']
        A = {'Z': Matrix.Identity(3), 'X': Euler((0, math.radians(90), 0)).to_matrix(), 'Y': Euler((math.radians(90), 0, 0)).to_matrix()}[axis]
        R = Euler(tuple(math.radians(a) for a in rot), 'XYZ').to_matrix() @ A
        for v in vs: v.co = R @ v.co + Vector(c)
        for f in {f for v in vs for f in v.link_faces}: f.material_index = mi
        return self
    def build(self, coll=None):
        me = bpy.data.meshes.new(self.name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=0.0005)
        self.bm.to_mesh(me); self.bm.free()
        for m in self.mats: me.materials.append(m)
        o = bpy.data.objects.new(self.name, me)
        (coll or bpy.context.scene.collection).objects.link(o)
        if self.bevel:
            bv = o.modifiers.new("Bevel", 'BEVEL'); bv.width = self.bevel; bv.segments = 1; bv.limit_method = 'ANGLE'
        return o

def scale_all(k):
    for o in bpy.data.objects:
        if o.type == 'MESH':
            for v in o.data.vertices: v.co *= k
            for md in o.modifiers:
                if md.type == 'BEVEL': md.width *= k

def mirror_x():
    """Roblox turns imported glTF 180 deg around Y: mirror X so the Blender 'RightArm' ends up as the character's RIGHT arm"""
    import bmesh as _bm
    for o in bpy.data.objects:
        if o.type != 'MESH': continue
        b = _bm.new(); b.from_mesh(o.data)
        for v in b.verts: v.co.x = -v.co.x
        _bm.ops.reverse_faces(b, faces=b.faces)
        b.to_mesh(o.data); b.free()

def export(path):
    mirror_x()
    bpy.ops.object.select_all(action='DESELECT')
    for o in bpy.data.objects: o.select_set(o.type == 'MESH')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

def render_preview(path, center=(0, 0, 3.2), dist=13, res=(1400, 1000)):
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_WORKBENCH'
    scn.display.shading.light = 'STUDIO'; scn.display.shading.color_type = 'MATERIAL'
    scn.display.shading.show_shadows = True; scn.display.shading.show_cavity = True
    scn.render.resolution_x, scn.render.resolution_y = res
    scn.world = bpy.data.worlds.new("w") if not scn.world else scn.world
    scn.world.color = (0.18, 0.18, 0.2)
    cam = bpy.data.cameras.new("cam"); cam.lens = 50
    co = bpy.data.objects.new("cam", cam); scn.collection.objects.link(co); scn.camera = co
    import mathutils
    shots = [(-30, 'a'), (0, 'f'), (155, 'b')]
    files = []
    for yaw, tag in shots:
        a = math.radians(yaw)
        eye = Vector(center) + Vector((math.sin(a) * dist * -1, -math.cos(a) * dist, 2.2))
        co.location = eye
        d = Vector(center) - eye
        co.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        f = path.replace('.png', f'_{tag}.png'); scn.render.filepath = f
        bpy.ops.render.render(write_still=True); files.append(f)
    bpy.data.objects.remove(co)
    return files
