# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table(:tweets, force: true) do |t|
    t.text :content
    t.timestamps
  end
end
