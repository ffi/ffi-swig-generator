module FFI
  module Generator
    class Enum < Node
      def initialize(params = { })
        super
        eval_items
      end
      def to_s
        @items.sort { |i1, i2| i1[1] <=> i2[1] }.inject("") do |result, item|
          result << assignment_str(item[0], item[1]) << "\n"
        end
      end
      private
      def assignment_str(name, value)
        @indent_str + "#{name} = #{value}"
      end
      def eval_expr(expr)
        if expr.include?('+')
          (@items[expr[/\w+/]].to_i + 1).to_s
        else
          0.to_s
        end
      end
      def eval_items
        @items = {}
        get_items.each do |i|
          node = Node.new(:node => i)
          @items[node.get_attr('name')] = node.get_attr('enumvalueex') ? eval_expr(node.get_attr('enumvalueex')) : node.get_attr('enumvalue')
        end
        @items
      end
      def get_items
        @node / './enumitem'
      end
    end
  end
end
