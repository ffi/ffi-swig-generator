module FFI
  module Generator
    class Constant < Node
      def initialize(params = { })
        super
        @name, @value = get_attr('sym_name'), get_attr('value')
      end
      def to_s
        @indent_str + "#{@name} = #{sanitize!(@value)}"        
      end
      private
      def sanitize!(value)
        const_regex = /(0x)?[0-9a-f]+/
        if @value.match(/#{const_regex}U$/) or @value.match(/#{const_regex}L$/)
          result = value.chop
        elsif @value.match(/#{const_regex}UL$/)
          result = @value.chop.chop
        else
          result = @value
        end
      end
    end
  end
end
