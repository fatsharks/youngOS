#ifndef _ORANGES_STRING_H_
#define _ORANGES_STRING_H_
#include "const.h"

PUBLIC void* memcpy(void* p_dst, void* p_src, int size);
PUBLIC void     memset(void* p_dst, char ch, int size);

#define phys_copy   memcpy
#define phys_set    memset

#endif