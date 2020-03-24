# frozen_string_literal: true

module TestModels
  class Post
    def self.find(id)
      author = User.new(id: id, name: "User ##{id}")
      new(id: id, title: "Post ##{id}", author: author)
    end

    attr_reader :id, :title, :author

    def initialize(id:, title:, author:)
      @id = id
      @title = title
      @author = author
    end
  end
end
