package packages1

import "core:fmt"

my_public_variable: int

// cannot be accessed outside of this package.
@(private) // equivalent to @(private="package")
my_package_private_variable: int

// cannot be accessed outside of this file.
@(private="file")
my_file_private_variable: int

potato :: proc() {
    fmt.println("I'm potato from packages_1")
}
