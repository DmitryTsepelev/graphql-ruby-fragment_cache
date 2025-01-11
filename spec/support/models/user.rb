# frozen_string_literal: true

class User
  attr_reader :id
  attr_accessor :name

  class << self
    def find_by_post_ids(post_ids)
      post_ids.map { |id| Post.find(id).author }
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
