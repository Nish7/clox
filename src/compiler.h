#ifndef clox_compiler_h
#define clox_compiler_h

#include "common.h"
#include "vm.h"

ObjFunction *compile(const char *source);

#endif
