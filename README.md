# lua-encored
Converts an lua table to an array (an integer indexed table) and reconstructs based on a schema.

Half-Hearted Apache Avro, it just goes half-way there. Maybe it evolves in the future.

## Schema Specification
A schema is formated by one or more fields with 2 required attributes: name, type and other optional ones.
Ex. schema:

```lua
local person_schema = {
    { name = "given_name", type = "string" },
    { name = "family_name", type = "string" },
    { name = "height", type = "number" },
    { name = "gender", type = "string" },
    { name = "birthday", type = "number" }
}
```

Schemas are composables, ex.:

```lua
local John = {
    person_schema,
    { name = "friends", type = "array", items = person_schema }
}
```

### Field Types:
- `number`
ex. value: 42 or 3.14 or -24

- `string`
ex. value: "Lorem ipsum"

- `bool`
ex. value: true or false

- `record` Field of type `record` tales additional attribute `items` which can take a collection of field that make a record.

- `array` Field of type `array` tales additional attribute `items` which can take a collection of fields to make an array of records.


### Additional Field Attributes:
* `default`: set's up a default value for when the field value is nil
* `optional`: the field value can be nil

## Usage Example:

1. Write your schema.

```lua
local member_schema = {
    { name = "given_name", type = "string" },
    { name = "family_name", type = "string" },
    { name = "status", type = "string", default = "confirmation_pending" },
    { name = "email", type = "string" },
    { name = "password", type = "record", items = {
        { name = "enc_pass", type = "string" },
        { name = "salt", type = "string" },
        { name = "alg", type = "string"}
    } },
    { name = "last_locations", type = "array", items = {
        { name = "name", type = "string" },
        { name = "X", type = "number" },
        { name = "Y", type = "number" },
        { name = "time", type = "number" }
    } }
}
```

2. Validate your schema.

```lua
local encored = require("encored")

local is_valid = encored.validate_schema(member) -- true
if not is_valid then error("Schema is not valid") end

```

3. Encode your data

```lua
local member_data = {
    given_name = "Tasos",
    family_name = "Soukoulis",
    status = nil,               -- replaced by default
    email = "lua.encored@gmail.com",
    password = {
        enc_pass = "lua_encored_secret_pass",
        salt = "esypn3v895ytcrq",
        alg = "bcrypt"
    },
    last_locations = {
        {name = "New York, US", X = 45.213, Y = 23.435, time = 1519426665 },
        {name = "Athens, GR", X = 37.15, Y = 11.435, time = 1519426739 },
        {name = "Bucharest, RO", X = 25.511, Y = 17.525, time = 1519529216 },
    }
}

local encoded_data = encored.encode(member_schema, member_data)
--[[
{ 'Tasos', 'Soukoulis', 'confirmation_pending', 'lua.encored@gmail.com', { 
'lua_encored_secret_pass', 'esypn3v895ytcrq', 'bcrypt' }, { { 'New York, US', 
    45.213, 23.435, 1519426665 }, { 'Athens, GR', 37.15, 11.435, 1519426739 }, { 
    'Bucharest, RO', 25.511, 17.525, 1519529216 } } }
]]--
```

4. Decode your encoded data.

```lua

local decoded = encored.decode(member_schema, encoded_data)

```

## TODO:
* Write `normalize` ✕
* Write `validate_data` ✕
* Write `tests` ✕

## API
- `encode(schema, table)`
- `decode(schema, array)`
- <del>`normalize(schema, array)` add's msgpack.NULL where table element is missing.</del>
- `validate_schema(schema)` it validates the schema using the specification.
- <del>`validate_data(schema, tableORarray)` it validates the tableORarray based on a schema.</del>

