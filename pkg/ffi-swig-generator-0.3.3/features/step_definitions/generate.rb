Given /^we are in a project directory$/ do
  FileUtils.mkdir_p('tmp')
  Dir.chdir('tmp')
end

Given /^the project directory is configured for the '(.+)'$/ do |mod|
  @scenario = eval(mod)
  @scenario.generate
end

When /^rake task 'ffi:generate' is invoked$/ do
  @output = `rake ffi:generate 2>&1`
  @result = $?.success?
end

Then /^rake task 'ffi:generate' succeeded$/ do
  @result.should be_true
end

Then /^the file '(.+)' is created/ do |fn|
  File.exists?(fn).should be_true
end

Then /^the file '(.+)' contains ffi glue code$/ do |fn|
  File.read(fn).should == @scenario.result_template
end

Then /^the tmp directory is removed$/ do
  Dir.chdir('..')
  FileUtils.rm_rf 'tmp'
  File.exists?('tmp').should be_false
end
