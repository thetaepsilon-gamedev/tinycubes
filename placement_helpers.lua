-- various helper bits for on_place callbacks.
local i = {}



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
i.on_use_surface = on_use_surface



-- another wrapper which only invokes the underlying function if a certain pointed type.
local on_use_only = function(type, f)
	return function(itemstack, user, pointed)
		if pointed.type == type then
			return f(itemstack, user, pointed)
		end
	end
end
i.on_use_only = on_use_only



-- combine the two to only use for placing on a surface.
local on_use_surface_only = function(f)
	return on_use_only("node", on_use_surface(f))
end
i.on_use_surface_only = on_use_surface_only



return i

