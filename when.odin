package main

import "core:fmt"

/*

   when is almost identical to `if`, but
   - it is evaluated at compile time, so each condition MUST be a constant expr
   - the statements within a branch do NOT create a new scope
   - it's like the #if in C

   !!!
   Because when is evaluated during compilation, the branch that isn't taken
   is NEVER type-checked or compiled. This is ideal for platform-specific code.
   !!!
*/
main :: proc() {
    when ODIN_ARCH == .i386 {
	fmt.println("Arch is .i386")
    } else when ODIN_ARCH == .amd64 {
	fmt.println("Arch is .amd64")
    } else when ODIN_ARCH == .arm64 {
	fmt.println("Arch is .arm64")
    } else {
	fmt.println("Unsupported arch")
    }
}
