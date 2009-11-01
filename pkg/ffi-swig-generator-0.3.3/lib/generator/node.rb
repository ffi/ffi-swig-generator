module FFI
  module Generator
    class Node
      attr_reader :symname
      def initialize(params = { })
        params = { :indent => 0 }.merge(params)
        @node, @indent = params[:node], params[:indent]
        @indent_str = ' ' * @indent
        @symname = get_attr('name')
      end
      def get_attr(name)
        if @node
          attr = (@node / "./attributelist/attribute[@name='#{name}']").first
          attr['value'] if attr
        end
      end
    end
  end
end
