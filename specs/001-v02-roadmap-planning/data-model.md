# Data Model: typethis v0.2

## Core Entities

### 1. TypedFunction

Represents a function wrapped with type validation.

**Fields**:
- `fn`: The original function
- `arg_specs`: Named list of type specifications (e.g., `list(x = "integer", y = "numeric")`)
- `return_spec`: Return type specification
- `formals`: Captured formals from original function
- `metadata`: Additional introspection data

**Validation Rules**:
- arg_specs names must match function's formal argument names (subset allowed)
- return_spec must be valid type specification
- fn must be a function

### 2. TypedModel

Represents a validated record-like class.

**Fields**:
- `class_name`: Character string naming the class
- `fields`: Named list of field definitions
- `validator_fn`: Custom validation function (optional)

**Field Definition**:
- `name`: Field name
- `type_spec`: Type specification
- `nullable`: Logical, default FALSE
- `default`: Default value (optional)
- `validator`: Custom field validator (optional)

### 3. TypedModelInstance

**Fields**:
- `_class`: Reference to TypedModel
- `[field_names]`: Actual field values as list

**Validation Rules**:
- All non-nullable fields must be present and valid
- Field values must match their type specs
- Nested model instances must be valid

## State Transitions

### TypedModelInstance Lifecycle

```
[Construction]
    │
    ▼
new_ModelName(...) ──► [Validation] ──► ValidInstance
    │                              │
    │                              ▼
    │                         InvalidError
    ▼
update_ModelName(inst, ...)
    │
    ▼
[Validate Updated Values]
    │
    ├── Valid ─► UpdatedInstance
    └── Invalid ─► Error
```

## Relationships

- TypedModel → has many → FieldDefinition
- TypedModel → creates → TypedModelInstance
- TypedModelInstance → references → TypedModel