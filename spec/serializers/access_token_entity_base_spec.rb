# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessTokenEntityBase do
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { create(:personal_access_token, user: user) }

  subject(:json) {  described_class.new(token).as_json }

  it 'has the correct attributes' do
    expect(json).to(
      include(
        id: token.id,
        name: token.name,
        revoked: false,
        created_at: token.created_at,
        scopes: token.scopes,
        expires_at: token.expires_at.iso8601,
        expired: false,
        expires_soon: false
      ))

    expect(json).not_to include(:token)
  end
end
