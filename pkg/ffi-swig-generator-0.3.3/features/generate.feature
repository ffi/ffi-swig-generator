Feature: Generate FFI glue code from SWIG interface.

  In order to generate ruby-ffi glue code.
  As a developer of ruby-ffi bindings.
  I want the generator to automagically produce code for me.

  Scenario: Generate code using default configuration
    Given we are in a project directory
    And the project directory is configured for the 'Scenario1'
    When rake task 'ffi:generate' is invoked
    Then rake task 'ffi:generate' succeeded
    And the file 'generated/interface_wrap.rb' is created
    And the file 'generated/interface_wrap.xml' is created
    And the file 'generated/interface_wrap.rb' contains ffi glue code
    And the tmp directory is removed

  Scenario: Generate code using a configuration hash
    Given we are in a project directory
    And the project directory is configured for the 'Scenario2'
    When rake task 'ffi:generate' is invoked
    Then rake task 'ffi:generate' succeeded
    And the file 'generated/interface_wrap.rb' is created
    And the file 'generated/interface_wrap.xml' is created
    And the file 'generated/interface_wrap.rb' contains ffi glue code
    And the tmp directory is removed

  Scenario: Generate code using a configuration block
    Given we are in a project directory
    And the project directory is configured for the 'Scenario3'
    When rake task 'ffi:generate' is invoked
    Then rake task 'ffi:generate' succeeded
    And the file 'generated/interface_wrap.rb' is created
    And the file 'generated/interface_wrap.xml' is created
    And the file 'generated/interface_wrap.rb' contains ffi glue code
    And the tmp directory is removed

  Scenario: Generate code using a configuration file
    Given we are in a project directory
    And the project directory is configured for the 'Scenario4'
    When rake task 'ffi:generate' is invoked
    Then rake task 'ffi:generate' succeeded
    And the file 'generated/interface_wrap.rb' is created
    And the file 'generated/interface_wrap.xml' is created
    And the file 'generated/interface_wrap.rb' contains ffi glue code
    And the tmp directory is removed
