## Dynamic Arrays

- basically an ArrayList;
- it owns memory;
- the memory usually needs to be freed;
- it can change size, although that might be expensive when it happens.

## Arrays

- cannot change size;
- ows memory.

## Slices

- just a view into a piece of memory;
- does not own the memory;
- cheap to pass from one function call to another;
- just a pointer and a length.

## Common patterns:

- Use a dynamic array while building or collecting data.
- Pass it to functions as a slice.
- Use arrays only when the size is inherently fixed.
