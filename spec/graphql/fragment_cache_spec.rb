# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache do
  context "when interpreter is not used" do
    it "raises error" do
      expect {
        Class.new(GraphQL::Schema) { use GraphQL::FragmentCache }
      }.to raise_error(
        StandardError, "GraphQL::Execution::Interpreter should be enabled for partial caching"
      )
    end
  end
end
