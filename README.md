# observers-typed

> Utility observer functions, with updated types — for Roblox.

A strongly-typed collection of observer utility functions for Roblox, written in Luau with `--!strict`. Each observer fires a callback when something becomes "active" (a player joins, a tag is applied, an attribute changes, etc.) and calls an optional cleanup function when that thing becomes "inactive".

## Installation

Install via [pesde](https://github.com/daimond113/pesde):

```sh
pesde add josephh310/observers_typed
```

## Usage

```luau
local Observers = require(path.to.observers_typed)

Observers.observeTag(...)
Observers.observeAttribute(...)
Observers.observeProperty(...)
Observers.observePlayer(...)
Observers.observeCharacter(...)
Observers.observeLocalCharacter(...)
```

Every observer function returns a **stop function** that, when called, disconnects all internal connections and runs any pending cleanup functions.

---

## API

### `observeTag`

```luau
observeTag<T>(tag: string, callback: (instance: T) -> (() -> ())?, valid_ancestry: (Instance | { Instance })?): () -> ()
```

Observes instances tagged with a [CollectionService](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag. The callback fires for each matching instance and may return a cleanup function that is called when the instance loses the tag, is destroyed, or (if `valid_ancestry` is provided) leaves the allowed ancestor hierarchy.

```luau
local stopObserving = Observers.observeTag("MyTag", function(instance: Instance)
    print("Observing", instance)

    return function()
        print("Stopped observing", instance)
    end
end)

-- Stop the observer after 10 seconds:
task.wait(10)
stopObserving()
```

#### Ancestor inclusion list

By default, tagged instances are observed anywhere in the game hierarchy. Pass a `valid_ancestry` argument to restrict observation to instances that are descendants of the given ancestor(s). This can be a single `Instance` or a table of `Instance`s.

```luau
-- Only observe "MyTag" instances that are inside the Workspace:
Observers.observeTag("MyTag", function(instance: Instance)
    -- ...
end, workspace)

-- Or pass multiple ancestors as a table:
Observers.observeTag("MyTag", function(instance: Instance)
    -- ...
end, { workspace, game:GetService("ReplicatedStorage") })
```

---

### `observeAttribute`

```luau
observeAttribute<T>(instance: Instance, name: string, callback: (value: T) -> (() -> ())?, guard: ((value: T) -> boolean)?): () -> ()
```

Observes an attribute on an instance. The callback fires whenever the attribute has a non-nil value, and the optional cleanup function is called when the value changes away from the previous one. The generic type `T` allows you to specify the expected attribute type.

```luau
Observers.observeAttribute(workspace.Model, "MyAttribute", function(value)
    print("MyAttribute is now:", value)

    return function()
        print("MyAttribute is no longer:", value)
    end
end)
```

An optional `guard` predicate can be provided to narrow which values trigger the callback:

```luau
-- Only fire the callback when the attribute is a string:
Observers.observeAttribute(
    workspace.Model,
    "MyAttribute",
    function(value)
        print("value is a string:", value)
    end,
    function(value)
        return typeof(value) == "string"
    end
)
```

---

### `observeProperty`

```luau
observeProperty<I, P>(instance: I & Instance, property: P & keyof<I>, callback: (value: index<I, P>) -> (() -> ())?): () -> ()
```

Observes a property of an instance. The callback fires immediately with the current value and again whenever the property changes. The optional cleanup function is called before each new callback invocation. The generic types `I` and `P` ensure that the property name is valid for the given instance type, and the callback receives the correctly typed value.

```luau
Observers.observeProperty(workspace.Model, "Name", function(newName: string)
    print("New name:", newName)

    return function()
        print("Model's name is no longer:", newName)
    end
end)
```

---

### `observePlayer`

```luau
observePlayer(callback: (player: Player) -> (() -> ())?): () -> ()
```

Observes all players in the game. The callback fires for every player currently in the game and for each new player that joins. The optional cleanup function is called with the player's `Enum.PlayerExitReason` when they leave.

```luau
Observers.observePlayer(function(player)
    print("Player joined:", player.Name)

    return function(exitReason: Enum.PlayerExitReason)
        print("Player left:", player.Name, "| Reason:", exitReason.Name)
    end
end)
```

---

### `observeCharacter`

```luau
observeCharacter(callback: (player: Player, character: Model) -> (() -> ())?, allowedPlayers: { Player }?): () -> ()
```

Observes every character in the game. The callback fires whenever any player's character spawns and receives both the `Player` and their `Model`. The optional cleanup function is called when the character is removed.

```luau
Observers.observeCharacter(function(player, character)
    print("Character spawned for", player.Name)

    return function()
        print("Character removed for", player.Name)
    end
end)
```

An optional `allowedPlayers` array restricts observation to only the listed players:

```luau
Observers.observeCharacter(function(player, character)
    -- Only fires for somePlayer and anotherPlayer
end, { somePlayer, anotherPlayer })
```

---

### `observeLocalCharacter`

```luau
observeLocalCharacter(callback: (character: Model) -> (() -> ())?): () -> ()
```

> **Client-only.** Will error if called from the server.

Observes the local player's character. The callback fires when the local character spawns, and the optional cleanup function is called when it is removed.

```luau
-- In a LocalScript or client-context script:
Observers.observeLocalCharacter(function(character)
    print("Local character spawned")

    return function()
        print("Local character removed")
    end
end)
```

---

## Cleanup Pattern

All observer functions return a stop function. Call it to disconnect the observer and run any active cleanup functions immediately:

```luau
local stop = Observers.observeTag("MyTag", function(instance)
    -- ...
end)

-- Later, when the observer is no longer needed:
stop()
```

---

## License

MIT — see [LICENSE.md](LICENSE.md) for details.