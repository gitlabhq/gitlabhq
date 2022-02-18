# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreateService, :aggregate_failures, :clean_gitlab_redis_cache, :clean_gitlab_redis_shared_state, :sidekiq_inline do
  let_it_be(:source, reload: true) { create(:project) }
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

      it 'triggers a members added event' do
        expect(Gitlab::EventStore)
          .to receive(:publish)
          .with(an_instance_of(Members::MembersAddedEvent))
          .and_call_original

        expect(execute_service[:status]).to eq(:success)
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
      expect(execute_service[:message]).to eq("The member's email address has already been taken")
      expect(OnboardingProgress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when tracking the invite source', :snowplow do
    context 'when invite_source is not passed' do
      let(:additional_params) { {} }

      it 'raises an error' do
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

      context 'with an already existing member' do
        before do
          source.add_developer(member)
        end

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

  context 'when assigning tasks to be done' do
    let(:additional_params) do
      { invite_source: '_invite_source_', tasks_to_be_done: %w(ci code), tasks_project_id: source.id }
    end

    it 'creates 2 task issues', :aggregate_failures do
      expect(TasksToBeDone::CreateWorker)
        .to receive(:perform_async)
        .with(anything, user.id, [member.id])
        .once
        .and_call_original
      expect { execute_service }.to change { source.issues.count }.by(2)

      expect(source.issues).to all have_attributes(
        project: source,
        author: user
      )
    end

    context 'when passing many user ids' do
      before do
        stub_licensed_features(multiple_issue_assignees: false)
      end

      let(:another_user) { create(:user) }
      let(:user_ids) { [member.id, another_user.id].join(',') }

      it 'still creates 2 task issues', :aggregate_failures do
        expect(TasksToBeDone::CreateWorker)
          .to receive(:perform_async)
          .with(anything, user.id, array_including(member.id, another_user.id))
          .once
          .and_call_original
        expect { execute_service }.to change { source.issues.count }.by(2)

        expect(source.issues).to all have_attributes(
          project: source,
          author: user
        )
      end
    end

    context 'when a `tasks_project_id` is missing' do
      let(:additional_params) do
        { invite_source: '_invite_source_', tasks_to_be_done: %w(ci code) }
      end

      it 'does not create task issues' do
        expect(TasksToBeDone::CreateWorker).not_to receive(:perform_async)
        execute_service
      end
    end

    context 'when `tasks_to_be_done` are missing' do
      let(:additional_params) do
        { invite_source: '_invite_source_', tasks_project_id: source.id }
      end

      it 'does not create task issues' do
        expect(TasksToBeDone::CreateWorker).not_to receive(:perform_async)
        execute_service
      end
    end

    context 'when invalid `tasks_to_be_done` are passed' do
      let(:additional_params) do
        { invite_source: '_invite_source_', tasks_project_id: source.id, tasks_to_be_done: %w(invalid_task) }
      end

      it 'does not create task issues' do
        expect(TasksToBeDone::CreateWorker).not_to receive(:perform_async)
        execute_service
      end
    end

    context 'when invalid `tasks_project_id` is passed' do
      let(:another_project) { create(:project) }
      let(:additional_params) do
        { invite_source: '_invite_source_', tasks_project_id: another_project.id, tasks_to_be_done: %w(ci code) }
      end

      it 'does not create task issues' do
        expect(TasksToBeDone::CreateWorker).not_to receive(:perform_async)
        execute_service
      end
    end

    context 'when a member was already invited' do
      let(:user_ids) { create(:project_member, :invited, project: source).invite_email }
      let(:additional_params) do
        { invite_source: '_invite_source_', tasks_project_id: source.id, tasks_to_be_done: %w(ci code) }
      end

      it 'does not create task issues' do
        expect(TasksToBeDone::CreateWorker).not_to receive(:perform_async)
        execute_service
      end
    end
  end
end
