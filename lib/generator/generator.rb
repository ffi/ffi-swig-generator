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
      'size_t' => ':uint',
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
        @full_decl = params[:declaration] || get_full_decl
        @is_pointer = 0
      end
      def to_s
        ffi_type_from(@full_decl)
      end
      private
      def get_full_decl
        get_attr('decl').to_s + get_attr('type').to_s if @node
      end
      def decl
        get_attr('decl').to_s
      end
      def type
        get_attr('type').to_s
      end
      def is_native?
        Generator::TYPES.has_key?(@full_decl)
      end
      def is_pointer?
        (@is_pointer > 0 or @full_decl[/^p\./]) and not is_callback?
      end
      def is_enum?
        @full_decl[/^enum/]
      end
      def is_array?
        @full_decl and @full_decl[/\w+\(\d+\)/]
      end
      def is_struct?
        @full_decl[/^struct/]
      end
      def is_union?
        @full_decl[/^union/]
      end
      def is_constant?
        @full_decl[/^q\(const\)/]
      end
      def is_callback?
        @full_decl[/^p.f\(/]
      end
      def native
        ffi_type_from(Generator::TYPES[@full_decl]) if is_native?
      end
      def constant
        ffi_type_from(@full_decl.scan(/^q\(const\)\.(.+)/).flatten[0]) if is_constant?
      end
      def pointer
        if is_pointer?
          @is_pointer += 1
          if @full_decl.scan(/^p\.(.+)/).flatten[0]
            ffi_type_from(@full_decl.scan(/^p\.(.+)/).flatten[0])
          elsif @full_decl == 'char' and @is_pointer == 2
            ':string'
          else
            ':pointer'
          end
        end        
      end
      def array
        if is_array?
          num = @full_decl.scan(/\w+\((\d+)\)/).flatten[0]
          "[#{ffi_type_from(@full_decl.gsub!(/\w+\(\d+\)\./, ''))}, #{num}]"
        end
      end
      def struct
        @full_decl = Structure.camelcase(@full_decl.scan(/^struct\s(\w+)/).flatten[0]) if is_struct?
      end
      def union
        @full_decl = Union.camelcase(@full_decl.scan(/^union\s(\w+)/).flatten[0]) if is_union?
      end
      def enum
        ffi_type_from(Generator::TYPES['int']) if is_enum?
      end
      def callback
        Callback.new(:node => @node).to_s if is_callback?        
      end
      def typedef
        ffi_type_from(Generator.typedefs[@full_decl]) if Generator.typedefs.has_key?(@full_decl)
      end
      def ffi_type_from(full_decl)
        @full_decl = full_decl
        constant || typedef || pointer || enum || native || struct || union || array || callback || "#{full_decl}"
      end
    end
    class Typedef < Type
      attr_reader :symname, :full_decl
      def initialize(params = { })
        super
        @symname = get_attr('name')
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
          case get_attr('type')
          when 'void'
            nil
          when 'v(...)'
            ':varargs'
          else
            super
          end
        end
      end
      def initialize(params = { })
        super
        @type = get_attr('type')
      end
      def to_s
        params = get_params(@node).inject([]) do |array, node|
          array << Argument.new(:node => node).to_s
        end
        @indent_str + "attach_function :#{@symname}, [ #{params.join(', ')} ], #{get_rtype}"
      end
      private
      def get_params(node)
        parmlist = node / './attributelist/parmlist/parm'
      end
      def get_rtype
        pointer = get_attr('decl').scan(/^f\(.*\)\.(p)/).flatten[0]
        declaration = pointer ? "p.#{get_attr('type')}" : get_attr('type')
        Type.new(:declaration => declaration).to_s
      end
    end
    class Callback < Function
      def to_s
        @indent_str + "callback(:#{@symname}, [ #{get_params.join(', ')} ], #{get_rtype})"
      end
      private
      def get_params
        params = (@node / './attributelist/parmlist/parm')
        declaration = decl
        unless params.empty?
          result = params.inject([]) do |array, node|
            declaration.gsub!(/#{Regexp.escape(Type.new(:node => node).get_attr('type'))}/, '')
            array << Argument.new(:node => node).to_s
          end
        else
          result = @full_decl.scan(/p.f\((.*)\)/).flatten[0].split(',').inject([]) do |array, type|
            array << (type == 'void' ? '' : Type.new(:declaration => type).to_s)
          end
        end
        @full_decl = declaration + type
        result
      end
      def get_rtype
        Type.new(:declaration => @full_decl.scan(/\)\.(.+)/).flatten[0]).to_s
      end
    end
    class Parser
      @indent = 2
      class << self
        def get_attr(node, name)
          nodes = (node / "./attributelist/attribute[@name='#{name}']")
          nodes.first['value'] if nodes.first
        end
        def get_verbatim(node)
          get_attr(node, 'code')
        end
        def is_insert_runtime?(node)
          get_attr(node, 'section') == 'runtime'
        end
        def is_constant?(node)
          node.name == 'constant'
        end
        def is_enum?(node)
          node.name == 'enum'
        end
        def is_function_decl?(node)
          node.name == 'cdecl' and get_attr(node, 'kind') == 'function'
        end
        def is_struct?(node)
          node.name == 'class' and get_attr(node, 'kind') == 'struct'
        end
        def is_union?(node)
          node.name == 'class' and get_attr(node, 'kind') == 'union'
        end        
        def is_typedef?(node)
          node.name == 'cdecl' and get_attr(node, 'kind') == 'typedef'
        end
        def is_callback?(node)
          get_attr(node, 'decl') =~ /^p\.f\(/
        end
        def generate(node)
          result = ""
          node.traverse do |node|
            if is_constant?(node)
              result << Constant.new(:node => node, :indent => @indent).to_s << "\n"
            elsif is_typedef?(node)
              typedef = Typedef.new(:node => node)
              Generator.add_type(typedef.symname, typedef.full_decl)
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
