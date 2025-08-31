# Variable Declaration vs Definition

In Lox, there are two distinct phases for variables:

### Declaration
```clox/src/compiler.c#L583-597
static void declareVariable() {
  if (current->scopeDepth == 0)
    return;

  Token *name = &parser.previous;
  for (int i = current->localCount - 1; i >= 0; i--) {
    Local *local = &current->locals[i];
    if (local->depth != -1 && local->depth < current->scopeDepth) {
      break;
    }

    if (identifierEqual(name, &local->name)) {
      error("Already a variable with this name in this scope.");
    }
  }
```

**Declaration** reserves a name in the current scope and checks for duplicate names. For local variables, this adds the variable to the compiler's local array but marks it as uninitialized (depth = -1).

### Definition
```clox/src/compiler.c#L606-616
static void defineVariable(uint8_t global) {
  if (current->scopeDepth > 0) { // if it local mark it initialized
    markInitialized();
    return;
  }

  emitBytes(OP_DEFINE_GLOBAL, global); // define global with constant idx
}
```

**Definition** actually creates the variable and assigns it a value. For locals, this marks the variable as initialized. For globals, this emits bytecode to create the variable in the global table.

## Local vs Global Variables

### Local Variables

Local variables are stored in a compile-time array and accessed by stack slot indices:

```clox/src/compiler.c#L25-29
typedef struct {
  Token name;
  int depth;
  bool isCaptured;
} Local;
```

Key characteristics:
- Stored in the `locals` array during compilation
- Accessed via `OP_GET_LOCAL` and `OP_SET_LOCAL` with stack slot indices
- Scope depth tracks nesting level
- `isCaptured` indicates if the variable is closed over by a closure
- Resolved at compile time for fast runtime access

Example from tests:
```clox/test/block.lox#L1-8
var a = "global a";

{
  var a = "block a";
  print a; 
}

print a; 
```

### Global Variables

Global variables are stored in a hash table at runtime:

```clox/src/vm.c#L292-296
case OP_DEFINE_GLOBAL: {
  ObjString *name = READ_STRING();
  tableSet(&vm.globals, name, peek(0));
```

Key characteristics:
- Stored in the VM's global hash table (`vm.globals`)
- Accessed via `OP_GET_GLOBAL` and `OP_SET_GLOBAL` with string names
- Resolved at runtime by name lookup
- Can be accessed from any scope

The resolution logic prioritizes locals first:
```clox/src/compiler.c#L406-420
static void namedVariable(Token name, bool canAssign) {
  uint8_t getOp, setOp;
  int arg = resolveLocal(current, &name);
  if (arg != -1) {
    getOp = OP_GET_LOCAL;
    setOp = OP_SET_LOCAL;
  } else if ((arg = resolveUpvalue(current, &name)) != -1) {
    getOp = OP_GET_UPVALUE;
    setOp = OP_SET_UPVALUE;
  } else {
    arg = identifierConstant(&name);
    getOp = OP_GET_GLOBAL;
    setOp = OP_SET_GLOBAL;
  }
```

## Class Accessors (Properties)

Classes in Lox support dynamic property access through dot notation:

### Class Structure
```clox/src/object.h#L78-87
typedef struct {
  Obj obj;
  ObjString *name;
} ObjClass;

typedef struct {
  Obj obj;
  ObjClass *klass;
  Table fields;
} ObjInstance;
```

### Property Access Implementation
```clox/src/compiler.c#L451-461
static void dot(bool canAssign) {
  consume(TOKEN_IDENTIFIER, "Expect property name after '.'");
  uint8_t name = identifierConstant(&parser.previous);

  if (canAssign && match(TOKEN_EQUAL)) {
    expression();
    emitBytes(OP_SET_PROPERTY, name);
  } else {
    emitBytes(OP_GET_PROPERTY, name);
  }
}
```

### Runtime Property Operations
```clox/src/vm.c#L381-397
case OP_GET_PROPERTY: {
  if (!IS_INSTANCE(peek(0))) {
    runtimeError("Only instances have properties.");
    return INTERPRET_RUNTIME_ERROR;
  }

  ObjInstance *instance = AS_INSTANCE(peek(0));
  ObjString *name = READ_STRING();

  Value value;
  if (tableGet(&instance->fields, name, &value)) {
```

Key characteristics:
- Properties are stored in a hash table per instance (`instance->fields`)
- Dynamic property creation - you can add properties at runtime
- No declaration required - properties are created on first assignment
- Accessed via dot notation (`object.property`)

Example from tests:
```clox/test/class_state.lox#L1-6
class Pair {}

var pair = Pair();
pair.first = 1;
pair.second = 2;
print pair.first + pair.second;
```

## Summary

1. **Declaration vs Definition**: Declaration reserves the name and checks for conflicts; definition creates the variable and assigns the initial value.

2. **Local Variables**: Compile-time resolved, stack-based storage, fast access via indices, lexically scoped.

3. **Global Variables**: Runtime resolved, hash table storage, slower name-based lookup, globally accessible.

4. **Class Properties**: Dynamic hash table-based fields per instance, created on first assignment, accessed via dot notation.
