# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :secret
  end
end

class User < ActiveRecord::Base
end
