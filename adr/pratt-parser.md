The Parsing Method: Pratt Parser (Recursive Descent with Precedence)

This Lox interpreter uses a **Pratt parser**, which is a type of recursive descent parser that to handle operator precedence. Here's how it works:

### 1. **Core Components**

The parser has these key structures:

```clox/src/compiler.c#L18-23
typedef struct {
  Token current;
  Token previous;
  bool hadError;
  bool panicMode;
} Parser;
```

- `current` - the token being looked at
- `previous` - the token just consumed
- `hadError` and `panicMode` - for error handling

### 2. **The Magic: Parse Rules Table**

The heart of the Pratt parser is a table that maps each token type to parsing functions:

```clox/src/compiler.c#L63-67
typedef struct {
  ParseFn prefix;
  ParseFn infix;
  Precedence precedence;
} ParseRule;
```

Each token has:
- A **prefix** function (for when the token appears at the start of an expression)
- An **infix** function (for when it appears between operands) 
- A **precedence** level

### 3. **Precedence Levels**

```clox/src/compiler.c#L48-60
typedef enum {
  PREC_NONE,
  PREC_ASSIGNMENT, // =
  PREC_OR,         // or
  PREC_AND,        // and
  PREC_EQUALITY,   // == !=
  PREC_COMPARISON, // < > <= >=
  PREC_TERM,       // + -
  PREC_FACTOR,     // * /
  PREC_UNARY,      // ! -
  PREC_CALL,       // . ()
  PREC_PRIMARY
} Precedence;
```

Higher numbers = higher precedence (binds tighter).

### 4. **The Main Parsing Algorithm**

```clox/src/compiler.c#L216-236
static void parsePrecedence(Precedence precendence) {
  advance();
  ParseFn prefixRule = getRule(parser.previous.type)->prefix;
  if (prefixRule == NULL) {
    error("Expect expression.");
    return;
  }

  bool canAssign = precendence <= PREC_ASSIGNMENT;
  prefixRule(canAssign);

  while (precendence <= getRule(parser.current.type)->precedence) {
    advance();
    ParseFn infixRule = getRule(parser.previous.type)->infix;
    infixRule(canAssign);
  }

  if (canAssign && match(TOKEN_EQUAL)) {
    error("Invalid assignment target");
  }
}
```

Here's what happens:
1. **Start with prefix**: Parse the first token using its prefix function
2. **Look ahead**: Check if the next token has higher precedence than what we're looking for
3. **If yes**: Consume it and call its infix function, then repeat
4. **If no**: We're done with this precedence level

### 5. **Example: Parsing "2 + 3 * 4"**

1. Start parsing with `PREC_ASSIGNMENT`
2. See `2` → call `number()` (prefix function)
3. See `+` with `PREC_TERM` → higher than assignment, so continue
4. Call `binary()` for `+`, which calls `parsePrecedence(PREC_FACTOR)` for right side
5. In the recursive call: see `3`, then `*` with `PREC_FACTOR` 
6. Call `binary()` for `*`, parse `4`
7. `*` is done, return to `+` which now has `(3 * 4)` as its right operand

Precedence Examples

Let's trace through some expressions:

### Example 1: `2 + 3 * 4`

1. Start with `parsePrecedence(PREC_ASSIGNMENT)`
2. Parse `2` (prefix rule)
3. See `+` with PREC_TERM, continue parsing
4. Parse right side with `parsePrecedence(PREC_FACTOR)` (TERM + 1)
5. Parse `3` (prefix rule)  
6. See `*` with PREC_FACTOR, continue parsing (FACTOR >= FACTOR)
7. Parse `4` with `parsePrecedence(PREC_UNARY)` (FACTOR + 1)
8. Result: `2 + (3 * 4)` ✓

### Example 2: `a and b or c`

1. Start parsing with PREC_ASSIGNMENT
2. Parse `a`
3. See `and` (PREC_AND), parse right side with PREC_EQUALITY
4. Parse `b`
5. See `or` (PREC_OR), but PREC_OR < PREC_EQUALITY, so stop the `and` parsing
6. Back to main level, see `or` (PREC_OR), parse right side
7. Result: `(a and b) or c` ✓
