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
          @full_decl[/^(a\(\)\.)?p\./] and not is_inline_callback?
        end
        def is_enum?
          @full_decl[/^enum/]
        end
        def is_array?
          @full_decl and @full_decl[ArrayRE]
        end
        def is_struct?
          @full_decl[/^(q\([a-z]+\)\.)*struct/]
        end
        def is_union?
          @full_decl[/^(q\([a-z]+\)\.)*union/]
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
        return unless @declaration.is_pointer?
        
        # String case is easy, pointer (const, volitile, etc) to a char
        return ':string' if @full_decl =~ /^p.(q\([a-z]+\)\.)*char$/

        # Other types of pointers require us to strip the leading p.
        tail_decl = @full_decl.split("p.", 2).last

        # We need to expand any typedefs possible here.
        tail_decl = @typedefs[tail_decl] if @typedefs.has_key?(tail_decl)

        # Let's see if this is a struct
        decl = Declaration.new(tail_decl)
        return Struct.camelcase(tail_decl.split(" ").last) + ".ptr" if
          decl.is_struct?

        # Everything else is a :pointer
        ":pointer"
      end
      def array
        if @declaration.is_array?
          num = @full_decl.scan(ArrayRE).flatten[0]
          "[#{ffi_type_from(@full_decl.gsub!(/#{ArrayRE}\./, ''))}, #{num}]"
        end
      end
      def struct
        return nil unless @declaration.is_struct?
        Struct.camelcase(@full_decl.scan(/^struct\s(\w+)/).flatten[0]) + ".by_value"
      end
      def union
        Union.camelcase(@full_decl.scan(/^union\s(\w+)/).flatten[0]) if @declaration.is_union?
      end
      def enum
        return nil unless @declaration.is_enum?

        # Look up the class for the enum in our typedefs, otherwise use :int
        (@typedefs.find { |k,v| v == @full_decl } || []).first ||
          ffi_type_from(Generator::TYPES['int'])
      end
      def callback
        "Callback_#{@full_decl.scan(/^callback\s(\w+)/).flatten[0]}" if @declaration.is_callback?
      end
      def inline_callback
        Callback.new(:node => @node, :inline => true, :typedefs => @typedefs).to_s if @declaration.is_inline_callback?        
      end
      def typedef
        # Pull the ruby type from the typedefs.  If one doesn't exist, this
        # isn't a typedef and we just return nil.
        ruby_decl = @typedefs[@full_decl] or return nil

        # For those typedefs that were legitimately typedef'ed in the C code,
        # our ruby declaration will be a string representing a symbol for that
        # type.  Ex:
        #   @typedefs => {
        #     'my_time_t' => ':my_time_t'
        #   }
        #
        # For these we just return the ruby type
        return ruby_decl if ruby_decl =~ /^:/

        # For the remaining typedefs, the mapping is from a C data type to a
        # string that Type can parse to construct the Ruby data type.  Ex:
        #   @typedefs => {
        #     'example_struct' => 'struct example_struct',
        #     'my_union' => 'union my_union',
        #   }
        #
        # For these entries in typedefs, we return the type string for the ruby
        # declaration.
        return Type.new(:declaration => ruby_decl, :typedefs => @typedefs).to_s
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
