-- internal access table for other components
_mod = {}

local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")

local mn = minetest.get_current_modname()
local mp = minetest.get_modpath(mn).."/"
local entity = mn..":tinycube"

local prn = minetest.chat_send_all
local i = {}

local m_deserial = dofile(mp.."deserialize.lua")
local lua_get_staticdata = m_deserial.lua_get_staticdata
local mk_on_deserialize = m_deserial.mk_on_deserialize

local m_texmap = dofile(mp.."texture_mapping.lua")
local create_textures = m_texmap.create_textures

local m_query = dofile(mp.."texture_query.lua")
local texq = m_query.texq



-- on_deserialize for little cubes:
-- currently just sets the size to the correct scale.
local sfp = function(p) return math.pow(2, p) end
local scale_max = 4
local cube_on_deserialize = function(self, config, dtime_s)
	local scale = config.scale
	-- sanity limits on scale power
	if not scale or scale < 0 or scale > scale_max then
		return false
	end

	-- load specified surface textures, if any exist
	local textures
	if config.surfaces then
		textures = create_textures(texq, config.surfaces)
	end

	-- adjust static properties to match size
	local ent = self.object
	-- side length out from center of cube is half of cube fraction
	local s = 1 / sfp(scale)
	local c = 1 / sfp(scale + 1)
	ent:set_properties({
		collisionbox={-c,-c,-c,c,c,c},
		visual_size={x=s,y=s},
		textures=textures,
	})

	self.config = config
	return true
end



-- placeholder testing rightclick handler...
local blank = ItemStack("")
local on_rightclick_item = function(self, clicker, itemstack)
	local ref = minetest.add_item(self.object:get_pos(), itemstack)
	if ref then return blank end
end
local mkadapter = dofile(mp.."entity_rightclick_itemstack_adapter.lua")
local on_rightclick = mkadapter(on_rightclick_item)



-- the base cube entity.
-- it gets scaled down according to the size down below.
local bsz = {x=1,y=1}
local b = 0.5
local tb = "tinycubes_tinycube_"
local tx = tb.."x.png"
local ty = tb.."y.png"
local tym = tb.."ym.png"
local tz = tb.."z.png"
minetest.register_entity(entity, {
	hp_max = 1,
	visual="cube",
	visual_size=bsz,
	textures = {ty, tym, tx, tx, tz, tz},
	physical=true,
	collide_with_objects=true,
	get_staticdata = lua_get_staticdata,
	on_activate = mk_on_deserialize(cube_on_deserialize),
	on_rightclick = on_rightclick,
})




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

-- make sure internal table isn't exposed.
_mod = nil



-- export interface table
local path = "ds2.minetest.tinycubes"
modtable_register(path, i)

