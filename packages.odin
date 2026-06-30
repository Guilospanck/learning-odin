// A package is a DIRECTORY of odin files.
// Each odin file in the same directory MUST have
// the SAME package name.
package main

// Imports have usually a prefix ("core:"). If no prefix is present, the import
// will look relative to the current file
import mypackage "_packages"

// we can do this to reference the package by a different name
import foo "core:fmt"


main :: proc() {
    foo.println("HELLO")

    // ALL declarations in a package are PUBLIC BY DEFAULT
    mypackage.potato()

    foo.println(mypackage.my_public_variable)

    // This will not work because the var is private
    // foo.println(mypackage.my_package_private_variable)
}
