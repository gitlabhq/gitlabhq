# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokenEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { create(:personal_access_token, user: user) }

  subject(:json) {  described_class.new(token).as_json }

  it 'has the correct attributes' do
    expected_revoke_path = Gitlab::Routing.url_helpers
                                          .revoke_profile_personal_access_token_path(
                                            { id: token })

    expect(json).to(
      include(
        id: token.id,
        name: token.name,
        scopes: token.scopes,
        user_id: token.user_id,
        revoke_path: expected_revoke_path
      ))

    expect(json).not_to include(:token)
  end
end
