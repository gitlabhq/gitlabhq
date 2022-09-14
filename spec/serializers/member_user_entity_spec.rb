# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberUserEntity do
  let_it_be(:user) { create(:user, last_activity_on: Date.today) }
  let_it_be(:emoji) { 'slight_smile' }
  let_it_be(:user_status) { create(:user_status, user: user, emoji: emoji) }

  let(:entity) { described_class.new(user) }
  let(:entity_hash) { entity.as_json }

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('entities/member_user_default')
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

  it 'correctly exposes `is_bot`' do
    allow(user).to receive(:bot?).and_return(true)

    expect(entity_hash[:is_bot]).to be(true)
  end

  it 'does not expose `two_factor_enabled` by default' do
    expect(entity_hash[:two_factor_enabled]).to be(nil)
  end

  it 'correctly exposes `status.emoji`' do
    expect(entity_hash[:status][:emoji]).to match(emoji)
  end

  it 'correctly exposes `created_at`' do
    expect(entity_hash[:created_at]).to be(user.created_at)
  end

  it 'correctly exposes `last_activity_on`' do
    expect(entity_hash[:last_activity_on]).to be(user.last_activity_on)
  end

  context 'when options includes a source' do
    let(:current_user) { create(:user) }
    let(:options) { { current_user: current_user, source: source } }
    let(:entity) { described_class.new(user, options) }

    shared_examples 'correctly exposes user two_factor_enabled' do
      context 'when the current_user has a role lower than minimum manage member role' do
        before do
          source.add_member(current_user, Gitlab::Access::DEVELOPER)
        end

        it 'does not expose user two_factor_enabled' do
          expect(entity_hash[:two_factor_enabled]).to be(nil)
        end

        it 'matches json schema' do
          expect(entity.to_json).to match_schema('entities/member_user_default')
        end
      end

      context 'when the current user has a minimum manage member role or higher' do
        before do
          source.add_member(current_user, minimum_manage_member_role)
        end

        it 'matches json schema' do
          expect(entity.to_json).to match_schema('entities/member_user_for_admin_member')
        end

        it 'exposes user two_factor_enabled' do
          expect(entity_hash[:two_factor_enabled]).to be(false)
        end
      end

      context 'when the current user is self' do
        let(:current_user) { user }

        it 'exposes user two_factor_enabled' do
          expect(entity_hash[:two_factor_enabled]).to be(false)
        end

        it 'matches json schema' do
          expect(entity.to_json).to match_schema('entities/member_user_for_admin_member')
        end
      end
    end

    context 'when the source is a group' do
      let(:source) { create(:group) }
      let(:minimum_manage_member_role) { Gitlab::Access::OWNER }

      it_behaves_like 'correctly exposes user two_factor_enabled'
    end

    context 'when the source is a project' do
      let(:source) { create(:project) }
      let(:minimum_manage_member_role) { Gitlab::Access::MAINTAINER }

      it_behaves_like 'correctly exposes user two_factor_enabled'
    end
  end
end
