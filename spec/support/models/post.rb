# frozen_string_literal: true

class Post
  class << self
    def find(id)
      store.fetch(id.to_i) do
        author = User.new(id: id, name: "User ##{id}")
        new(id: id, title: "Post ##{id}", author: author)
      end
    end

    def all
      @store.values
    end

    def create(id:, **attributes)
      store[id] = new(id: id, **attributes)
    end

    def delete_all
      store.clear
    end

    private

    def store
      @store ||= {}
    end
  end

  attr_accessor :id, :title, :author, :meta

  def initialize(id:, title:, author: nil, meta: nil)
    @id = id
    @title = title
    @author = author
    @meta = meta
  end

  def cache_key
    title.gsub(/\s/, "")
  end
end
