Feature: Generate FFI glue code from SWIG interface.

  In order to generate ffi glue code.
  As a ffi bindings developer.
  I want the generator to generate code for me.

  Scenario: generate from an interface file
    Given an interfaces directory
    And an interface file named 'interface.i'
    When rake task 'ffi:generate' is invoked
    Then rake task 'ffi:generate' succeeded
    And the file 'interface_wrap.rb' is created
    And the file 'interface_wrap.rb' contains ffi glue code
