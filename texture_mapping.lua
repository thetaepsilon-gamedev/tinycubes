--[[
The cube entities internally store references to which material (node),
and which face, they take textures from,
as well as the coordinates (UV style, [0..1]) of the region of that texture.
This allows them to look like a fragment of that node's surface.

However, some textures are a higher resolution that others,
and may even change between runs
(e.g. if higher resolution textures are configured).
Further complicating matters is the fact that
MT doesn't let us dynamically set UV sample coordinates into a texture at runtime
(despite the GPU probably being more than capable of this...).
Instead, for entities we can only specify textures using MT's texture modifiers,
and these do not allow us to use UV coordinates.
The closest modifiers we have are only specified in exact pixels.
This leads to a problem where a UV coordinate may be halfway into a pixel,
so we need to do *something* to such cases or the modifier won't work.

Here, we map these UV coordinates back to pixel coordinates.
The lower bounds are rounded down, and the upper bounds rounded up.
This has the property that e.g. 1/16th cubes sampling an 8x8 texture
will Do The Right Thing™ visually, where two 1/16th cubes next to each other
(the first having e.g. U=0..1/16 and the second having U=1/16..2/16)
will both visually take on the first pixel in the texture.
Non-power-of-two sized textures may not fare so well here,
however this mod isn't really intended for such odd textures to begin with.
]]



local i = {}

--[[
@INTERFACE texture_query
First, a concept to introduce:
For a given node/material and tile face (0-5, see node def tiles={...}),
we need a function which will return a) the texture string,
and b) the dimensions of this texture.
MT doesn't have a way to query (b), so we have to have it stored elsewhere.

query :: node_material -> Int -> Maybe (String, Int, Int)
-- Maybe here means it may return nil's if the lookup fails; e.g. material missing.
-- otherwise returns three values: base texture, width, height, in that order.
-- node_material doesn't have to be a string; it is an opaque type,
--   and can be anything that describes a node material (e.g. brick overlay modifier?).
]]



-- so then we move onto the pixel mapping
-- texq :: interface texture_query
-- returns :: Maybe (texturespec, x, y, w, h)
local floor = math.floor
local ceil = math.ceil
local map_to_pixels = function(texq, node, u1, v1, u2, v2)
	local texture, width, height = texq(node)
	-- if texture query returns nil, we return nil also.
	-- this allows create_uv_texture_spec() below
	-- to use a placeholder error texture.
	if texture == nil then
		return nil, nil, nil, nil, nil
	end

	-- scale the coordinates into a number of pixels,
	-- then round up or down as appropriate
	-- to obtain an integer number of pixels.
	local x1 = floor(u1 * width)
	local x2 = ceil(u2 * width)
	local y1 = floor(v1 * height)
	local y2 = ceil(v2 * height)

	-- work out the width/height of this region
	local w = x2 - x1
	local h = y2 - y1

	return texture, x1, y1, w, h
end

-- then, create the appropriate texture modifier.
-- same arguments as above, but just returns a texture spec string.
local assert_int = function(v, label)
	assert(((v % 1.0) == 0), label.." was not an integer!")
	return v
end

-- this texture intentionally doesn't exist
local missingtex = nil
-- returns :: TextureSpec String
local create_uv_texture_spec = function(...)
	local texture, x, y, w, h = map_to_pixels(...)
	-- if the querying phase failed and caused mapping to return nil,
	-- we return a string which will produce the "unknown node" texture,
	-- so players/admins will at least know something is up.
	if texture == nil then return missingtex end

	-- we use the [combine modifier for this.
	-- this is a little backwards because it works relative to target coordinates;
	-- so to take an offset into a texture
	-- we have to place it at negative coordinates relative to the "window".

	-- ensure integer coordinates, modifier probably won't work else
	local dim = assert_int(w, "w").."x"..assert_int(h, "h")
	local file = "("..texture..")"
	local coordinates = assert_int(-x, "x")..","..assert_int(-y, "y")
	local spec = "([combine:"..dim..":"..coordinates.."="..file..")"
	return spec
end
i.create_uv_texture_spec = create_uv_texture_spec





-- ## loading texture specs from saved entity data

local transparent = "tinycubes_nodraw.png"
-- next up, load the texture properties for an entire set of faces.
-- if any of them are missing, a transparent texture is used.
--[[
-- format of the property table:
{
	-- n is the index into the texture list for a cube drawtype
	[n] = {
		-- this structure: data TextureProps

		material = { ... },
		-- UV coordinates
		u1 = 0,
		v1 = 0,
		u2 = 0.5,
		v2 = 0.5,
	}
}
]]

-- interface texture_query -> Int -> TextureProps -> TextureSpec
local create_spec_from_properties = function(texq, properties)
	-- properties don't exist? use transparency
	if properties == nil then return transparent end

	local p = properties
	return create_uv_texture_spec(texq, p.material, p.u1, p.v1, p.u2, p.v2)
end
-- now for all faces
-- interface texture_query -> Array 6 (Maybe TextureProps) -> Array 6 (TextureSpec)
-- faceprops would likely be provided from an entity's saved configuration.
-- additionally, applies a ^[multiply tint to the returned textures,
-- so that it mimics the slight face differences for blocks in the game;
-- without it tiny cubes end up looking somewhat unnatural and out of place.

-- tints for faces
local tp = "^[multiply:"
local tx = tp.."#D8D8D8"
local ty = ""	-- upper Y faces are the baseline
local tym = tp.."#A7A7A7"	-- lower Y face is the darkest
local tz = tp.."#EEEEEE"
-- per-face tints, organised according to face order for cube drawtype
local tints = { ty, tym, tx, tx, tz, tz }

local create_textures = function(texq, faceprops)
	-- curse you, starts-at-one-arraaaayyyyyssssssss
	local specs = {}
	for i = 1, 6, 1 do
		-- maybe nil, but this is handled by create_spec_from_properties
		local props = faceprops[i]
		local spec = create_spec_from_properties(texq, props)
		local tint = tints[i]
		spec = spec .. tint
		specs[i] = spec
	end
	return specs
end
i.create_textures = create_textures



return i
