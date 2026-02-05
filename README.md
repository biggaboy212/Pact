# Pact

Schema based Luau networking library

## Installation

### Wally

Add Pact to your `wally.toml` dependencies:

```toml
[dependencies]
# Use the latest tag: https://github.com/biggaboy212/Pact/tags
pact = "biggaboy212/pact@1.0.3"
```

Then run:

```bash
wally install
```

## Usage

### Defining schemas

Create a shared module to define your packets. Packets must have unique IDs. (sorry)

```luau
-- shared/network.luau
local Pact = require(path.to.pact)

return {
    -- Unreliable packet (UDP)
    MouseUpdate = Pact.Packet.new({
        id = 1,
        protocol = "UDP",
        schema = Pact.Schema.struct({
            position = Pact.Schema.vector3(),
            isAiming = Pact.Schema.boolean()
        })
    }),

    -- Reliable packet (TCP)
    Interact = Pact.Packet.new({
        id = 2,
        protocol = "TCP",
        schema = Pact.Schema.struct({
            targetId = Pact.Schema.u32(),
            action = Pact.Schema.string()
        })
    })
}
```

### Sending a packet

```luau
-- Client

local Network = require(game.ReplicatedStorage.Shared.network)

Network.MouseUpdate:send({
    position = mouse.Hit.Position,
    isAiming = true
})
```

### Listening for a packet

```luau
-- Server

local Network = require(game.ReplicatedStorage.Shared.network)

Network.MouseUpdate:listen(function(data, sender)
    print(sender.Name, "is aiming at", data.position)
end)
```

## API Reference

### `Pact.Packet`

#### `Packet.new<T>(definition)`

Creates a new packet interface.

- definition:
  - `id`: Unique `number` identifier for the packet.
  - `protocol`: `"TCP"` (Reliable) or `"UDP"` (Unreliable).
  - `schema`: A `Schema<T>` object.

##### `:send(data: T, target: Player?)`

Sends data.

- data: The table or value matching the schema.
- target: Specific `Player` (Server-side only). If nil on Server, broadcasts to all clients.

##### `:listen(callback: (data: T, sender: Player?) -> ())`

Connects a listener.

- sender: The `Player` who sent the packet (Server-side only).

### `Pact.Schema`

Primitives for packetdefs

| Type | Size (Bytes) | Description |
| --- | --- | --- |
| `u8`, `u16`, `u32` | 1, 2, 4 | Unsigned Integers |
| `i8`, `i16`, `i32` | 1, 2, 4 | Signed Integers |
| `f32`, `f64` | 4, 8 | Floating Point Numbers |
| `boolean` | 1 | True/False |
| `string` | 4 + N | Length prefixed string |
| `vector3` | 12 | 3 f32 (X, Y, Z) |

#### `Schema.struct(definition)`

Creates a obj schema.

- definition: table - `{ [key]: Schema }`
