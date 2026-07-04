package main

import "core:fmt"

// Type alias
My_Int :: int
#assert(My_Int == int)

// Distinct types: it creates a NEW type, but withthe same underlying semantics.
// It's used so we can prevent mixing values that happen to have the same
// representation, but different meanings
My_Distinct_Int :: distinct int
#assert(My_Distinct_Int != int)

// Aggregate types (struct, enum, unions)
// will always be distinct.
Foo :: struct {}
#assert(Foo != struct {})

accept_int :: proc(something: int) {
  fmt.println("Received: ", something)
}

accept_distinct_int :: proc(something: My_Distinct_Int) {
  fmt.println("Received: ", something)
}

main :: proc() {
  potato: int = 8
  james: My_Int = 8
  larry: My_Distinct_Int = 8

  // both works
  accept_int(potato)
  accept_int(james)

  accept_distinct_int(larry) // this works
  // accept_distinct_int(potato) // this doesn't, because we only accept distinct
}

