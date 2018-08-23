-- texture querying implementation (see texture_mapping.lua):
-- due to MT not providing a way to query texture sizes,
-- we have to do some guesswork.
-- for now, assume that blocks are 16x16,
-- then load their tiles from minetest.registered_nodes.
-- material structure:
--[[
{
	node = "default:stone",		-- as you'd expect
	... -- some more properties planned here, like brick overlays.
}
]]
local i = {}



local defs = minetest.registered_nodes
local fail = function()
	-- might sneak in some debugging here later
	return nil, nil
end

local defaultsize = 16
local texq = function(material, index)
	local n = material.node
	if not n then return fail() end
	local def = defs[n]
	if not def then return fail() end
	-- hmm, can tiles be missing?
	-- I really could use the maybe monad in a do block rn
	local tiles = def.tiles
	if not tiles then return fail() end

	return tiles[index], defaultsize, defaultsize
end
i.texq = texq



return i

