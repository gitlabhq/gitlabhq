# frozen_string_literal: true

class AddPasswordToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :password, :string
  end
end
