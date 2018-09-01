local i = mtrequire("ds2.minetest.tinycubes.item_handler_registry")

local mkfake = function(itemstr)
	return {
		get_name = function(self) return itemstr end,
	}
end
local fakeitem = mkfake("default:stone")



local lookup = i.find_handler
local reject = function(item)
	local handler, info = lookup(item)
	assert(handler == nil)
	assert(info == nil)
end
local acceptf = function(item, h1)
	local handler, info = lookup(item)
	assert(info ~= nil, "info nil!?")
	assert(handler == h1, "handler didn't match expected")
end

-- initially the regtable is empty, so this should fail.
reject(fakeitem)



-- register some handler for the entire mod "default"
local dummyf = function() return function() end end
local f1 = dummyf()
i.register.wholemod("default", f1)
-- now we expect it to return that handler.
acceptf(fakeitem, f1)

-- an unrelated item should still be rejected.
local unrelated = mkfake("randommod:item")
reject(unrelated)



-- if we now add a mod for the exact item, we expect that to take precendence.
local f2 = dummyf()
-- before...
acceptf(fakeitem, f1)
-- then...
i.register.exact("default:stone", f2)
-- and after
acceptf(fakeitem, f2)

-- unrelated item remains unrelated
reject(unrelated)
-- however, something else in default should fall back to the whole mod handler.
local anotherdefault = mkfake("default:cobble")
acceptf(anotherdefault, f1)





