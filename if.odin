package main

import "core:fmt"

potato :: proc() -> int {
    return 5
}

print_something :: proc(something: string) {
    fmt.println(something)
}

main :: proc() {

    x := 2

    if x >= 0 {
	fmt.printfln("x is greater than zero. Its value is %d", x)
    }

    if y := potato(); y == 0 {
	fmt.println("y is zero")
    } else if y < 5 {
	fmt.printfln("y is less than five. Its value is %d", y)
    } else if y == 5 do print_something("YO, high five")
    else {
	fmt.printfln("y is neither zero nor less than 5. Its value is %d", y)
    }

}
