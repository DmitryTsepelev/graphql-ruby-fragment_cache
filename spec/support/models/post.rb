# frozen_string_literal: true

class Post
  class << self
    def find(id)
      store.fetch(id.to_i) do
        author = User.new(id: id, name: "User ##{id}")
        new(id: id, title: "Post ##{id}", author: author)
      end
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

  attr_reader :id
  attr_accessor :title, :author

  def initialize(id:, title:, author: nil)
    @id = id
    @title = title
    @author = author
  end
end
