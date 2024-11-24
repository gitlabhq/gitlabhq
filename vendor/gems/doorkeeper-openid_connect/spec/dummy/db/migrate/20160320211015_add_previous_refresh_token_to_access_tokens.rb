# frozen_string_literal: true

class AddPreviousRefreshTokenToAccessTokens < ActiveRecord::Migration[4.2]
  def change
    add_column(
      :oauth_access_tokens,
      :previous_refresh_token,
      :string,
      default: '',
      null: false
    )
  end
end
