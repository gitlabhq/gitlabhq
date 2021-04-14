# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberUserEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:emoji) { 'slight_smile' }
  let_it_be(:user_status) { create(:user_status, user: user, emoji: emoji) }

  let(:entity) { described_class.new(user) }
  let(:entity_hash) { entity.as_json }

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('entities/member_user')
  end

  it 'correctly exposes `avatar_url`' do
    avatar_url = 'https://www.gravatar.com/avatar/c4637cb869d5f94c3193bde4f23d4cdc?s=80&d=identicon'
    allow(user).to receive(:avatar_url).and_return(avatar_url)

    expect(entity_hash[:avatar_url]).to match(avatar_url)
  end

  it 'correctly exposes `blocked`' do
    allow(user).to receive(:blocked?).and_return(true)

    expect(entity_hash[:blocked]).to be(true)
  end

  it 'correctly exposes `two_factor_enabled`' do
    allow(user).to receive(:two_factor_enabled?).and_return(true)

    expect(entity_hash[:two_factor_enabled]).to be(true)
  end

  it 'correctly exposes `status.emoji`' do
    expect(entity_hash[:status][:emoji]).to match(emoji)
  end
end
