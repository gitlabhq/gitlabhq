# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ImpersonationAccessTokenEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { create(:personal_access_token, :impersonation, user: user) }

  subject(:json) {  described_class.new(token).as_json }

  it 'has the correct attributes' do
    expected_revoke_path = Gitlab::Routing.url_helpers
                                          .revoke_admin_user_impersonation_token_path(
                                            { user_id: user, id: token })

    expected_rotate_path = Gitlab::Routing.url_helpers
                                          .rotate_admin_user_impersonation_token_path(
                                            { user_id: user, id: token })

    expect(json).to(
      include(
        id: token.id,
        name: token.name,
        scopes: token.scopes,
        user_id: token.user_id,
        revoke_path: expected_revoke_path,
        rotate_path: expected_rotate_path
      ))

    expect(json).not_to include(:token)
  end
end
