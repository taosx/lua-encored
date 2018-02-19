lua-encored it converts an lua table to an array (an integer indexed table) and reconstructs based on a schema.

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

local John = {
    person_schema,
    { name = "friends", type = "array", items = person_schema }
}

### Field Types:
- `number`
ex. value: 42 or 3.14 or -24

- `string`
ex. value: "Lorem ipsum"

- `bool`
ex. value: true or false


- `array`
Field of type `array` has an additional attribute `items` which can take a type or another schema.
ex. fields:
1. `{ name = "primes", type = "array", items = "number" }`
data: `{ primes = {2, 73, 179} }`


2. `{ name = "names", type = "array", items = "string" }`
data: `{ name = "Tasos", "Mike", "John" }`


3. 
```
{ name = "friends", type = "array", items = {
    { name = "given_name", type = "string" },
    { name = "family_name", type = "string" }
} }
```
data:
```
{
    friends = {
        { given_name = "Tasos", family_name = "Soukoulis" },
        { given_name = "Mike", family_name = "Doe" },
        { given_name = "John", family_name = "Tyson" }
    }
}
```

Additional Field Attributes:
`default`: 


## API
`encode(schema, table)`
`decode(schema, array)`
`normalize(schema, array)` add's msgpack.NULL where table element is missing.
`validate_schema(schema)` it validates the schema using the specification.
`validate(schema, tableORarray)` it validates the tableORarray based on a schema.

