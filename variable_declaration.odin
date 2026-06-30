package main

main :: proc() {

	x: int = 123
	// or x: = 123  (default type for an integer literal is `int`)
	// or x := 123

	y := 10
	y := 20 // You cannot do this. Redeclaration of y in this scope.

	z := 33

	test, z := 11, 22 // not allowed. Redeclaration of y in this scope.

	test := 10 
	// or test: int
	// or test: int = 10
	// or test: = 10
	test, z = 11, 22 // this works. (if you remove the `test, z := 11, 22` from above, of course)

}
