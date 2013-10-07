module FFI
  module Generator
    class Constant < Node
      def initialize(params = { })
        super
        @name, @value, @type = get_attr('sym_name'), get_attr('value'), get_attr('type')
      end
      def to_s
        @indent_str + "#{@name} = #{sanitize!(@value)}"        
      end
      private
      def sanitize!(value)
        result = nil
        case @type
        when 'double', 'float'
          result = @value.sub(/f$/, '')
        when 'p.char'
          result = "'#{@value}'"
        else
          const_regex = /(0x)?[0-9a-f]+/
          if @value.match(/#{const_regex}U$/) or @value.match(/#{const_regex}L$/)
            result = value.chop
          elsif @value.match(/#{const_regex}UL$/)
            result = @value.chop.chop
          else
            result = @value
          end
        end
        result
      end
    end
  end
end
