# frozen_string_literal: true

class EnablePkce < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_access_grants, :code_challenge, :string, null: true
    add_column :oauth_access_grants, :code_challenge_method, :string, null: true
  end
end
