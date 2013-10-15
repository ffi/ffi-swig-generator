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
				decl = @indent_str.dup
				if node.get_attr('name') # has a name
					decl << "#{node.get_attr('name')} = "
				end
				decl << "enum "
				if node.get_attr('sym_name') # has a typedef
					decl << ":#{node.get_attr('sym_name')}, "
				end
				decl << "[\n"

        # For some reason there exists an enum with only one value
        prefix = @items[0][:name].sub(/[^_]+$/, "") if @items.size == 1

        # determine the common prefix of all the enum names
        prefix ||= /\A(.*).*(\n\1.*)*\Z/.match(
            @items.map {|i| i[:name]}.join("\n"))[1]

				values = ''
				constants = ''
				@items.each do |item|
					constants << "#{@indent_str}#{item[:sym_name]} = #{item[:valueex]}\n"

          # convert the long name into a symbol by stripping the prefix
          # and prepending a colon.  Also handle the case of long names
          # that start with numbers
          sym = item[:name].sub(/^#{prefix}/, "").downcase
          sym = "'#{sym}'" if sym =~ /^[0-9]/
          line = "#{@indent_str}  :#{sym},"

          # If this entry in the enum has a known value, let's include
          # it here.  Keep in mind that the XML maintains the order of
          # the enum elements as they were in the file.
          line += " #{item[:value]}," if item[:value]
					values << line + "\n"
        end

				final = "#{@indent_str}]\n"

				decl + values + final + constants
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
					{
						:name => n.get_attr('name'),
						:value => n.get_attr('enumvalue'),
						:sym_name => n.get_attr('sym_name'),
						:valueex => n.get_attr('enumvalue') || n.get_attr('enumvalueex'),
					}
        end
      end
    end
  end
end
