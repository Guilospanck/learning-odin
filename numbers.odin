package main

import "core:fmt"

main :: proc() {

	// 0x : hexa
	fmt.println(0x16) // 22

	// 0o : octal
	// 0b : binary
	fmt.println(0b00001010) // 10

	// you can use underscores to make it easier to read (1_000_000_000)
	fmt.println(1_000_000)

	// Adding a dot to a number makes it a floating point literal
	fmt.println(2.2)

	// A float literal but it can be represented by an integer without
	// precision loss.
	x: int = 1.0
	fmt.println(x)

	// This doesn't work because there would be a precision loss of
	// converting from floating point to an integer.
	// y: int = 1.1

}
