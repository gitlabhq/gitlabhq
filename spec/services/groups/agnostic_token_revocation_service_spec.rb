# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AgnosticTokenRevocationService, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
  end

  describe '#initialize' do
    subject(:result) { described_class.new(group, owner, 'plaintext') }

    it 'accepts a group, user, and plaintext' do
      expect(result).to be_a(described_class)
    end
  end

  shared_examples_for 'a successfully revoked token' do
    it { expect(result.success?).to be(true), result.message }

    it 'revokes the token' do
      result
      expect(token.reload).to be_revoked
    end

    it 'returns the token in the payload' do
      result
      expect(result.payload[:revocable]).to eq(token)
    end

    it 'returns the token class and api_entity in the payload', :aggregate_failures do
      result
      expect(result.payload[:type]).to be(type)
      expect(result.payload[:api_entity]).to be(type)
    end
  end

  shared_examples_for 'an unsuccessfully revoked token' do
    it { expect(result.success?).to be(false) }

    it 'does not revoke the token' do
      result
      expect(token.reload.revoked?).to be(false)
    end
  end

  describe '#execute' do
    subject(:result) { service.execute }

    let_it_be(:member) { create(:user, guest_of: group) }

    let(:service) { described_class.new(group, owner, token.token) }

    context 'with a personal access token' do
      let(:type) { 'PersonalAccessToken' }

      context 'when it can access the group' do
        let_it_be(:token) { create(:personal_access_token, user: member) }

        it_behaves_like 'a successfully revoked token'
      end

      context 'when it can access a sub group' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:member) { create(:user, guest_of: group) }
        let_it_be(:token) { create(:personal_access_token, user: member) }

        it_behaves_like 'a successfully revoked token'
      end

      context 'when it can access a group\'s project' do
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:member) { create(:user, :project_bot, guest_of: project) }
        let_it_be(:token) { create(:personal_access_token, user: member) }

        it_behaves_like 'a successfully revoked token'
      end

      context 'when it belongs to a member with no relation to the group' do
        let_it_be(:token) { create(:personal_access_token, user: user) }

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when it belongs to a member of multiple groups' do
        let_it_be(:group_b) { create(:group) }
        let_it_be(:member) { create(:user, guest_of: [group, group_b]) }
        let_it_be(:token) { create(:personal_access_token, user: member) }

        it_behaves_like 'a successfully revoked token'
      end

      context 'with an already revoked personal access token that can access the group' do
        let(:token) { create(:personal_access_token, user: member, revoked: true) }

        it_behaves_like 'a successfully revoked token'
      end

      context 'with an already expired token' do
        let(:token) { create(:personal_access_token, :expired, user: member) }

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'with an already expired and revoked token' do
        let(:token) { create(:personal_access_token, :expired, revoked: true, user: member) }

        it_behaves_like 'a successfully revoked token'
      end
    end

    context 'with a group deploy token' do
      let(:type) { 'DeployToken' }

      let_it_be(:subgroup) { create(:group, parent: group) }

      context 'when it can access the group' do
        let_it_be(:token) { create(:group_deploy_token, group: group).deploy_token }

        it_behaves_like 'a successfully revoked token'
      end

      context 'when it can access a subgroup' do
        let_it_be(:token) { create(:group_deploy_token, group: subgroup).deploy_token }

        it_behaves_like 'a successfully revoked token'
      end

      context 'when it belongs to another group' do
        let_it_be(:token) { create(:group_deploy_token).deploy_token }

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when it belongs to a project' do
        let_it_be(:token) { create(:project_deploy_token).deploy_token }

        it_behaves_like 'an unsuccessfully revoked token'
      end
    end

    context 'with a user feed token' do
      let(:service) { described_class.new(group, owner, user.reset.feed_token) }

      shared_examples_for 'a successfully rotated feed token' do
        it { expect(result.success?).to be(true), result.message }

        before do
          allow(Users::ResetFeedTokenService).to receive(:new).and_call_original
        end

        it 'calls ResetFeedTokenService with source' do
          result
          expect(Users::ResetFeedTokenService).to have_received(:new).with(owner, user: user,
            source: :group_token_revocation_service)
        end

        it 'rotates the token' do
          original_token = user.feed_token
          result
          expect(user.reset.feed_token).not_to eq(original_token)
        end

        it 'returns the user in the payload' do
          expect(result.payload[:revocable]).to eq(user)
        end

        it 'returns the type of token in the payload' do
          expect(result.payload[:type]).to be('FeedToken')
        end

        it 'uses the UserSafe api_entity' do
          expect(result.payload[:api_entity]).to be('UserSafe')
        end
      end

      shared_examples_for 'an unsuccessfully rotated feed token' do
        it { expect(result.success?).to be(false) }

        it 'does not revoke the token' do
          original_token = user.reset.feed_token
          result
          expect(user.reset.feed_token).to eq(original_token)
        end
      end

      context 'when the user can access the group' do
        let_it_be(:user) { create(:user, guest_of: group) }

        it_behaves_like 'a successfully rotated feed token'
      end

      context 'when the user can access a sub group' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:user) { create(:user, guest_of: subgroup) }

        it_behaves_like 'a successfully rotated feed token'
      end

      context 'when the user can access a group\'s project' do
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:user) { create(:user, :project_bot, guest_of: project) }

        it_behaves_like 'a successfully rotated feed token'
      end

      context 'when the user has with no relation to the group' do
        let_it_be(:user) { create(:user) }

        it_behaves_like 'an unsuccessfully rotated feed token'
      end
    end

    context 'with a token that would otherwise be revoked' do
      let_it_be(:token) { create(:personal_access_token, user: member) }

      context 'when ff disabled for group' do
        before do
          Feature.disable(:group_agnostic_token_revocation, group)
        end

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when group is a subgroup' do
        let_it_be(:group) { create(:group, :nested) }
        let_it_be(:member) { create(:user, guest_of: group) }

        before_all do
          group.add_owner(owner)
        end

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when current_user is a maintainer' do
        let(:service) { described_class.new(group, maintainer, token.token) }

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when current_user is not a member' do
        let(:service) { described_class.new(group, user, token.token) }

        it_behaves_like 'an unsuccessfully revoked token'
      end
    end

    context 'with an unsupported token type' do
      let(:token) { create(:oauth_access_token) }

      it_behaves_like 'an unsuccessfully revoked token'
    end

    context 'with a plaintext that does not exist' do
      let(:plaintext) { 'glpat-abc123' }
      let(:service) { described_class.new(group, owner, plaintext) }

      it { expect(result.success?).to be(false) }
    end

    context 'with a nil plaintext' do
      let(:plaintext) { nil }
      let(:service) { described_class.new(group, owner, plaintext) }

      it { expect(result.success?).to be(false) }
    end
  end
end
