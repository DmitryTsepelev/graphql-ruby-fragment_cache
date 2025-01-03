# frozen_string_literal: true

module SchemaHelper
  def build_schema(&block)
    Class.new(GraphQL::Schema) do
      use GraphQL::FragmentCache

      instance_eval(&block)
    end
  end
end
