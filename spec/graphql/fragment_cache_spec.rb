# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache do
  context "when interpreter is not used" do
    it "raises error" do
      expect do
        Class.new(GraphQL::Schema) { use GraphQL::FragmentCache }
      end.to raise_error(
        StandardError, "GraphQL::Execution::Interpreter should be enabled for partial caching"
      )
    end
  end
end
