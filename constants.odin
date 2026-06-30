package main

import "core:fmt"

main :: proc() {

	// constant values MUST be able to be evaluated at compile time.
	// Its value cannot be changed
	x :: "what"

	// x = "potato" // ERROR, constant cannot be changed

	// explictly typed constant declaration
	y : int : 123

    // constant computations are possible
	z :: y + 7 
	fmt.println(z) // 130
}
