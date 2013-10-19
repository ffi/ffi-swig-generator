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
					result = @value.sub(/^(-?(?:0x[0-9a-f]+|[0-9]+))U?L*$/i, '\1')
        end
        result
      end
    end
  end
end
