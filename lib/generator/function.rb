module FFI
  module Generator
    class Function < Type
      class Argument < Type
        def to_s
          case get_attr('type')
          when 'void'
            nil
          when /^p\./
            ':pointer'
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
        # Don't try to attach to inline functions; maybe look at using the
        # inline gem to automatically handle these?
        return "#{@indent_str}# inline function #{get_attr('sym_name')}" if
          get_attr("code") != nil

        params = get_params(@node).inject([]) do |array, node|
          array << Argument.new(:node => node, :typedefs => @typedefs).to_s
        end
        @indent_str + "attach_function :#{get_attr('sym_name')}, :#{@symname}, [ #{params.join(', ')} ], #{get_rtype}"
      end
      private
      def get_params(node)
        parmlist = node / './attributelist/parmlist/parm'
      end
      def get_rtype
        pointer = get_attr('decl').scan(/^f\(.*\)\.(p)/).flatten[0]
        declaration = pointer ? "p.#{get_attr('type')}" : get_attr('type')
        Type.new(:declaration => declaration, :typedefs => @typedefs).to_s
      end
    end
    class Callback < Function
      def initialize(params = { })
        super(params)
        @inline = true if params[:inline] == true
      end
      def to_s
        unless @inline
          @indent_str + "Callback_#{@symname} = callback(:#{@symname}, [ #{get_params.join(', ')} ], #{get_rtype})"
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
            declaration.gsub!(/#{Regexp.escape(Type.new(:node => node, :typedefs => @typedefs).get_attr('type'))}/, '')
            array << Argument.new(:node => node, :typedefs => @typedefs).to_s
          end
        else
          result = @full_decl.scan(/p.f\((.*)\)/).flatten[0].split(',').inject([]) do |array, type|
            array << (type == 'void' ? '' : Type.new(:declaration => type, :typedefs => @typedefs).to_s)
          end
        end
        @full_decl = declaration + type
        result
      end
      def get_rtype
        Type.new(:declaration => @full_decl.scan(/f\([a-zA-z0-9,.\s\(\)]*\)\.([a-zA-Z0-9_\.,\s\(\)]+)/).flatten[0], :typedefs => @typedefs).to_s
      end
    end
  end
end
