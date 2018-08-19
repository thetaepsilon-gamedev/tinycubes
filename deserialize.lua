-- on_activate and staticdata helpers:
-- load lua properties from a serialised string.
-- we don't implement updating physical properties on config updates,
-- so instead, assuming the string was valid lua,
-- we simply store the serialised string for later saving via get_staticdata.
-- this means that it is simpler to spawn a new cube and remove the old one.
local i = {}

local lua_get_staticdata = function(self)
	return self.__serialised
end
i.lua_get_staticdata = lua_get_staticdata

local mk_on_deserialize = function(inner)
	return function(self, staticdata, dtime_s)
		local config = minetest.deserialize(staticdata)
		local keep = inner(self, config, dtime_s)
		if not keep then self.object:remove() end
		self.__serialised = staticdata
	end
end
i.mk_on_deserialize = mk_on_deserialize



return i

