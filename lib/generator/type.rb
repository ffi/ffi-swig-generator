module FFI
  module Generator
    class Type < Node
      attr_reader :full_decl
      
      ArraySizeRE = /([0-9\+\-\*\/\(\)]+)/
      ArrayRE = /^a\(#{ArraySizeRE}\)/

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
          @full_decl and @full_decl[ArrayRE]
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
        params = { :declaration => get_full_decl, :typedefs => { } }.merge(params)
        @full_decl = params[:declaration]
        @typedefs = params[:typedefs] || { }
        @declaration = Declaration.new(@full_decl)
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
          num = @full_decl.scan(ArrayRE).flatten[0]
          "[#{ffi_type_from(@full_decl.gsub!(/#{ArrayRE}\./, ''))}, #{num}]"
        end
      end
      def struct
        Struct.camelcase(@full_decl.scan(/^struct\s(\w+)/).flatten[0]) if @declaration.is_struct?
      end
      def union
        Union.camelcase(@full_decl.scan(/^union\s(\w+)/).flatten[0]) if @declaration.is_union?
      end
      def enum
        ffi_type_from(Generator::TYPES['int']) if @declaration.is_enum?
      end
      def callback
        "Callback_#{@full_decl.scan(/^callback\s(\w+)/).flatten[0]}" if @declaration.is_callback?
      end
      def inline_callback
        Callback.new(:node => @node, :inline => true, :typedefs => @typedefs).to_s if @declaration.is_inline_callback?        
      end
      def typedef
        ":" + @full_decl if @typedefs.has_key?(@full_decl)
      end
      def undefined(type)
        "#{type}"
      end
      def ffi_type_from(full_decl)
        @full_decl = full_decl
        @declaration = Declaration.new(full_decl)
        constant             || \
        volatile             ||
        typedef              ||
        pointer              ||
        enum                 ||
        native               ||
        struct               ||
        union                ||
        array                ||
        inline_callback      ||
        callback             ||
        undefined(full_decl)
      end
    end
  end
end
