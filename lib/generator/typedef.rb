module FFI
  module Generator
    class Typedef < Type
      attr_reader :type
      attr_reader :name
      def initialize(params = { })
        super
        @name = get_attr('sym_name')
        @type = Type.new(:node => @node, :typedefs => @typedefs)

        # Issue #30, if this is a pointer to an opaque struct, let's demote it
        # to a :pointer type
        if @type.to_s =~ /^(.*)\.ptr$/
          @type = ":pointer" unless @typedefs[$1]
        end
      end
      def to_s
        @indent_str + "typedef #{@type}, :#{@name}"
      end
      private
    end
  end
end
