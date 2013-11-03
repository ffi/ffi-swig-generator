module FFI
  module Generator
    NestedStructureNotSupported =<<EOM
Nested structures are not correctly supported at the moment.
Please check the order of the declarations in the structure below.
EOM
    class Parser
      def initialize(indent = 2)
        @indent = indent
        @typedefs = {}
        @nested_type = {}
        @nested_structure = {}
        @ignored = []
        @ignore_at_second_pass = []
      end
      def generate(node)
        result = ""
        result = pass(node)
        result = pass(node) unless @nested_type.empty?
        result
      end
      def ignore(*ignored)
        @ignored.concat(ignored)
      end
      def load_config(fn)
        eval(File.read(fn), binding)
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
      def add_type(ctype, rtype)
        @typedefs[ctype] = rtype
      end
      def add_nested_structure(symname, id)
        (@nested_structure[@nested_type[symname]] ||= []) << id
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
      def typedef_alias?(node)
        # This is to handle the case where a typedef references an opaque
        # struct.  In that case the typedef code would output something that
        # throws an error.  See issue #21
        return false if get_attr(node, 'type') =~ /^struct /
        typedef?(node) and !callback?(node) and !get_attr(node, 'sym_name').nil?
      end
      def callback?(node)
        get_attr(node, 'decl') =~ /^p\.f\(/
      end
      def nested_type?(node)
        get_attr(node, 'nested')
      end
      def fix_nested_structure(node)
        result = ""
        if struct?(node)
          s = Struct.new(:node => node, :indent => @indent, :typedefs => @typedefs)
          result << (@nested_structure.has_key?(s.symname) ? fixme(s.to_s, NestedStructureNotSupported) : s.to_s)
        else
          u = Union.new(:node => node, :indent => @indent, :typedefs => @typedefs)
          result << (@nested_structure.has_key?(u.symname) ? fixme(u.to_s, NestedStructureNotSupported) : u.to_s)
        end
        result  
      end
      # Search for nested structures and fix them.
      def find_nested_struct(node, id)
        result = ""
        nested_node = (node.parent / "class[@id='#{id}']").first
        if @nested_structure.has_key?(get_attr(nested_node, 'name'))
          @nested_structure[get_attr(nested_node, 'name')].reverse.each do |id|
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
        @nested_structure[symname] and not @nested_structure[symname].empty?
      end
      def prepend_nested_structures(node, symname)
        result = ""
        if has_nested_structures?(node, symname)
          @nested_structure[symname].reverse.each do |nested_id|
            result << find_nested_struct(node, nested_id)
          end
          @nested_structure[symname].clear
        end
        result          
      end
      def handle_nested_structure(node, symname)
        if @nested_type[symname]
          add_nested_structure(symname, node.attributes['id'])
          @ignore_at_second_pass << node.attributes['id']
        end
        prepend_nested_structures(node, symname)
      end
      def ignore?(name)
        @ignored.any? do |to_be_ignored|
          Regexp === to_be_ignored ? to_be_ignored =~ name : to_be_ignored == name
        end
      end
      def pass(node)
        result = []
        node.traverse do |node|
          node_result = ''
          node_type = nil
          unless ignore?(get_attr(node, 'name'))
            if constant?(node)
              node_type = :constant
              node_result << Constant.new(:node => node, :indent => @indent).to_s << "\n"
            elsif typedef?(node)
              node_type = :typedef
              typedef = Typedef.new(:node => node, :indent => @indent, :typedefs => @typedefs)
              add_type(typedef.symname, typedef.full_decl)
              if callback?(node)
                cb = Callback.new(:node => node, :indent => @indent, :typedefs => @typedefs).to_s << "\n"
                add_type(typedef.symname, "callback #{typedef.symname}")
                result << cb.to_s
              elsif typedef_alias?(node)
                node_result << typedef.to_s << "\n"
              end
            elsif enum?(node)
              node_type = :enum
              e = Enum.new(:node => node, :indent => @indent)
              add_type(e.symname, e.symname)
              node_result << e.to_s << "\n"
            elsif struct?(node)
              node_type = :struct
              s = Struct.new(:node => node, :indent => @indent, :typedefs => @typedefs)
              add_type(s.symname, "struct #{s.symname}")
              unless @ignore_at_second_pass.include? node.attributes['id']
                nested = handle_nested_structure(node, s.symname)
                node_result << (nested.empty? ? s.to_s : nested << fixme(s.to_s, NestedStructureNotSupported))
              end
            elsif union?(node)
              node_type = :union
              s = Union.new(:node => node, :indent => @indent, :typedefs => @typedefs)
              add_type(s.symname, "union #{s.symname}")
              unless @ignore_at_second_pass.include? node.attributes['id']
                nested = handle_nested_structure(node, s.symname)
                node_result << (nested.empty? ? s.to_s : nested << fixme(s.to_s, NestedStructureNotSupported))
              end
            elsif function_decl?(node)
              node_type = :function
              node_result << Function.new(:node => node, :indent => @indent, :typedefs => @typedefs).to_s << "\n"
            elsif nested_type?(node)
              node_type = :nested
              # Pull the type name for the node.  Handle the case where the
              # nested type is a pointer by only using everything after the
              # last period as the type key.
              type = get_attr(node, 'type').split(".").last
              @nested_type[type] = get_attr(node, 'nested')
            elsif node.name == 'insert' and not insert_runtime?(node) and not node.parent.name == 'class'
              node_type = :insert
              node_result << get_verbatim(node)
            end       
          end

          # don't append unhandled node types
          next unless node_type

          # don't add output if node is the result of %import
          parent = node
          while parent.respond_to?(:parent) and parent = parent.parent
            if parent.name == 'import'
              break
            end
          end
          if parent.name != 'import'
            result << [ node_type, node_result ]
          end
        end

        # Now, our results may contain pointer references to Struct classes
        # that are not defined until later in the file.  To handle this we
        # process each chunk of user-defined text from the .i file, and
        # generated text from the parser.  If the generated text contains
        # any pointers to Struct classes, we will prepend the generated
        # text with a minimal FFI::Struct class for each class.
        #
        # We process the code in groups of user-defined text, and generated
        # text because it's possible that the user-defined text may actually
        # contain both the end of one class and the start of a new class.  So
        # the only way to safely prepend our minimal classes so that they are
        # defined in the appropriate class is to shove them between each
        # pair of user-defined text and generated text.
        #
        # Another case we need to consider is that of pointers to opaque
        # structs in attach_function() calls.  attach_function() does not
        # appear to like Struct.ptr for structs that have no layout.  So
        # for all Struct.ptr references in our generated code, we verify that
        # a class for that struct was generated with a layout.  If not, we
        # replace all pointer references to that struct with :pointer.

        # If the .i did not start with user-defined text, prepend an empty
        # user-defined text here to make processing easier.
        result.unshift [ :insert, "" ] unless result[0][0] == :insert

        result.inject([]) do |out, chunk|
          # Step 1: Convert our result array into chunks of:
          #  [ user-defined text, generated text ]
          if chunk[0] == :insert
            # new chunk
            out << [chunk[1], ""]
          else
            # append the generated text to the existing chunk
            out[-1][-1] << chunk[1]
          end
          out
        end.inject("") do |buf, pair|
          supplied, generated = pair

          # Append the user-supplied text
          buf << supplied if supplied

          # move on if we don't have a generated section
          next buf unless generated
          
          # Search our generated output for any Struct.ptr references.
          # If the layout of the struct is defined anywhere in our output,
          # prepend a minimal FFI::Struct declaration to the front of this
          # generated code segment.  If the layout of the struct is never
          # supplied, we convert all Struct.ptr references to :pointer.
          generated.scan(/([a-z0-9]+)\.ptr/i).uniq.flatten.each do |klass|
            if result.find { |t,b| b =~ /^  class #{klass}/ }
              buf << "#{" " * @indent}class #{klass} < FFI::Struct; end\n"
            else
              generated.gsub! /([^a-zA-Z0-9])#{klass}.ptr/, "\\1:pointer"
            end
          end
          
          # Append our generated code
          buf << generated
         
          # next chunk
          buf
        end
      end
    end
  end
end
