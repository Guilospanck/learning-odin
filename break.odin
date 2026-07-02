package main

import "core:fmt"

check_something :: proc() -> bool {
    fmt.println("Checking something...")
    return false
}

main :: proc(){

    for {
	switch {
	case:
	   if true {
		fmt.println("break if-switch-for")
		break // break out of the switch statement
	   } 
	}

	fmt.println("break for")
	break // break out of the for statement
    }

    loop: for {
	for {
	    fmt.println("break loop")
	    break loop // leaves both loops
	}

	fmt.println("This won't be printed")
    }

    outer: if true {
	ok := check_something()
	if !ok {
	    fmt.println("break outer")
	    break outer // label names are required with conditionals
	}
    }

    // works with labeled blocks too
    exit: {
	if true {
	    fmt.println("break exit")
	    break exit
	}

	fmt.println("This will never print")
    }
}
