--[[
Looking up a handler for tiny cubes (or perhaps any case of item handlers).
We want to be able to support:
-- exact item matches, "mymod:someitem"
-- mod name matches, one handler that could be called for all "mymod:" items

In any case, to support this and future cases,
lookup for a given item string is as follows:
+ The item gets turned into a table with some info extracted.
	Currently this consists of the split mod and item name,
	as well as the original item string for table matching convenience.
	This extraction process may fail if the item string was anomalous;
	e.g. if the expected colon was missing between mod and item.

+ A list of query functions are tried in order, to see if any return a handler;
	first to return a handler wins, operation fails if no handler found.
	The query function is passed the extracted table from the previous step.
	Currently the only two such functions are, in precedence order:
	+ One which checks for a handler for an exact item string
		(e.g. checks info.itemstring).
	+ One which checks for a handler for just the mod prefix.
]]
local i = {}

local require = mtrequire
local pre = "com.github.thetaepsilon.minetest.libmthelpers."





local m_split = require(pre.."strutil")
-- split on the colon syntax used in item strings;
local split = m_split.split_once_(":", 1, true)

local extractor = function(itemstack)
	local itemstring = itemstack:get_name()
	local before, match, after = split(itemstring)
	-- no colon in there? what a strange itemstring...
	if match == nil then return nil end

	--print("extract ok")
	return {
		itemstring = itemstring,
		modname = before,
		moditem = after,
	}
end





-- look up a handler from an array-like table of functions, and given extractor.
-- if a handler is found, then both it and the extracted item info are returned;
-- otherrwise, nils are returned.
-- type ItemQuery i = (i -> Maybe ItemHandler)
-- type ItemExtractor i = (ItemStack -> Maybe i)
-- find_handler_inner :: Array (ItemQuery i) -> \
--	ItemExtractor i -> ItemStack -> Maybe (ItemHandler, i)
local find_handler_inner = function(querylist, extractor, item)
	local iteminfo = extractor(item)
	if iteminfo == nil then return nil, nil end
	--print("got iteminfo")

	for i, queryf in ipairs(querylist) do
		--print("queryf "..i)
		local found = queryf(iteminfo)
		--print("found value, queryf "..i..": "..tostring(found))
		if found then return found, iteminfo end
	end

	--print("no handler found")
	return nil, nil
end





-- registry tables for the mod-based and exact itemstring matches.
local hooks = {
	checkkey = function(k)
		local ok = (type(k) == "string")
		return ok, "item key required to be a string"
	end,
	validator = function(v)
		local ok = (type(v) == "function")
		return ok, "item handler required to be a function"
	end,
}





-- set up query functions list for handler lookup
local mkreg = mtrequire(pre.."datastructs.regtable").construct
local regtable_mod = mkreg(hooks)
local regtable_exact = mkreg(hooks)
local reg = {}
reg.exact = regtable_exact.register
reg.wholemod = regtable_mod.register
i.register = reg

local gete = regtable_exact.get
local getm = regtable_mod.get
local getexact = function(iteminfo)
	return gete(iteminfo.itemstring)
end
local getmod = function(iteminfo)
	return getm(iteminfo.modname)
end
local querylist = {
	getexact,
	getmod,
}





-- finally plug the pieces together
local find_handler = function(itemstack)
	return find_handler_inner(querylist, extractor, itemstack)
end
i.find_handler = find_handler



return i

