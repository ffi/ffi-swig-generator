Feature: Generate FFI glue code from SWIG interface.

  In order to generate ffi glue code.
  As a developer of FFI bindings.
  I want the generator to produce code for me.

  Scenario: generate from an interface file
    Given we are in a project directory    
    And an interfaces directory exists
    And an interface file named 'interface.i' exists
    And a Rakefile exists
    When rake task 'ffi:generate' is invoked
    Then rake task 'ffi:generate' succeeded
    And the file 'interface_wrap.rb' is created
    And the file 'interface_wrap.rb' contains ffi glue code
    And the tmp directory is removed
