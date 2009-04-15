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
    class Parser
      def initialize(indent = 2)
        @indent = indent
      end
      def generate(node)
        result = ""
        result = pass(node)
        result = pass(node) unless Generator.nested_type.empty?
        result
      end
      private
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
      def insert_runtime?(node)
        get_attr(node, 'section') == 'runtime'
      end
      def constant?(node)
        node.name == 'constant'
      end
      def enum?(node)
        node.name == 'enum'
      end
      def function_decl?(node)
        node.name == 'cdecl' and get_attr(node, 'kind') == 'function'
      end
      def struct?(node)
        node.name == 'class' and get_attr(node, 'kind') == 'struct'
      end
      def union?(node)
        node.name == 'class' and get_attr(node, 'kind') == 'union'
      end        
      def typedef?(node)
        node.name == 'cdecl' and get_attr(node, 'kind') == 'typedef'
      end
      def callback?(node)
        get_attr(node, 'decl') =~ /^p\.f\(/
      end
      def fix_nested_structure(node)
        result = ""
        if struct?(node)
          s = Structure.new(:node => node, :indent => @indent)
          result << (Generator.nested_structure.has_key?(s.symname) ? fixme(s.to_s, NestedStructureNotSupported) : s.to_s)
        else
          u = Union.new(:node => node, :indent => @indent)
          result << (Generator.nested_structure.has_key?(u.symname) ? fixme(u.to_s, NestedStructureNotSupported) : u.to_s)
        end
        result  
      end
      # Search for nested structures and fix them.
      def find_nested_struct(node, id)
        result = ""
        nested_node = (node.parent / "class[@id='#{id}']").first
        if Generator.nested_structure.has_key?(get_attr(nested_node, 'name'))
          Generator.nested_structure[get_attr(nested_node, 'name')].reverse.each do |id|
            result << find_nested_struct(nested_node, id)
          end
        end
        result << fix_nested_structure(nested_node) if nested_node
      end
      def fixme(code, message)
        comment('FIXME: ' + message) << comment(code)
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
          Generator.nested_structure[symname].reverse.each do |nested_id|
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
          if constant?(node)
            result << Constant.new(:node => node, :indent => @indent).to_s << "\n"
          elsif typedef?(node)
            typedef = Typedef.new(:node => node)
            Generator.add_type(typedef.symname, typedef.full_decl)
            if callback?(node)
              cb = Callback.new(:node => node, :indent => @indent).to_s << "\n"
              Generator.add_type(typedef.symname, "callback #{typedef.symname}")
              result << cb.to_s
            end
          elsif enum?(node)
            e = Enum.new(:node => node, :indent => @indent)
            Generator.add_type(e.symname, Generator::TYPES['int'])
            result << e.to_s << "\n"
          elsif struct?(node)
            s = Structure.new(:node => node, :indent => @indent)
            Generator.add_type(s.symname, "struct #{s.symname}")
            unless Generator.ignored.include? node.attributes['id']
              nested = handle_nested_structure(node, s.symname)
              result << (nested.empty? ? s.to_s : nested << fixme(s.to_s, NestedStructureNotSupported))
            end
          elsif union?(node)
            s = Union.new(:node => node, :indent => @indent)
            Generator.add_type(s.symname, "union #{s.symname}")
            unless Generator.ignored.include? node.attributes['id']
              nested = handle_nested_structure(node, s.symname)
              result << (nested.empty? ? s.to_s : nested << fixme(s.to_s, NestedStructureNotSupported))
            end
          elsif function_decl?(node)
            result << Function.new(:node => node, :indent => @indent).to_s << "\n"
          elsif node.name == 'insert' and not insert_runtime?(node) and not node.parent.name == 'class'
            result << get_verbatim(node)
          end       
        end
        result
      end
    end
  end
end
