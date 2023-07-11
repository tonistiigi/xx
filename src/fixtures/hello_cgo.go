package main

// #include <stdio.h>
// #include <stdlib.h>
//
// static void hello(char* s) {
//   printf("hello %s\n", s);
//   fflush(stdout);
// }
import "C"
import (
	"unsafe"
)

func main() {
	cs := C.CString("cgo")
	C.hello(cs)
	C.free(unsafe.Pointer(cs))
}
