# frozen_string_literal: true

require_relative "base_type"

module TestTypes
  class UserType < BaseType
    field :id, ID, null: false
    field :name, String, null: false
  end
end
