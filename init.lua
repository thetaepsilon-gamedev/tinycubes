local mn = minetest.get_current_modname()
local entity = mn..":tinycube"
local sf = 16
local s = 1 / sf
local cf = 2 * sf
local c = 1 / cf

local prn = minetest.chat_send_all

-- the base cube entity.
-- it gets scaled down according to the size down below.
local bsz = {x=1,y=1}
local b = 0.5
local tb = "tinycubes_tinycube_"
local tx = tb.."x.png"
local ty = tb.."y.png"
local tz = tb.."z.png"
minetest.register_entity(entity, {
	hp_max = 1,
	visual="cube",
	visual_size=bsz,
	textures = {tx, tx, ty, ty, tz, tz},
	physical=true,
	collide_with_objects=true,
	on_rightclick = function(self, clicker)
		prn("clicky")
	end,
})





-- add extra data to a pointed thing in the case that it is a node;
-- namely, by adding the precise intersection position.
-- note: assumes type == node; see next function for guard
local on_use_surface = function(f)
	return function(itemstack, user, pointed)
		local spos = minetest.pointed_thing_to_face_pos(user, pointed)
		pointed.surface = spos
		return f(itemstack, user, pointed)
	end
end
-- another wrapper which only invokes the underlying function if a certain pointed type.
local on_use_only = function(type, f)
	return function(itemstack, user, pointed)
		if pointed.type == type then
			return f(itemstack, user, pointed)
		end
	end
end



-- placement logic
-- to place a tiny cube, we align it to the small grid they exist in.
-- scale power is the power of two of the grid size;
-- 1 is 1/2, 2 is 1/(2^2) = 1/4, 3 is 1/8 etc.
local sfp = function(p) return math.pow(2, p) end
local align = function(v, sp)
	local sf = sfp(sp)
	local c = 1 / (2 * sf)
	local r = (math.floor(v * sf) / sf) + c
	print("v", v, "r", r)
	return r
end
local align_tiny_pos_mut = function(pos, sp)
	pos.x = align(pos.x, sp)
	pos.y = align(pos.y, sp)
	pos.z = align(pos.z, sp)
	return pos
end

-- adds a tiny entity at a position (mutates pos!)
local add_tiny_cube_mut = function(pos, sp)
	local aligned = align_tiny_pos_mut(pos, sp)
	local ent = minetest.add_entity(aligned, entity)
	local sf = sfp(sp)
	local sfd = 1 / sf
	local cfd = 1 / (sf * 2)
	ent:set_properties({
		visual_size={x=sfd,y=sfd},
		collisionbox={-cfd,-cfd,-cfd,cfd,cfd,cfd}
	})
	return ent
end



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
	add_tiny_cube_mut(target, bp)
end

local item = mn..":tinycubetool"
minetest.register_craftitem(item, {
	inventory_image = t,
	on_place = on_use_only("node", on_use_surface(on_place)),
})


