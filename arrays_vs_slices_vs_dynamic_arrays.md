## Dynamic Arrays

```odin
my_dynamic_array := [dynamic]{1, 2, 3}

// append one value
append(&my_dynamic_array, 123)

// append multiple values
append(&my_dynamic_array, 11, 22, 33)

// can also append slices
some_slice := []int{20, 30}
append(&my_dynamic_array, ..some_slice[:])
```

- basically an ArrayList;
- it owns memory;
- they area allocated using the current `context`'s allocator;
- the memory usually needs to be freed;
- they have `len` and `cap`;
- it can change size, although that might be expensive when it happens.

## Arrays

```odin
my_array := [3]{1, 2, 3} 
// or
my_array := [?]{1, 2, 3} 
```

- cannot change size;
- ows memory.

## Slices

```odin
my_slice: []int = my_array[1:2] // [2]

// or you can also initiate a slice literal, which will create an array and then
// a slice that references it.
my_slice := []int{1, 2, 3}
```

- just a view into a piece of memory;
- does not own the memory;
- cheap to pass from one function call to another;
- the ZERO value of a slice is `nil`;
- just a pointer and a length.

## Common patterns:

- Use a dynamic array while building or collecting data.
- Pass it to functions as a slice.
- Use arrays only when the size is inherently fixed.
