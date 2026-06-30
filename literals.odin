package main

import "core:fmt"

main :: proc() {
	// "This is a string"
	// 'A'  <- This is a character
	// '\n' <- newline character


	fmt.println(len("Guilherme")) // 9

	my_string := "Potato"
	fmt.println(len(my_string)) // 6

	fmt.println(" Bell: \"\a\" \n Backspace: \'\b\' \n Escape: \e")
}
