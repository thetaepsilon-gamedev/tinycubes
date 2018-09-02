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
local on_place = function(itemstack, user, pointed)
	-- work out which face and which direction.
	-- do this by comparing the above and below, then scaling down.
	local diff = vector.subtract(pointed.above, pointed.under)
	local offset = vector.multiply(diff, tiny)
	--print("offset", dump(offset))
	-- add this to the surface pos to make sure positions round in the way we want.
	local bp = 4
	local target = vector.add(pointed.surface, offset)
	add_tiny_cube_raw(bp, target.x, target.y, target.z)
end

local item = mn..":tinycubetool"
minetest.register_craftitem(item, {
	inventory_image = "tinycubes_tinycubetool.png",
	on_place = on_use_surface_only(on_place),
})





-- register some extra items
dofile(mp.."extraitems.lua")

-- make sure internal table isn't exposed.
_mod = nil





-- export interface table
local path = "ds2.minetest.tinycubes"
modtable_register(path, i)

