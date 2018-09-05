-- internal access table for other components
_mod = {}

local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")

local mn = minetest.get_current_modname()
_mod.modname = mn
local mp = minetest.get_modpath(mn).."/"
_mod.modpath = mp
local entity = mn..":tinycube"
_mod.entity = {}
_mod.entity.name = entity
_mod.entity.apiname = "ds2.minetest.tinycubes.cube"

local prn = minetest.chat_send_all
local i = {}

-- small util function - 2 ^ p.
-- used for alignment and size calculations.
local sfp = function(p) return math.pow(2, p) end
_mod.util = {}
_mod.util.sfp = sfp

-- firstly register the tiny cube entity itself
dofile(mp.."entity_register.lua")





local m_place = dofile(mp.."placement_helpers.lua")
local on_use_surface_only = m_place.on_use_surface_only

-- placement logic
-- to place a tiny cube, we align it to the small grid they exist in.
-- scale power is the power of two of the grid size;
-- 1 is 1/2, 2 is 1/(2^2) = 1/4, 3 is 1/8 etc.
local align = function(v, sp)
	local sf = sfp(sp)
	local c = 1 / (2 * sf)
	local r = (math.floor(v * sf) / sf) + c
	return r
end

-- align a position to a cube (returns bare x, y, z vars)
local align_tiny_pos_raw = function(sp, x, y, z)
	local ax = align(x, sp)
	local ay = align(y, sp)
	local az = align(z, sp)
	return ax, ay, az
end

-- adds a tiny entity at a position (takes bare xyz variables)
-- if noalign is true, the entity is allowed to be off-grid.
local s = {}
local tpos = {}
local add_tiny_cube_raw = function(sp, x, y, z, noalign)
	if not noalign then
		x, y, z = align_tiny_pos_raw(sp, x, y, z)
	end
	s.scale = sp
	local data = minetest.serialize(s)
	tpos.x, tpos.y, tpos.z = x, y, z
	local ent = minetest.add_entity(tpos, entity, data)
	return ent
end
i.add_tiny_cube_raw = add_tiny_cube_raw

-- wrapped version of the above for convenience,
-- when passed a pos table from something in the MT API
local add_tiny_cube = function(sp, pos, noalign)
	local x, y, z = unwrap(pos)
	return add_tiny_cube_raw(sp, x, y, z, noalign)
end
i.add_tiny_cube = add_tiny_cube



-- on_place logic:
-- assumes a node pointed thing with surface pos.
-- places a tiny cube "above" the pointed face.
local tiny = 0.00001
local bp = 4	-- TODO: pull this from the itemstack's metadata?
local place_cube_from_surface_dir = function(surface, direction, sp)
	local offset = vector.multiply(direction, tiny)
	--print("offset", dump(offset))
	-- add this to the surface pos to make sure positions round in the way we want.
	-- this prevents rounding direction ambiguities due to
	-- the surface pos being on a .5 boundary between nodes.
	local target = vector.add(surface, offset)
	-- then let the above routine handle alignment.
	return add_tiny_cube_raw(sp, target.x, target.y, target.z)
end
local on_place = function(itemstack, user, pointed)
	-- work out which face and which direction.
	-- do this by comparing the above and below, then scaling down.
	local direction = vector.subtract(pointed.above, pointed.under)

	-- NB: do NOT do "return" here, as on_place() must return an itemstack!
	-- (whereas the the following returns an entity ref)
	place_cube_from_surface_dir(pointed.surface, direction, bp)
end



-- to use the same technique to place against existing entities,
-- we need to be a bit more clever here - can't use pointed_thing_to_face_pos().
-- thankfully vectorextra's cube intersection does the heavy lifting for us;
-- all we have to do is get the head height.
local apiname = _mod.entity.apiname
local m_camera = modtable("ds2.minetest.misc_game_routines.get_camera_pos")
local get_base_and_eye_pos = m_camera.get_base_and_eye_pos
local m_solve = mtrequire("ds2.minetest.vectorextras.cube_intersect_solve")
local solve_ws_raw = m_solve.solve_ws_raw
local face_offsets = m_solve.enum_offsets

local s = {}
local stack_cube = function(api, clicker, itemstack)
	if not clicker:is_player() then return nil end
	-- variables needed for solving -
	-- camera pos, look dir, entity pos, cube widths
	local e = api("get_cpos")
	local _, c = get_base_and_eye_pos(clicker)
	local l = clicker:get_look_dir()
	-- TODO: cuboids like slabs? just assume scale for now
	local scale = api("get_scale")
	local w = 1 / sfp(scale)

	-- wow many variable such line length
	local fx, fy, fz, es, ef =
		solve_ws_raw(c.x, c.y, c.z, l.x, l.y, l.z, e.x, e.y, e.z, w, w, w)

	-- shouldn't happen really...
	if fx == nil then
		prn("NOPE")
		return
	end
	local face = es..ef
	local dir = face_offsets[face]
	s.x, s.y, s.z = fx, fy, fz
	place_cube_from_surface_dir(s, dir, bp)
end

local item = mn..":tinycubetool"
minetest.register_craftitem(item, {
	inventory_image = "tinycubes_tinycubetool.png",
	on_place = on_use_surface_only(on_place),
	on_entity_rightclick = {
		[apiname] = stack_cube,
	}
})





-- register some extra items
dofile(mp.."extraitems.lua")

-- make sure internal table isn't exposed.
_mod = nil





-- export interface table
local path = "ds2.minetest.tinycubes"
modtable_register(path, i)

