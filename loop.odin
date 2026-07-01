#+feature dynamic-literals
package main

import "core:fmt"

potato :: proc() {
    fmt.println("I'm a potato")
}


/*
  Odin only has one loop statement: for
*/
main :: proc() {
    // Basic for loop
    for i := 0; i < 10; i += 1 {
	fmt.printfln("i is %d", i)
    }

    // For loop with `do`
    for i := 0; i < 10; i += 1 do potato()

    // the initial and post statements are optional:
    j := 0
    for ; j < 5; {
	fmt.printfln("j is %d", j)
	j += 1
    }

    // the semicolons can also be dropped
    k := 0

    for k < 3 {
	fmt.printfln("k is %d", k)
	k += 1
    }

    // infinite loop:
    /*
	for {}
    */

    // Other ways of writing the basic for loop:
    // 1. [0, 10)
    for i in 0..<10 {
	fmt.println(i)
    }
    // 2. [0, 9]
    for i in 0..=9 {
	fmt.println(i)
    }

    // Certain built-in types can be iterated over:
    // NOTE: the iterated values are COPIES and cannot be written to.
    my_string := "Guilherme"
    for character, index in my_string { // or just: for character in my_string {}
	fmt.printfln("At %d: %c", index, character)
    }

    some_array := [3]int{1, 4, 9}
    for value, index in some_array { // or just: for value in some_array {}
	fmt.printfln("At %d: %d", index, value)
    }

    some_slice := []int{2, 8, 12}
    for value, index in some_slice { // or just: for value in some_slice {}
	fmt.printfln("At %d: %d", index, value)
    }

    // If you want to enable them for this specific file,
    // add '#+feature dynamic-literals' at the top of the file
    some_dynamic_array := [dynamic]int{11, 44, 99}
    defer delete(some_dynamic_array) // frees the underlying memory when we're done.
    for value, index in some_dynamic_array { // or just: for value in some_dynamic_array {}
	fmt.printfln("At %d: %d", index, value)
    }

    // If you want to enable them for this specific file,
    // add '#+feature dynamic-literals' at the top of the file
    some_map := map[string]int{"A" = 1, "C" = 9, "B" = 4}
    defer delete(some_map)
    for key, value in some_map { // or just:  for key in some_map {}
	fmt.printfln("%s: %d", key, value)
    }

    // NOTE: you can change the copies if you iterate arrays - and dynamic arrays
    // NOTE: - or slices by reference
    for &value in some_dynamic_array {
	value = 22
    }

    fmt.println(some_dynamic_array) // [22, 22, 22]

    // NOTE: map VALUES can be iterated by reference, but their KEYS cannot
    // as they are immutable
    for key, &value in some_map {
	value += 1
    }

    fmt.println(some_map["A"]) // 2
    fmt.println(some_map["B"]) // 5
    fmt.println(some_map["C"]) // 10

    // NOTE: also you CANNOT iterate a STRING by reference, as strings are IMMUTABLE.

    // REVERSE for
    my_array := [?]int {10, 20, 30}
    #reverse for x in my_array {
	fmt.println(x) // 30 20 10
    }

    // UNROLLING for: expands at compile time.
    // Good for performance when the loop is small
    // Can only be done when we have constant intervals known at compile-time
    x: [4]u8 = 0xFF // [0xFF, 0xFF, 0xFF, 0xFF]
    y: [4]u8 = 0x88 // [0x88, 0x88, 0x88, 0x88]
    #unroll for i in 0..<len(x) {
	x[i] ~= y[i] // XOR
    }

    fmt.printfln("%x", x) // [0x77, 0x77, 0x77, 0x77]
}
