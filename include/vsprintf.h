#ifndef _H_VSPRINTF
#define _H_VSPRINTF

#include <stdarg.h>
#include <string.h>

int vsprintf(char *buf, const char *fmt, va_list args);

static inline void print_covering(char * str) {
    char * video_buffer = (char *) 0xb8000;
    size_t len = strlen(str);
    for (unsigned long i = 0; i < len; ++i) {
        video_buffer[i*2] = str[i];
        video_buffer[i*2+1] = 0x07;
    }
    return;
}

#endif