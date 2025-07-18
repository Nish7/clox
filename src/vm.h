#ifndef clox_vm_h
#define clox_vm_h

#include "chunk.h"
#include "object.h"
#include "table.h"
#include "value.h"
#define FRAMES_MAX 64
#define STACK_MAX (FRAMES_MAX * UINT8_COUNT)

typedef struct {
  ObjClosure *closure;
  uint8_t *ip;
  Value *slots;
} CallFrame;

typedef struct {
  CallFrame frames[FRAMES_MAX];
  int frameCount;
  Value stack[STACK_MAX];
  Value *stackTop;
  Obj *objects;
  Table strings;
  ObjUpvalue *openUpvalues;
  Table globals;
} VM;

extern VM vm;

typedef enum {
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR
} InterpretResult;

void initVM();
void freeVM();
void freeObjects();
InterpretResult interpret(const char *source);
void push(Value value);
Value pop();

#endif
