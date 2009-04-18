module FFI
  module Generator
    require libpath('generator/node')
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
        if @value.match(/\d+U$/) or @value.match(/\d+L$/)
          result = value.chop
        elsif @value.match(/\d+UL$/)
          result = @value.chop.chop
        else
          result = @value
        end
      end
    end
  end
end
