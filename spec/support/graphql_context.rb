# frozen_string_literal: true

using(Module.new {
  refine Hash do
    def camelize_keys
      transform_keys { |key| GraphQL::Schema::Member::BuildType.camelize(key.to_s) }.tap do |h|
        h.keys.each do |k|
          next unless h[k].is_a?(Hash)

          h[k] = h[k].camelize_keys
        end
      end
    end
  end
})

shared_context "graphql" do
  let(:context) { {} }
  let(:variables) { {} }
  let(:field) { result.fetch("data").keys.first }
  let(:schema) { raise NotImplementedError.new("Specify schema under test, e.g. `let(:schema) { MySchema }`") }

  let(:data) do
    raise "API Query failed:\n\tquery: #{query}\n\terrors: #{result["errors"]}" if result.key?("errors")
    result.fetch("data").dig(*field.split("->"))
  end

  let(:errors) { result["errors"]&.map { |err| err["message"] } }

  # for connection responses
  let(:edges) { data.fetch("edges").map { |node| node.fetch("node") } }
  let(:page_info) { data.fetch("pageInfo") }

  subject(:result) { execute_query }

  def execute_query(query = self.query, variables: self.variables, context: self.context)
    schema.execute(
      query,
      context: context,
      variables: variables.camelize_keys
    )
  end
end
