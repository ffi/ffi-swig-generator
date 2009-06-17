module FFI
  module Generator
    class Struct < Type
      def self.string_accessors(field_name, indent = 0)
        result = <<-code
def #{field_name}=(str)
  @#{field_name} = FFI::MemoryPointer.from_string(str)
  self[:#{field_name}] = @#{field_name}
end
def #{field_name}
  @#{field_name}.get_string(0)
end
code
      result.split("\n").map { |line| ' ' * indent + line }.join("\n") << "\n"
      end
      def self.callback_accessors(field_name, indent = 0)
        result = <<-code
def #{field_name}=(cb)
  @#{field_name} = cb
  self[:#{field_name}] = @#{field_name}
end
def #{field_name}
  @#{field_name}
end
code
      result.split("\n").collect { |line| ' ' * indent + line }.join("\n") << "\n"
      end
      def self.camelcase(name)
        name.gsub(/^_?\w|\_\w/) { |c| c.upcase }.delete('_')
      end
      def initialize(params = { })
        super
        @name = self.class.camelcase(@symname)
      end
      def to_s
        fields_str = fields.inject("") do |str, f|
          str << @indent_str + ' ' * 9 << f.join(', ') << ",\n"
        end
        code = klass_string + @indent_str + "  layout(\n" + fields_str.chomp.chomp(',') + "\n" + @indent_str + "  )\n" + accessors + @indent_str + "end\n"
      end
      private
      def klass_string
        @indent_str + "class #{@name} < FFI::Struct\n"
      end
      def fields
        (@node / 'cdecl').inject([]) do |array, field|
          type_node = Type.new(:node => field, :typedefs => @typedefs).to_s
          type = type_node.to_s
          array << [":#{Node.new(:node => field).symname}", type == ':string' ? ':pointer' : type]
        end
      end
      def accessors
        result = ""
        fields = (@node / 'cdecl').map do |field|
          [Node.new(:node => field).symname, "#{Type.new(:node => field, :typedefs => @typedefs)}"]
        end
        fields.each do |field|
          if field[1] == ':string'
            result << self.class.string_accessors(field[0], @indent + 2)
          elsif field[1] =~ /^callback/ or @typedefs[field[1].delete(':')] =~ /^callback/
            result << self.class.callback_accessors(field[0], @indent + 2)
          end
        end
        result += "\n" unless result.empty?
        result
      end
    end
    class Union < FFI::Generator::Struct
      private
      def klass_string
        @indent_str + "class #{@name} < FFI::Union\n"
      end
    end
  end
end
