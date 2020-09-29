# frozen_string_literal: true

class User
  attr_reader :id
  attr_accessor :name

  class << self
    def fetch(id)
      store.fetch(id.to_i) do
        new(id: id, name: "User ##{id}")
      end
    end

    def all
      @store.values
    end

    def create(id:, **attributes)
      store[id] = new(id: id, **attributes)
    end

    def store
      @store ||= {}
    end
  end

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
