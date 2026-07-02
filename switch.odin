package main

import "core:fmt"

foo :: proc() -> int {
    return 0
}

main :: proc() {

    // a `break` statement is NOT needed as odin only runs a specific case
    // for a "fall through", you can use the keyword `fallthrough`
    switch arch := ODIN_ARCH; arch {
    case .i386, .wasm32, .arm32:
	fmt.println("32 bit")
    case .amd64, .wasm64p32, .arm64, .riscv64:
	fmt.println("64 bit")
    case .Unknown:
	fmt.println("Unknown arch")
    }

    // without fallthrough, `foo()` does not get called here
    i := 0
    switch i {
    case 0:
	fmt.println("won't fallthrough")
    case foo():
	// won't be called
	fmt.println("foo called")
    }

    // with `fallthrough`, it DOES
    switch i {
    case 0:
	fmt.println("will fallthrough")
	fallthrough
    case foo():
	// will be called
	fmt.println("foo called")
    }

    // switch without condition (switch true), is good to write
    // a clean and long if-else chain and have the ability to `break` when needed
    x := 2
    switch {
    case x < 0:
	fmt.println("X is negative")
    case x == 0:
	fmt.println("X is zero")
    case: // default
	fmt.println("X is positive")
    }

    // we can also use ranges (like in rust)
    c := '%'
    switch c {
    case 'A'..='Z', 'a'..='z', '0'..='9' :
	fmt.println("c is alphanumeric")
    case:
	fmt.println("c is NOT alphanumeric")
    }

    // we can use #partial keyword when we don't need/want to check for all
    // possible values
    Foo :: enum {
	A, 
	B, 
	C,
	D,
    }

    f := Foo.A

    // without #partial you need to check for ALL "Foo" possibilities
    switch f {
    case .A: fmt.println("A")
    case .B: fmt.println("B")
    case .C: fmt.println("C")
    case .D: fmt.println("D")
    case:    fmt.println("?")
    }

    #partial switch f {
    case .A: fmt.println("A")
    case .D: fmt.println("D")
    }

    // type switch statements
    Value :: union {
	bool, i32, f32, string,
    }
    my_union: Value
    my_union = f32(2)

    switch v in my_union {
    case string:
	#assert(type_of(v) == string)
	fmt.println("it's a string")
    case bool:
	#assert(type_of(v) == bool)
	fmt.println("it's a bool")
    case i32, f32:
	// As this can be multiple values, we can't use
	// assert, otherwise it will panic
	#assert(type_of(v) == Value)
	
	// we could use something like this, tho
	_, ok := v.(i32)
	if ok do fmt.println("it's i32")
	else do fmt.println("it's f32")
    case:
	// Default case
	// In this case, it is `nil`
    }
}
