# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreateService, :aggregate_failures, :clean_gitlab_redis_cache, :clean_gitlab_redis_shared_state, :sidekiq_inline do
  let_it_be(:source) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:member) { create(:user) }
  let_it_be(:user_ids) { member.id.to_s }
  let_it_be(:access_level) { Gitlab::Access::GUEST }

  let(:additional_params) { { invite_source: '_invite_source_' } }
  let(:params) { { user_ids: user_ids, access_level: access_level }.merge(additional_params) }

  subject(:execute_service) { described_class.new(user, params.merge({ source: source })).execute }

  before do
    if source.is_a?(Project)
      source.add_maintainer(user)
      OnboardingProgress.onboard(source.namespace)
    else
      source.add_owner(user)
      OnboardingProgress.onboard(source)
    end
  end

  context 'when passing valid parameters' do
    it 'adds a user to members' do
      expect(execute_service[:status]).to eq(:success)
      expect(source.users).to include member
      expect(OnboardingProgress.completed?(source.namespace, :user_added)).to be(true)
    end

    context 'when executing on a group' do
      let_it_be(:source) { create(:group) }

      it 'adds a user to members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include member
        expect(OnboardingProgress.completed?(source, :user_added)).to be(true)
      end
    end
  end

  context 'when passing no user ids' do
    let(:user_ids) { '' }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(source.users).not_to include member
      expect(OnboardingProgress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when passing many user ids' do
    let(:user_ids) { 1.upto(101).to_a.join(',') }

    it 'limits the number of users to 100' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(source.users).not_to include member
      expect(OnboardingProgress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when passing an invalid access level' do
    let(:access_level) { -1 }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to include("#{member.username}: Access level is not included in the list")
      expect(source.users).not_to include member
      expect(OnboardingProgress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when passing an existing invite user id' do
    let(:user_ids) { create(:project_member, :invited, project: source).invite_email }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to eq('Invite email has already been taken')
      expect(OnboardingProgress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when tracking the invite source', :snowplow do
    context 'when invite_source is not passed' do
      let(:additional_params) { {} }

      it 'tracks the invite source as unknown' do
        expect { execute_service }.to raise_error(ArgumentError, 'No invite source provided.')

        expect_no_snowplow_event
      end
    end

    context 'when invite_source is passed' do
      it 'tracks the invite source from params' do
        execute_service

        expect_snowplow_event(
          category: described_class.name,
          action: 'create_member',
          label: '_invite_source_',
          property: 'existing_user',
          user: user
        )
      end
    end

    context 'when it is a net_new_user' do
      let(:additional_params) { { invite_source: '_invite_source_', user_ids: 'email@example.org' } }

      it 'tracks the invite source from params' do
        execute_service

        expect_snowplow_event(
          category: described_class.name,
          action: 'create_member',
          label: '_invite_source_',
          property: 'net_new_user',
          user: user
        )
      end
    end
  end
end
