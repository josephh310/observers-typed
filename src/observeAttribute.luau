--!strict
local function defaultGuard(_value: any)
	return true
end

--[=[
	@within Observers

	Creates an observer around an attribute of a given instance. The callback will fire for any non-nil
	attribute value.

	```lua
	observeAttribute(workspace.Model, "MyAttribute", function(value)
		print("MyAttribute is now:", value)

		return function()
			-- Cleanup
			print("MyAttribute is no longer:", value)
		end
	end)
	```

	An optional `guard` predicate function can be supplied to further narrow which values trigger the observer.
	For instance, if only strings are wanted:

	```lua
	observeAttribute(
		workspace.Model,
		"MyAttribute",
		function(value) print("value is a string", value) end,
		function(value) return typeof(value) == "string" end
	)
	```

	The observer also returns a function that can be called to clean up the observer:
	```lua
	local stopObserving = observeAttribute(workspace.Model, "MyAttribute", function(value) ... end)

	task.wait(10)
	stopObserving()
	```
]=]
local function observeAttribute<T>(
	instance: Instance,
	name: string,
	callback: (value: T) -> ...any,
	guard: ((value: T) -> boolean)?
): () -> ()
	local cleanFn: (() -> ())? = nil

	local onAttrChangedConn: RBXScriptConnection
	local changedId = 0

	local valueGuard: (value: any) -> boolean = if guard ~= nil then guard :: any else defaultGuard

	local function onAttributeChanged()
		if cleanFn ~= nil then
			task.spawn(cleanFn)
			cleanFn = nil
		end

		changedId += 1
		local id = changedId

		local value = instance:GetAttribute(name) :: any?

		if value ~= nil and valueGuard(value) then
			task.spawn(function()
				local clean = (callback :: any)(value)
				if typeof(clean) == "function" then
					if id == changedId and onAttrChangedConn.Connected then
						cleanFn = clean
					else
						task.spawn(clean)
					end
				end
			end)
		end
	end

	-- Get changed values:
	onAttrChangedConn = instance:GetAttributeChangedSignal(name):Connect(onAttributeChanged)

	-- Get initial value:
	task.defer(function()
		if not onAttrChangedConn.Connected then
			return
		end

		onAttributeChanged()
	end)

	-- Cleanup:
	return function()
		onAttrChangedConn:Disconnect()
		if cleanFn ~= nil then
			task.spawn(cleanFn)
			cleanFn = nil
		end
	end
end

return observeAttribute
