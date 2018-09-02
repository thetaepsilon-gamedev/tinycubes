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





-- the proxy factory for the entity.
-- this object (see libmthelpers: datastructs/proxy.lua)
-- only allows certain methods on the base object to be called.
local acl = {
	get_cpos = function(self)
		return self.object:get_pos()
	end,
	get_scale = function(self)
		return self.config.scale
	end
}
local lib = "com.github.thetaepsilon.minetest.libmthelpers"
local m_proxy = mtrequire(lib..".datastructs.proxy")
local interface_prefix = "interface_"
local mk_proxy = m_proxy.proxy_factory_(acl, interface_prefix)




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

	-- create the proxy object for later use.
	self.proxy = mk_proxy(self)

	self.config = config
	return true
end





-- create the right-click handler registry for this entity.
local mkreg = mtrequire("ds2.minetest.tinycubes.item_handler_registry")
local deps = {
	itemdef = {
		deftable = minetest.registered_items,
		entity_api_name = _mod.entity.apiname,
	}
}
local find_handler, register = mkreg(deps)



-- then, define the right-click handler:
-- if any item-specific handler is found, call that,
-- and expect it to know about the itemstack logic.
-- if no handler, return nil so that the wielded itemstack is preserved.
local prn = minetest.chat_send_all
local on_rightclick_item = function(self, clicker, itemstack)
	local handler = find_handler(itemstack)
	-- TODO: the API is not yet defined,
	-- so just yell some debug text for now
	if handler then
		handler(self.proxy, clicker, itemstack)
	else
		-- no handler? do nothing, preserve itemstack
		return nil
	end
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

