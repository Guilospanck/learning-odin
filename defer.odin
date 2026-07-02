package main

import "core:fmt"
import "core:os"

// this will print 4 and then 234
simple_defer :: proc(){
    x := 123

    defer fmt.println(x)

    {
	defer x = 4
	x = 2
    }

    fmt.println(x)

    x = 234
}

entire_block_defer :: proc(){
    y := false

    defer {
	fmt.println("A")
	fmt.println("B")
    }

    // this is equivalent to `defer { if y {...} }`
    defer if y {
	fmt.println("y is true")
    }
}

// this will print 1 2 3
defers_are_reverse_order :: proc(){
    defer fmt.println("3")
    defer fmt.println("2")
    defer fmt.println("1")
}

real_life_scenario :: proc(){
    f, err := os.open("my_file.txt", {.Read})
    if err != os.ERROR_NONE {
	fmt.println("Oh sheeeit")
	return
    }

    defer {
	fmt.println("Closing file...")
	os.close(f)
    }

    data, err2 := os.read_entire_file_from_file(f, context.temp_allocator)
    defer {
	fmt.println("Freeing temp_allocator...")
	free_all(context.temp_allocator)
    }

    if err2 != os.ERROR_NONE {
	fmt.println("could not read file from file")
	return
    }

    fmt.printfln("%s",data)
}

/*

  NOTE: the `defer` in odin is different from Golang.
  In odin, it is scope-based. In Golang it is function-exit based.

  Examples:

  ```go
  func f() {
	{
	    defer fmt.Println("A")
	    fmt.Println("inside")
	}

	fmt.Println("after block")
  } 
  ```
  will print: 
	- inside
	- after block
	- A

   
   ```odin
   proc f() {
	{
	    defer fmt.println("A")
	    fmt.println("inside")
	}

	fmt.println("after block")
   }
   ```

   will print:
	- inside
	- A
	- after block

*/
main :: proc() {
    simple_defer()
    entire_block_defer()
    defers_are_reverse_order()
    real_life_scenario()
}
