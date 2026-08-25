# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::UserinfoClaimsBuilder, feature_category: :system_access do
  let_it_be(:user) do
    create(:user,
      name: 'Jane Doe',
      username: 'janedoe',
      first_name: 'Jane',
      last_name: 'Doe',
      website_url: 'https://example.com',
      email: 'jane@example.com',
      current_sign_in_at: Time.zone.parse('2026-01-01T00:00:00Z')
    )
  end

  let_it_be(:group) { create(:group, developers: user) }

  subject(:claims) { described_class.new(user).claims }

  it 'returns exactly the claims marked "Included in ID Token"' do
    expect(claims.keys).to match_array(%i[
      sub auth_time name nickname preferred_username given_name family_name
      email email_verified website profile picture groups_direct
    ])
  end

  it 'maps claims to the expected user attributes' do
    expect(claims).to include(
      sub: user.id.to_s,
      name: 'Jane Doe',
      nickname: 'janedoe',
      preferred_username: 'janedoe',
      given_name: 'Jane',
      family_name: 'Doe',
      email: 'jane@example.com',
      email_verified: user.primary_email_verified?,
      website: user.full_website_url,
      profile: Gitlab::Routing.url_helpers.user_url(user),
      picture: user.avatar_url(only_path: false),
      groups_direct: [group.full_path]
    )
  end

  context 'when the user has no sign-in history' do
    let(:user) { create(:user, current_sign_in_at: nil) }

    it 'omits auth_time' do
      expect(claims).not_to have_key(:auth_time)
    end
  end

  context 'when the user has signed in before' do
    it 'includes auth_time as a unix timestamp' do
      expect(claims[:auth_time]).to eq(user.current_sign_in_at.to_i)
    end
  end

  context 'when optional attributes are blank' do
    let(:user) { create(:user, first_name: '', last_name: '', website_url: '') }

    it 'omits the blank claims' do
      expect(claims).not_to have_key(:given_name)
      expect(claims).not_to have_key(:family_name)
      expect(claims).not_to have_key(:website)
    end
  end

  context 'when the user has no direct group membership' do
    let_it_be(:lone_user) { create(:user) }

    subject(:claims) { described_class.new(lone_user).claims }

    it 'returns an empty groups_direct array' do
      expect(claims[:groups_direct]).to eq([])
    end
  end
end
