# frozen_string_literal: true

class AddCurrentSignInAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_sign_in_at, :datetime
  end
end
