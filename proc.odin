package main

import "core:fmt"
import "core:math"

fibonacci :: proc(nth: int) -> int {
  switch {
  case nth < 1:
    return 0
  case nth == 1:
    return 1
  }

  return fibonacci(nth - 1) + fibonacci(nth - 2)
}

// parameters are immutable
param_are_immutable :: proc(x, y: int) {
  // x = 1 // ERROR: cannot assign to `x` which is a proc parameter

  fmt.println(x, y)
}

// if you want to mutate the parameter locally (i.e. keeping the function pure),
// then you can shadow it
shadowing_parameter :: proc(x: int) {
  x := x

  x = 2

  fmt.printfln("Local 'x' value is %d", x) // 2
}

// passing a pointer value makes a COPY OF THE POINTER, not the data it points to
// mutating the value the pointer points to, will mutate the value (durrrr)
pointers_as_param :: proc(y: ^int) {
  y^ = 2
}

// note how we defined the return parameter in the procedure call and it already
// returns it automatically
variadic_params :: proc(nums: ..int) -> (result: int) {
  for n in nums {
    result += n
  }

  return
}

multiple_results :: proc(x, y: int) -> (int, int) {
  return y, x
}

named_results :: proc(input: int) -> (x, y: int) {
  x = input * 2
  y = input * 3

  return x, y
  // you could also just `return` (called a "naked" return)
  // but that can contribute to a worse reading clarity
}

// we can also have default results
default_results :: proc(default: bool) -> (y := 8) {
  if default {
    return y
  }

  y = 2
  return y
}

named_arguments :: proc(title: string, x: int = 11, y: int, name: string) {
  fmt.printfln("title: %s, x: %d, y: %d, name: %s", title, x, y, name)
}

/* Explicit overloading */

area_rect :: proc(a, b: f32) -> f32 {
  return a * b
}

area_circle :: proc(r: f32) -> f32 {
  return math.PI * math.pow(r, 2)
}

area :: proc {
  area_rect,
  area_circle,
}

/* -- Explicit overloading -- */

main :: proc() {
  fib_res := fibonacci(7)
  fmt.println(fib_res) // 13

  param_are_immutable(2, 3)

  fmt.println("POINTERS")

  y := 4
  pointers_as_param(&y)
  fmt.println(y) // 2, mutable because of the procedure above

  fmt.println("SHADOWING")

  x := 8
  shadowing_parameter(x)
  fmt.println(x) // 8, the shadowing function did not change the x's underlying value

  fmt.println("VARIADIC")

  variadic_one_res := variadic_params(1, 1, 1, 1)
  fmt.println(variadic_one_res) // 4
  fmt.println(variadic_params()) // 0
  fmt.println(variadic_params(3)) // 3

  my_slice := []int{2, 2, 2}
  variadic_two_res := variadic_params(..my_slice)
  fmt.println(variadic_two_res) // 6

  a := 1
  b := 2
  res1, res2 := multiple_results(a, b)
  fmt.println(res1, res2) // 2, 1

  named_result_res_one, named_result_res_two := named_results(3)
  fmt.println(named_result_res_one, named_result_res_two) // 6, 9

  fmt.println(default_results(true)) // 8
  fmt.println(default_results(false)) // 2

  named_arguments(x = 8, name = "Guilherme", y = 2, title = "Potato")
  // This is not allowed because you cannot use positional arguments AFTER
  // named arguments
  //
  // named_arguments(x = 8, name = "Guilherme", y, title = "Potato")

  // but you can use positional arguments AND THEN named arguments
  named_arguments("my_title", 3, name = "Larry", y = 2)

  // using the default values
  // in this case, as x has a default value of 11 and we didn't mention it anywhere
  // in the parameters, its value will be 11.
  named_arguments("my_title", name = "Larry", y = 2)

  // Explicit overloading
  rect := area(10, 20)
  circle := area(5)

  // or

  rect2 := area_rect(10, 20)
  circle2 := area_circle(5)

  // Area of rect is: 200.000
  // Area of circle is 78.540
  fmt.printfln("Area of rect is: %f\nArea of circle is %f", rect, circle)

  assert(math.abs(rect - rect2) <= 1e-6)
  assert(math.abs(circle - circle2) <= 1e-6)
}

