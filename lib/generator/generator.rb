require 'rubygems'
require 'nokogiri'

module FFI
  module Generator
    @typedefs = {}
    TYPES = { 
      'char' => ':char',
      'double' => ':double',
      'float' => ':float',
      'unsigned long' => ':ulong',
      'unsigned char' => ':uchar',
      'signed char' => ':char',
      'unsigned char' => ':uchar',
      'short' => ':short',
      'signed short'     => ':short',
      'signed short int' => ':short',
      'unsigned short'     => ':ushort',
      'unsigned short int' => ':ushort',
      'int' => ':int',
      'signed int' => ':int',
      'unsigned int' => ':uint',
      'long' => ':long',
      'long int' => ':long',
      'signed long' => ':long',
      'signed long int' => ':long',
      'unsigned long' => ':ulong',
      'unsigned long int' => ':ulong',
      'long unsigned int' => ':ulong',
      'long long'     => ':long_long',
      'long long int' => ':long_long',
      'signed long long'     => ':long_long',
      'signed long long int' => ':long_long',
      'unsigned long long'     => ':ulong_long',
      'unsigned long long int' => ':ulong_long',
      'void' => ':void'
    }     
    class << self
      attr_reader :typedefs
      def add_type(ctype, rtype)
        @typedefs[ctype] = rtype
      end
    end
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
    class Type < Node
      def initialize(params = { })
        super
        @statement = params[:statement] || get_statement
        @is_pointer = 0
      end
      def to_s
        get_type
      end
      private
      def get_statement
        get_attr('decl').to_s + get_attr('type').to_s if @node
      end
      def is_native?
        Generator::TYPES.has_key?(@statement)
      end
      def is_pointer?
        (@is_pointer > 0 or @statement[/^p\./]) and not is_callback?
      end
      def is_enum?
        @statement[/^enum/]
      end
      def is_array?
        @statement and @statement[/\w+\(\d+\)/]
      end
      def is_struct?
        @statement[/^struct/]
      end
      def is_union?
        @statement[/^union/]
      end
      def is_constant?
        @statement[/^q\(const\)/]
      end
      def is_callback?
        @statement[/^p.f\(/]
      end
      def native
        if is_native?
          @statement = Generator::TYPES[@statement] 
          get_type
        end
      end
      def constant
        if is_constant?
          @statement = @statement.scan(/^q\(const\)\.(.+)/).flatten[0]
          get_type 
        end
      end
      def pointer
        if is_pointer?
          @is_pointer += 1
          if @statement.scan(/^p\.(.+)/).flatten[0]
            @statement = @statement.scan(/^p\.(.+)/).flatten[0]
            get_type
          elsif @statement == 'char' and @is_pointer == 2
            ':string'
          else
            ':pointer'
          end
        end        
      end
      def array
        if is_array?
          num = @statement.scan(/\w+\((\d+)\)/).flatten[0]
          @statement.gsub!(/\w+\(\d+\)\./, '')
          "[#{get_type}, #{num}]"
        end
      end
      def struct
        if is_struct?
          @statement = Structure.camelcase(@statement.scan(/^struct\s(\w+)/).flatten[0])
          get_type
        end
      end
      def union
        if is_union?
          @statement = Union.camelcase(@statement.scan(/^union\s(\w+)/).flatten[0])
          get_type
        end
      end
      def enum
        if is_enum?
          @statement = Generator::TYPES['int']
          get_type
        end
      end
      def callback
        Callback.new(:node => @node).to_s if is_callback?        
      end
      def typedef
        if Generator.typedefs.has_key?(@statement)
          @statement = Generator.typedefs[@statement]
          get_type
        end
      end
      def get_type
        constant || typedef || pointer || enum || native || struct || union || array || callback || "#{@statement}"
      end
    end
    class Typedef < Type
      attr_reader :symname, :statement
      def initialize(params = { })
        super
        @symname = get_attr('name')
        # @type = is_pointer? ? ':pointer' : get_attr('type')
        # p @statement
      end
    end
    class Constant < Node
      def initialize(params = { })
        super
        @name, @value = get_attr('sym_name'), get_attr('value')
      end
      def to_s
        @indent_str + "#{@name} = #{@value}"        
      end
    end
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
    class Structure < Node
      def self.camelcase(name)
        name.gsub(/^\w|\_\w/) { |c| c.upcase }.delete('_')
      end
      def initialize(params = { })
        super
        @name = self.class.camelcase(@symname)
      end
      def to_s
        fields_str = fields.inject("") do |str, f|
          str << @indent_str + ' ' * 9 << f.join(', ') << ",\n"
        end
        code = klass_string + @indent_str + "  layout(\n" + fields_str.chomp.chomp(',') + "\n" + @indent_str + "  )\n" + @indent_str + "end\n"
      end
      private
      def klass_string
        @indent_str + "class #{@name} < FFI::Struct\n"
      end
      def fields
        (@node / 'cdecl').inject([]) do |array, field|
          array << [":#{Node.new(:node => field).symname}", "#{Type.new(:node => field)}"]
        end
      end
    end
    class Union < Structure
      private
      def klass_string
        @indent_str + "class #{@name} < FFI::Union\n"
      end
    end
    class Function < Type
      class Argument < Type
        def to_s
          get_attr('type') == 'void' ? nil : super
        end
      end
      def initialize(params = { })
        super
        @type = get_attr('type')
      end
      def to_s
        params = get_params(@node).inject([]) do |array, node|
          array << Argument.new(:node => node).to_s
        end.collect { |p| "#{p}" }
        @indent_str + "attach_function :#{@symname}, [ #{params.join(', ')} ], #{get_rtype}"
      end
      private
      def get_params(node)
        parmlist = node / './attributelist/parmlist/parm'
      end
      def get_rtype
        pointer = get_attr('decl').scan(/^f\(.*\)\.(p)/).flatten[0]
        statement = pointer ? "p.#{get_attr('type')}" : get_attr('type')
        Type.new(:statement => statement).to_s
      end
    end
    class Callback < Type
      def to_s
        params = get_params.inject([]) do |array, type|
          array << (type == 'void' ? '' : Type.new(:statement => type).to_s)
        end
        @indent_str + "callback(:#{@symname}, [ #{params.join(', ')} ], #{get_rtype})"
      end
      private
      def get_params
        @statement.scan(/p.f\((.*)\)/).flatten[0].split(',')
      end
      def get_rtype
        Type.new(:statement => @statement.scan(/\)\.(\w+)/).flatten[0]).to_s
      end
    end
    class Parser
      @indent = 2
      class << self
        def get_verbatim(node)
          node.xpath("./attributelist/attribute[@name='code']").first['value']
        end
        def is_insert_runtime?(node)
          section = node.xpath("./attributelist/attribute[@name='section']")
          section.first['value'] == 'runtime' if section.first
        end
        def is_constant?(node)
          node.name == 'constant'
        end
        def is_enum?(node)
          node.name == 'enum'
        end
        def is_function_decl?(node)
          node.name == 'cdecl' and (node / "./attributelist/attribute[@name='kind']").first['value'] == 'function'
        end
        def is_struct?(node)
          node.name == 'class' and (node / "./attributelist/attribute[@name='kind']").first['value'] == 'struct'
        end
        def is_union?(node)
          node.name == 'class' and (node / "./attributelist/attribute[@name='kind']").first['value'] == 'union'
        end        
        def is_typedef?(node)
          node.name == 'cdecl' and (node / "./attributelist/attribute[@name='kind']").first['value'] == 'typedef'
        end
        def is_callback?(node)
          (node / "./attributelist/attribute[@name='decl']").first['value'] =~ /^p\.f\(/
        end
        def generate(node)
          result = ""
          node.traverse do |node|
            if is_constant?(node)
              result << Constant.new(:node => node, :indent => @indent).to_s << "\n"
            elsif is_typedef?(node)
              typedef = Typedef.new(:node => node)
              Generator.add_type(typedef.symname, typedef.statement)
              if is_callback?(node)
                cb = Callback.new(:node => node, :indent => @indent).to_s << "\n"
                Generator.add_type(typedef.symname, ":#{typedef.symname}")
                result << cb.to_s
              end
            elsif is_enum?(node)
              e = Enum.new(:node => node, :indent => @indent)
              Generator.add_type(e.symname, Generator::TYPES['int'])
              result << e.to_s << "\n"
            elsif is_struct?(node)
              s = Structure.new(:node => node, :indent => @indent)
              Generator.add_type(s.symname, "struct #{s.symname}")
              result << s.to_s
            elsif is_union?(node)
              s = Union.new(:node => node, :indent => @indent)
              Generator.add_type(s.symname, "union #{s.symname}")
              result << s.to_s
            elsif is_function_decl?(node)
              result << Function.new(:node => node, :indent => @indent).to_s << "\n"
            elsif node.name == 'insert' and not is_insert_runtime?(node)
              result << get_verbatim(node)
            end       
          end
          result
        end
      end
    end
  end
end

