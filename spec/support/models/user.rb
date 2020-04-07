# frozen_string_literal: true

class User
  attr_reader :id
  attr_accessor :name

  def initialize(id:, name:)
    @id = id
    @name = name
  end
end

class CacheableUser < User
  def cache_key
    "#{id}/#{name}"
  end
end
