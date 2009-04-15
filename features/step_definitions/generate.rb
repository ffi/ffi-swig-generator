Given /^we are in a project directory$/ do
  FileUtils.mkdir_p('tmp')
  Dir.chdir('tmp')
end

Given /^an interfaces directory exists$/ do
  FileUtils.mkdir_p('interfaces')
end

Given /^an interface file named 'interface\.i' exists$/ do
  File.open('interfaces/interface.i', 'w') do |file|
    file << interface_template
  end
end

Given /^a Rakefile exists$/ do
  File.open('Rakefile', 'w') do |file|
    file << rakefile_template
  end  
end

When /^rake task 'ffi:generate' is invoked$/ do
  @output = `rake ffi:generate 2>&1`
  @result = $?.success?
end

Then /^rake task 'ffi:generate' succeeded$/ do
  @result.should be_true
end

Then /^the file 'interface_wrap\.rb' is created$/ do
  File.exists?('generated/interface_wrap.rb').should be_true
end

Then /^the file 'interface_wrap\.rb' contains ffi glue code$/ do
  File.read('generated/interface_wrap.rb').should == interface_wrap_result
end

Then /^the tmp directory is removed$/ do
  Dir.chdir('..')
  FileUtils.rm_rf 'tmp'
  File.exists?('tmp').should be_false
end
