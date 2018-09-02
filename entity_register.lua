--[[
Register the core entity used for tinycubes;
we currently don't have any better way to have many things in a block space,
so we have to mimic cube microbits using small cube-like entities.
]]

local mp = _mod.modpath
local entity = _mod.entity.name
-- needed other bits
-- save and restore
local m_deserial = dofile(mp.."deserialize.lua")
local lua_get_staticdata = m_deserial.lua_get_staticdata
local mk_on_deserialize = m_deserial.mk_on_deserialize

-- block material texture mapping
local m_texmap = dofile(mp.."texture_mapping.lua")
local create_textures = m_texmap.create_textures

local m_query = dofile(mp.."texture_query.lua")
local texq = m_query.texq





-- on_deserialize for little cubes:
-- currently just sets the size to the correct scale.
local sfp = _mod.util.sfp
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





-- now register the entity.
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

