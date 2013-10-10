module FFI
  module Generator
    class Enum < Node
      def initialize(params = { })
        super
        eval_items
      end
      def to_s
        node = Node.new(:node => @node)

        # start off the declaration of the enum
        decl = "#{@indent_str}#{node.get_attr('sym_name')} = enum "

        # For some reason there exists an enum with only one value
        prefix = @items[0][0].sub(/[^_]+$/, "") if @items.size == 1

        # determine the common prefix of all the enum names
        prefix ||= /\A(.*).*(\n\1.*)*\Z/.match(
            @items.map {|a,b| a}.join("\n"))[1]

        decl + @items.map do |name,val|
          # convert the long name into a symbol by stripping the prefix
          # and prepending a colon.  Also handle the case of long names
          # that start with numbers
          sym = name.sub(/^#{prefix}/, "").downcase
          sym = "'#{sym}'" if sym =~ /^[0-9]/
          line = ":#{sym}"

          # If this entry in the enum has a known value, let's include
          # it here.  Keep in mind that the XML maintains the order of
          # the enum elements as they were in the file.
          line += ", #{val}" if val
          line
        end.join(",\n#{" " * decl.size}") + "\n"
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
        @items ||= (@node / "./enumitem").map do |x|
          n = Node.new(:node => x)
          [n.get_attr('name'), n.get_attr('enumvalue')]
        end
      end
    end
  end
end
