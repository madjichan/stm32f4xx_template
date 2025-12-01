#include <sys/stat.h>
#include <errno.h>

int _write(int fd, const void *buf, size_t count) {
    return count;
}

int _sbrk(int incr) {
    extern char _end;
    static char *heap_end;
    char *prev_heap_end;

    if (heap_end == 0)
        heap_end = &_end;

    prev_heap_end = heap_end;
    heap_end += incr;
    return (int)prev_heap_end;
}

int _close(int fd) {
    return -1;
}

int _fstat(int fd, struct stat *st) {
    return 0;
}

int _isatty(int fd) {
    return 1;
}

int _lseek(int fd, int ptr, int dir) {
    return 0;
}

int _read(int fd, void *buf, size_t count) {
    return 0;
}
