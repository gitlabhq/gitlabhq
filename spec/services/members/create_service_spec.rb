# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreateService, :aggregate_failures, :clean_gitlab_redis_cache, :clean_gitlab_redis_shared_state, :sidekiq_inline,
  feature_category: :groups_and_projects do
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
    when Group
      source.add_owner(user)
    end
  end

  context 'when the current user does not have permission to create members' do
    let(:current_user) { create(:user) }

    it 'returns an unauthorized http_status' do
      expect(execute_service[:status]).to eq(:error)
      # this is expected by API::Helpers::MembersHelpers#add_single_member_by_user_id
      expect(execute_service[:http_status]).to eq(:unauthorized)
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

  context 'when trying to create a Membership with invalid params' do
    let(:additional_params) { Hash[invite_source: '_invite_source_', expires_at: 3.days.ago] }

    it 'returns an error response' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:http_status]).to be_nil
    end
  end

  context 'when passing valid parameters' do
    it 'adds a user to members' do
      expect(execute_service[:status]).to eq(:success)
      expect(source.users).to include member
    end

    context 'when user_id is passed as an integer' do
      let(:user_id) { member.id }

      it 'successfully creates member' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include member
      end
    end

    context 'with user_id as an array of integers' do
      let(:user_id) { [member.id, user_invited_by_id.id] }

      it 'successfully creates members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include(member, user_invited_by_id)
      end
    end

    context 'with user_id as an array of strings' do
      let(:user_id) { [member.id.to_s, user_invited_by_id.id.to_s] }

      it 'successfully creates members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include(member, user_invited_by_id)
      end
    end

    context 'when composite identity is being used' do
      context 'when a member has composite identity' do
        before do
          allow(member).to receive(:composite_identity_enforced).and_return(true)
        end

        it 'successfuly adds a project member' do
          expect(execute_service[:status]).to eq(:success)
          expect(source.users).to include member
        end
      end

      context 'when the user has composite identity' do
        before do
          allow(user).to receive(:composite_identity_enforced).and_return(true)
        end

        it 'returns unauthorized error' do
          expect(execute_service[:status]).to eq(:error)
          expect(execute_service[:http_status]).to eq(:unauthorized)
        end
      end
    end

    context 'when executing on a group' do
      let_it_be(:source) { create(:group) }

      it 'adds a user to members' do
        expect(execute_service[:status]).to eq(:success)
        expect(source).to have_user(member)
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
        allow(Gitlab::EventStore).to receive(:publish)
      end

      it 'triggers the authorizations changed events' do
        expect(Gitlab::EventStore)
          .to receive(:publish_group)
                .with(array_including(an_instance_of(ProjectAuthorizations::AuthorizationsAddedEvent)))
                .and_call_original

        execute_service
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
      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
              .with(an_instance_of(described_class::BlankInvitesError), class: described_class.to_s, user_id: user.id)
      expect(Gitlab::EventStore)
        .not_to receive(:publish)
        .with(an_instance_of(Members::MembersAddedEvent))

      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to eq(s_('AddMember|No users specified.'))
      expect(execute_service[:reason]).to eq(:blank_invites_error)
      expect(source.users).not_to include member
    end
  end

  context 'when passing many user ids' do
    let(:user_id) { 1.upto(101).to_a.join(',') }

    it 'limits the number of users to 100' do
      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
              .with(an_instance_of(described_class::TooManyInvitesError), class: described_class.to_s, user_id: user.id)

      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(execute_service[:reason]).to eq(:too_many_invites_error)
      expect(source.users).not_to include member
    end
  end

  context 'when passing an invalid access level' do
    let(:access_level) { -1 }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to include("#{member.username}: Access level is not included in the list")
      expect(source.users).not_to include member
    end
  end

  context 'when passing an existing invite user id' do
    let(:invited_member) { create(:project_member, :guest, :invited, project: source) }
    let(:user_id) { invited_member.invite_email }
    let(:access_level) { ProjectMember::MAINTAINER }

    it 'allows already invited members to be re-invited by email and updates the member access' do
      expect(execute_service[:status]).to eq(:success)
      expect(invited_member.reset.access_level).to eq ProjectMember::MAINTAINER
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
        expect(execute_service[:http_status]).to eq(:unauthorized)
        expect(execute_service[:message]).to eq("#{project_bot.username}: not authorized to update member")
      end
    end

    context 'when project_bot is not already a member' do
      it 'adds the member' do
        expect(execute_service[:status]).to eq(:success)
        expect(source.users).to include project_bot
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

  context 'with raised errors' do
    using RSpec::Parameterized::TableSyntax

    where(:error, :stubbed_method, :reason) do
      described_class::BlankInvitesError      | :validate_invite_source! | :blank_invites_error
      described_class::TooManyInvitesError    | :validate_invitable!     | :too_many_invites_error
      described_class::MembershipLockedError  | :add_members             | :membership_locked_error
      described_class::SeatLimitExceededError | :add_members             | :seat_limit_exceeded_error
    end

    with_them do
      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(stubbed_method).and_raise(error)
        end
      end

      it 'returns the correct reason' do
        expect(execute_service[:reason]).to eq(reason)
      end
    end
  end
end
