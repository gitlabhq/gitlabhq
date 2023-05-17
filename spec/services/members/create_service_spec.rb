# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreateService, :aggregate_failures, :clean_gitlab_redis_cache, :clean_gitlab_redis_shared_state, :sidekiq_inline,
  feature_category: :subgroups do
  let_it_be(:source, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:member) { create(:user) }
  let_it_be(:user_invited_by_id) { create(:user) }
  let_it_be(:user_id) { member.id.to_s }
  let_it_be(:access_level) { Gitlab::Access::GUEST }

  let(:additional_params) { { invite_source: '_invite_source_' } }
  let(:params) { { user_id: user_id, access_level: access_level }.merge(additional_params) }
  let(:current_user) { user }

  subject(:execute_service) { described_class.new(current_user, params.merge({ source: source })).execute }

  before do
    case source
    when Project
      source.add_maintainer(user)
      Onboarding::Progress.onboard(source.namespace)
    when Group
      source.add_owner(user)
      Onboarding::Progress.onboard(source)
    end
  end

  context 'when the current user does not have permission to create members' do
    let(:current_user) { create(:user) }

    it 'raises a Gitlab::Access::AccessDeniedError' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end

    context 'when a project maintainer attempts to add owners' do
      let(:access_level) { Gitlab::Access::OWNER }

      before do
        source.add_maintainer(current_user)
      end

      it 'raises a Gitlab::Access::AccessDeniedError' do
        expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  context 'when passing an invalid source' do
    let_it_be(:source) { Object.new }

    it 'raises a RuntimeError' do
      expect { execute_service }.to raise_error(RuntimeError, 'Unknown source type: Object!')
    end
  end

  context 'when passing valid parameters' do
    it 'adds a user to members' do
      expect(execute_service[:status]).to eq(:success)
      expect(source.users).to include member
      expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(true)
    end

    context 'when user_id is passed as an integer' do
      let(:user_id) { member.id }

      it 'successfully creates member' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include member
        expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(true)
      end
    end

    context 'with user_id as an array of integers' do
      let(:user_id) { [member.id, user_invited_by_id.id] }

      it 'successfully creates members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include(member, user_invited_by_id)
        expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(true)
      end
    end

    context 'with user_id as an array of strings' do
      let(:user_id) { [member.id.to_s, user_invited_by_id.id.to_s] }

      it 'successfully creates members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include(member, user_invited_by_id)
        expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(true)
      end
    end

    context 'when executing on a group' do
      let_it_be(:source) { create(:group) }

      it 'adds a user to members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include member
        expect(Onboarding::Progress.completed?(source, :user_added)).to be(true)
      end

      it 'triggers a members added event' do
        expect(Gitlab::EventStore)
          .to receive(:publish)
          .with(an_instance_of(Members::MembersAddedEvent))
          .and_call_original

        expect(execute_service[:status]).to eq(:success)
      end
    end

    context 'when only one user fails validations' do
      let_it_be(:source) { create(:project, group: create(:group)) }
      let(:user_id) { [member.id, user_invited_by_id.id] }

      before do
        # validations will fail because we try to invite them to the project as a guest
        source.group.add_developer(member)
      end

      it 'triggers the members added event' do
        expect(Gitlab::EventStore)
          .to receive(:publish)
          .with(an_instance_of(Members::MembersAddedEvent))
          .and_call_original

        expect(execute_service[:status]).to eq(:error)
        expect(execute_service[:message])
          .to include 'Access level should be greater than or equal to Developer inherited membership from group'
        expect(source.users).not_to include(member)
        expect(source.users).to include(user_invited_by_id)
      end
    end

    context 'when all users fail validations' do
      let_it_be(:source) { create(:project, group: create(:group)) }
      let(:user_id) { [member.id, user_invited_by_id.id] }

      before do
        # validations will fail because we try to invite them to the project as a guest
        source.group.add_developer(member)
        source.group.add_developer(user_invited_by_id)
      end

      it 'does not trigger the members added event' do
        expect(Gitlab::EventStore)
          .not_to receive(:publish)
          .with(an_instance_of(Members::MembersAddedEvent))

        expect(execute_service[:status]).to eq(:error)
        expect(execute_service[:message])
          .to include 'Access level should be greater than or equal to Developer inherited membership from group'
        expect(source.users).not_to include(member, user_invited_by_id)
      end
    end
  end

  context 'when passing no user ids' do
    let(:user_id) { '' }

    it 'does not add a member' do
      expect(Gitlab::EventStore)
        .not_to receive(:publish)
        .with(an_instance_of(Members::MembersAddedEvent))

      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(source.users).not_to include member
      expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when passing many user ids' do
    let(:user_id) { 1.upto(101).to_a.join(',') }

    it 'limits the number of users to 100' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(source.users).not_to include member
      expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when passing an invalid access level' do
    let(:access_level) { -1 }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to include("#{member.username}: Access level is not included in the list")
      expect(source.users).not_to include member
      expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(false)
    end
  end

  context 'when passing an existing invite user id' do
    let(:invited_member) { create(:project_member, :guest, :invited, project: source) }
    let(:user_id) { invited_member.invite_email }
    let(:access_level) { ProjectMember::MAINTAINER }

    it 'allows already invited members to be re-invited by email and updates the member access' do
      expect(execute_service[:status]).to eq(:success)
      expect(invited_member.reset.access_level).to eq ProjectMember::MAINTAINER
      expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(true)
    end
  end

  context 'when adding a project_bot' do
    let_it_be(:project_bot) { create(:user, :project_bot) }

    let(:user_id) { project_bot.id }

    context 'when project_bot is already a member' do
      before do
        source.add_developer(project_bot)
      end

      it 'does not update the member' do
        expect(execute_service[:status]).to eq(:error)
        expect(execute_service[:message]).to eq("#{project_bot.username}: not authorized to update member")
        expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(false)
      end
    end

    context 'when project_bot is not already a member' do
      it 'adds the member' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include project_bot
        expect(Onboarding::Progress.completed?(source.namespace, :user_added)).to be(true)
      end
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
      let(:additional_params) { { invite_source: '_invite_source_', user_id: 'email@example.org' } }

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

    context 'when it is an invite by email passed to user_id' do
      let(:user_id) { 'email@example.org' }

      it 'does not create task issues' do
        expect(TasksToBeDone::CreateWorker).not_to receive(:perform_async)
        execute_service
      end
    end

    context 'when passing many user ids' do
      before do
        stub_licensed_features(multiple_issue_assignees: false)
      end

      let(:another_user) { create(:user) }
      let(:user_id) { [member.id, another_user.id].join(',') }

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
      let(:user_id) { create(:project_member, :invited, project: source).invite_email }
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
