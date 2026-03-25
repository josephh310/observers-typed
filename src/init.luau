--!strict
local observeTag = require(script.observeTag)

--[=[
	@class Observers

	A collection of observer utility functions.
]=]

observeTag("Tag", function() end)

return {
	observeTag = require(script.observeTag),
	observeAttribute = require(script.observeAttribute),
	observeProperty = require(script.observeProperty),
	observePlayer = require(script.observePlayer),
	observeCharacter = require(script.observeCharacter),
	observeLocalCharacter = require(script.observeLocalCharacter),
}
