require 'rubygems'
require 'nokogiri'

module FFI
  module Generator
    NestedStructureNotSupported =<<EOM
Nested structures are not correctly supported at the moment.
Please check the order of the declarations in the structure below.
EOM
    @typedefs = {}
    @nested_type = {}
    @nested_structure = {}
    @ignored = []
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
      attr_reader :typedefs, :nested_type, :nested_structure, :ignored
      attr_reader :messages
      def add_type(ctype, rtype)
        @typedefs[ctype] = rtype
      end
      def add_nested_structure(symname, id)
        (Generator.nested_structure[Generator.nested_type[symname]] ||= []) << id
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
      class Declaration
        def initialize(declaration)
          @full_decl = declaration
        end
        def is_native?
          Generator::TYPES.has_key?(@full_decl)
        end
        def is_pointer?
          @full_decl[/^p\./] and not is_inline_callback?
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
        def is_volatile?
          @full_decl[/^q\(volatile\)/]
        end
        def is_callback?
          @full_decl[/^callback/]
        end
        def is_inline_callback?
          @full_decl[/^p.f\(/]
        end
      end
      def initialize(params = { })
        super
        @full_decl = params[:declaration] || get_full_decl
        @declaration = Declaration.new(@full_decl)
        @is_pointer = 0
        Generator.nested_type[get_attr('type')] = get_attr('nested') if is_nested_type? 
      end
      def is_nested_type?
        get_attr('nested')
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
      def native
        ffi_type_from(Generator::TYPES[@full_decl]) if @declaration.is_native?
      end
      def constant
        ffi_type_from(@full_decl.scan(/^q\(const\)\.(.+)/).flatten[0]) if @declaration.is_constant?
      end
      def volatile
        ffi_type_from(@full_decl.scan(/^q\(volatile\)\.(.+)/).flatten[0]) if @declaration.is_volatile?
      end
      def pointer
        if @declaration.is_pointer? or @is_pointer > 0
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
        if @declaration.is_array?
          num = @full_decl.scan(/\w+\((\d+)\)/).flatten[0]
          "[#{ffi_type_from(@full_decl.gsub!(/\w+\(\d+\)\./, ''))}, #{num}]"
        end
      end
      def struct
        Structure.camelcase(@full_decl.scan(/^struct\s(\w+)/).flatten[0]) if @declaration.is_struct?
      end
      def union
        Union.camelcase(@full_decl.scan(/^union\s(\w+)/).flatten[0]) if @declaration.is_union?
      end
      def enum
        ffi_type_from(Generator::TYPES['int']) if @declaration.is_enum?
      end
      def callback
        ":#{@full_decl.scan(/^callback\s(\w+)/).flatten[0]}" if @declaration.is_callback?
      end
      def inline_callback
        Callback.new(:node => @node, :inline => true).to_s if @declaration.is_inline_callback?        
      end
      def typedef
        ffi_type_from(Generator.typedefs[@full_decl]) if Generator.typedefs.has_key?(@full_decl)
      end
      def undefined(type)
        "#{type}"
      end
      def ffi_type_from(full_decl)
        @full_decl = full_decl
        @declaration = Declaration.new(full_decl)
        constant             || \
        volatile             || \
        typedef              || \
        pointer              || \
        enum                 || \
        native               || \
        struct               || \
        union                || \
        array                || \
        inline_callback      || \
        callback             || \
        undefined(full_decl)
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
      def self.string_setter_getter(field_name, indent = 0)
        result = <<-code
def #{field_name}=(str)
  @#{field_name} = FFI::MemoryPointer.from_string(str)
  self[:#{field_name}] = @#{field_name}
end
def #{field_name}
  @#{field_name}.get_string(0)
end
code
      result.map { |line| ' ' * indent + line }.join
      end
      def self.callback_setter_getter(field_name, indent = 0)
        result = <<-code
def #{field_name}=(cb)
  @#{field_name} = cb
  self[:#{field_name}] = @#{field_name}
end
def #{field_name}
  @#{field_name}
end
code
      result.map { |line| ' ' * indent + line }.join
      end
      def self.camelcase(name)
        name.gsub(/^_?\w|\_\w/) { |c| c.upcase }.delete('_')
      end
      def initialize(params = { })
        super
        @name = self.class.camelcase(@symname)
      end
      def to_s
        fields_str = fields.inject("") do |str, f|
          str << @indent_str + ' ' * 9 << f.join(', ') << ",\n"
        end
        code = klass_string + @indent_str + "  layout(\n" + fields_str.chomp.chomp(',') + "\n" + @indent_str + "  )\n" + accessors + @indent_str + "end\n"
      end
      private
      def klass_string
        @indent_str + "class #{@name} < FFI::Struct\n"
      end
      def fields
        (@node / 'cdecl').inject([]) do |array, field|
          type_node = Type.new(:node => field).to_s
          type = type_node.to_s
          array << [":#{Node.new(:node => field).symname}", type == ':string' ? ':pointer' : type]
        end
      end
      def accessors
        result = ""
        fields = (@node / 'cdecl').map do |field|
          [Node.new(:node => field).symname, "#{Type.new(:node => field)}"]
        end
        fields.each do |field|
          if field[1] == ':string'
            result << self.class.string_setter_getter(field[0], @indent + 2)
          elsif field[1] =~ /^callback/ or Generator.typedefs[field[1].delete(':')] =~ /^callback/
            result << self.class.callback_setter_getter(field[0], @indent + 2)
          end
        end
        result += "\n" unless result.empty?
        result
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
      def initialize(params = { })
        super(params)
        @inline = true if params[:inline] == true
      end
      def to_s
        unless @inline
          @indent_str + "callback(:#{@symname}, [ #{get_params.join(', ')} ], #{get_rtype})"
        else
          @indent_str + "callback([ #{get_params.join(', ')} ], #{get_rtype})"
        end
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
        def get_id(node)
          node.id
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
        def find_nested_struct(node, id)
          result = ""
          nested_node = (node.parent / "class[@id='#{id}']").first
          if Generator.nested_structure.has_key?(get_attr(nested_node, 'name'))
            Generator.nested_structure[get_attr(nested_node, 'name')].reverse.each do |id|
              result << find_nested_struct(nested_node, id)
            end
          end
          if nested_node
            if get_attr(nested_node, 'kind') == 'struct'
              s = Structure.new(:node => nested_node, :indent => @indent)
              result << (Generator.nested_structure.has_key?(s.symname) ? fixme(s.to_s, NestedStructureNotSupported) : s.to_s)
            else
              u = Union.new(:node => nested_node, :indent => @indent)
              result << (Generator.nested_structure.has_key?(u.symname) ? fixme(u.to_s, NestedStructureNotSupported) : u.to_s)
            end
          end
          result
        end
        def fixme(code, message)
          message = comment('FIXME: ' + message)
          message << comment(code)
        end
        def comment(code)
          code.split(/\n/).map { |line| "# #{line}" }.join("\n") << "\n"
        end
        def has_nested_structures?(node, symname)
          Generator.nested_structure[symname] and not Generator.nested_structure[symname].empty?
        end
        def prepend_nested_structures(node, symname)
          result = ""
          if has_nested_structures?(node, symname)
            result = Generator.nested_structure[symname].reverse.inject("") do |result, nested_id|
              result << find_nested_struct(node, nested_id)
            end
            Generator.nested_structure[symname].clear
          end
          result          
        end
        def handle_nested_structure(node, symname)
          if Generator.nested_type[symname]
            Generator.add_nested_structure(symname, node.attributes['id'])
            Generator.ignored << node.attributes['id']
          end
          prepend_nested_structures(node, symname)
        end
        def pass(node)
          result = ""
          node.traverse do |node|
            if is_constant?(node)
              result << Constant.new(:node => node, :indent => @indent).to_s << "\n"
            elsif is_typedef?(node)
              typedef = Typedef.new(:node => node)
              Generator.add_type(typedef.symname, typedef.full_decl)
              if is_callback?(node)
                cb = Callback.new(:node => node, :indent => @indent).to_s << "\n"
                Generator.add_type(typedef.symname, "callback #{typedef.symname}")
                result << cb.to_s
              end
            elsif is_enum?(node)
              e = Enum.new(:node => node, :indent => @indent)
              Generator.add_type(e.symname, Generator::TYPES['int'])
              result << e.to_s << "\n"
            elsif is_struct?(node)
              s = Structure.new(:node => node, :indent => @indent)
              Generator.add_type(s.symname, "struct #{s.symname}")
              unless Generator.ignored.include? node.attributes['id']
                nested = handle_nested_structure(node, s.symname)
                result << (nested.empty? ? s.to_s : nested << fixme(s.to_s, NestedStructureNotSupported))
              end
            elsif is_union?(node)
              s = Union.new(:node => node, :indent => @indent)
              Generator.add_type(s.symname, "union #{s.symname}")
              unless Generator.ignored.include? node.attributes['id']
                nested = handle_nested_structure(node, s.symname)
                result << (nested.empty? ? s.to_s : nested << fixme(s.to_s, NestedStructureNotSupported))
              end
            elsif is_function_decl?(node)
              result << Function.new(:node => node, :indent => @indent).to_s << "\n"
            elsif node.name == 'insert' and not is_insert_runtime?(node) and not node.parent.name == 'class'
              result << get_verbatim(node)
            end       
          end
          result
        end
        def generate(node)
          pass(node)
          pass(node) unless Generator.nested_type.empty?
        end
      end
    end
  end
end
