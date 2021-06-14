module GraphQL
  module FragmentCache
    module Schema
      class LazyCacheResolver
        def initialize(&block)
          @block = block
        end

        def resolve
          @block.call
        end
      end
    end
  end
end