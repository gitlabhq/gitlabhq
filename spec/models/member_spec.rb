# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Member do
  include ExclusiveLeaseHelpers

  using RSpec::Parameterized::TableSyntax

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Validation" do
    subject { described_class.new(access_level: Member::GUEST) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:source) }

    context 'expires_at' do
      it { is_expected.not_to allow_value(Date.yesterday).for(:expires_at) }
      it { is_expected.to allow_value(Date.tomorrow).for(:expires_at) }
      it { is_expected.to allow_value(Date.today).for(:expires_at) }
      it { is_expected.to allow_value(nil).for(:expires_at) }
    end

    it_behaves_like 'an object with email-formated attributes', :invite_email do
      subject { build(:project_member) }
    end

    context "when an invite email is provided" do
      let_it_be(:project) { create(:project) }
      let(:member) { build(:project_member, source: project, invite_email: "user@example.com", user: nil) }

      it "doesn't require a user" do
        expect(member).to be_valid
      end

      it "requires a valid invite email" do
        member.invite_email = "nope"

        expect(member).not_to be_valid
      end

      it "requires a unique invite email scoped to this source" do
        create(:project_member, source: member.source, invite_email: member.invite_email)

        expect(member).not_to be_valid
      end
    end

    context "when an invite email is not provided" do
      let(:member) { build(:project_member) }

      it "requires a user" do
        member.user = nil

        expect(member).not_to be_valid
      end

      it "is valid otherwise" do
        expect(member).to be_valid
      end
    end

    context "when a child member inherits its access level" do
      let(:user) { create(:user) }
      let(:member) { create(:group_member, :developer, user: user) }
      let(:child_group) { create(:group, parent: member.group) }
      let(:child_member) { build(:group_member, group: child_group, user: user) }

      it "requires a higher level" do
        child_member.access_level = GroupMember::REPORTER

        child_member.validate

        expect(child_member).not_to be_valid
      end

      # Membership in a subgroup confers certain access rights, such as being
      # able to merge or push code to protected branches.
      it "is valid with an equal level" do
        child_member.access_level = GroupMember::DEVELOPER

        child_member.validate

        expect(child_member).to be_valid
      end

      it "is valid with a higher level" do
        child_member.access_level = GroupMember::MAINTAINER

        child_member.validate

        expect(child_member).to be_valid
      end
    end

    context 'project bots' do
      let_it_be(:project_bot) { create(:user, :project_bot) }
      let(:new_member) { build(:project_member, user_id: project_bot.id) }

      context 'not a member of any group or project' do
        it 'is valid' do
          expect(new_member).to be_valid
        end
      end

      context 'already member of a project' do
        before do
          unrelated_project = create(:project)
          unrelated_project.add_maintainer(project_bot)
        end

        it 'is not valid' do
          expect(new_member).not_to be_valid
        end
      end
    end
  end

  describe 'Scopes & finders' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:group) { create(:group) }

    before_all do
      @owner_user = create(:user).tap { |u| group.add_owner(u) }
      @owner = group.members.find_by(user_id: @owner_user.id)

      @maintainer_user = create(:user).tap { |u| project.add_maintainer(u) }
      @maintainer = project.members.find_by(user_id: @maintainer_user.id)

      @blocked_user = create(:user).tap do |u|
        project.add_maintainer(u)
        project.add_developer(u)

        u.block!
      end
      @blocked_maintainer = project.members.find_by(user_id: @blocked_user.id, access_level: Gitlab::Access::MAINTAINER)
      @blocked_developer = project.members.find_by(user_id: @blocked_user.id, access_level: Gitlab::Access::DEVELOPER)

      @invited_member = create(:project_member, :developer,
                              project: project,
                              invite_token: '1234',
                              invite_email: 'toto1@example.com')

      accepted_invite_user = build(:user, state: :active)
      @accepted_invite_member = create(:project_member, :developer,
                                      project: project,
                                      invite_token: '1234',
                                      invite_email: 'toto2@example.com')
                                      .tap { |u| u.accept_invite!(accepted_invite_user) }

      requested_user = create(:user).tap { |u| project.request_access(u) }
      @requested_member = project.requesters.find_by(user_id: requested_user.id)

      accepted_request_user = create(:user).tap { |u| project.request_access(u) }
      @accepted_request_member = project.requesters.find_by(user_id: accepted_request_user.id).tap { |m| m.accept_request }
      @member_with_minimal_access = create(:group_member, :minimal_access, source: group)
    end

    describe '.access_for_user_ids' do
      it 'returns the right access levels' do
        users = [@owner_user.id, @maintainer_user.id, @blocked_user.id]
        expected = {
          @owner_user.id => Gitlab::Access::OWNER,
          @maintainer_user.id => Gitlab::Access::MAINTAINER
        }

        expect(described_class.access_for_user_ids(users)).to eq(expected)
      end
    end

    describe '.invite' do
      it { expect(described_class.invite).not_to include @maintainer }
      it { expect(described_class.invite).to include @invited_member }
      it { expect(described_class.invite).not_to include @accepted_invite_member }
      it { expect(described_class.invite).not_to include @requested_member }
      it { expect(described_class.invite).not_to include @accepted_request_member }
    end

    describe '.non_invite' do
      it { expect(described_class.non_invite).to include @maintainer }
      it { expect(described_class.non_invite).not_to include @invited_member }
      it { expect(described_class.non_invite).to include @accepted_invite_member }
      it { expect(described_class.non_invite).to include @requested_member }
      it { expect(described_class.non_invite).to include @accepted_request_member }
    end

    describe '.non_minimal_access' do
      it { expect(described_class.non_minimal_access).to include @maintainer }
      it { expect(described_class.non_minimal_access).to include @invited_member }
      it { expect(described_class.non_minimal_access).to include @accepted_invite_member }
      it { expect(described_class.non_minimal_access).to include @requested_member }
      it { expect(described_class.non_minimal_access).to include @accepted_request_member }
      it { expect(described_class.non_minimal_access).not_to include @member_with_minimal_access }
    end

    describe '.request' do
      it { expect(described_class.request).not_to include @maintainer }
      it { expect(described_class.request).not_to include @invited_member }
      it { expect(described_class.request).not_to include @accepted_invite_member }
      it { expect(described_class.request).to include @requested_member }
      it { expect(described_class.request).not_to include @accepted_request_member }
    end

    describe '.non_request' do
      it { expect(described_class.non_request).to include @maintainer }
      it { expect(described_class.non_request).to include @invited_member }
      it { expect(described_class.non_request).to include @accepted_invite_member }
      it { expect(described_class.non_request).not_to include @requested_member }
      it { expect(described_class.non_request).to include @accepted_request_member }
    end

    describe '.not_accepted_invitations' do
      let_it_be(:not_accepted_invitation) { create(:project_member, :invited) }
      let_it_be(:accepted_invitation) { create(:project_member, :invited, invite_accepted_at: Date.today) }

      subject { described_class.not_accepted_invitations }

      it { is_expected.to include(not_accepted_invitation) }
      it { is_expected.not_to include(accepted_invitation) }
    end

    describe '.not_accepted_invitations_by_user' do
      let(:invited_by_user) { create(:project_member, :invited, project: project, created_by: @owner_user) }

      before do
        create(:project_member, :invited, invite_email: 'test@test.com', project: project, created_by: @owner_user, invite_accepted_at: Time.zone.now)
        create(:project_member, :invited, invite_email: 'test2@test.com', project: project, created_by: @maintainer_user)
      end

      subject { described_class.not_accepted_invitations_by_user(@owner_user) }

      it { is_expected.to contain_exactly(invited_by_user) }
    end

    describe '.not_expired' do
      let_it_be(:expiring_yesterday) { create(:group_member, expires_at: 1.day.from_now) }
      let_it_be(:expiring_today) { create(:group_member, expires_at: 2.days.from_now) }
      let_it_be(:expiring_tomorrow) { create(:group_member, expires_at: 3.days.from_now) }
      let_it_be(:not_expiring) { create(:group_member) }

      subject { described_class.not_expired }

      around do |example|
        travel_to(2.days.from_now) { example.run }
      end

      it { is_expected.not_to include(expiring_yesterday, expiring_today) }
      it { is_expected.to include(expiring_tomorrow, not_expiring) }
    end

    describe '.last_ten_days_excluding_today' do
      let_it_be(:now) { Time.current }
      let_it_be(:created_today) { create(:group_member, created_at: now.beginning_of_day) }
      let_it_be(:created_yesterday) { create(:group_member, created_at: now - 1.day) }
      let_it_be(:created_eleven_days_ago) { create(:group_member, created_at: now - 11.days) }

      subject { described_class.last_ten_days_excluding_today }

      before do
        travel_to now
      end

      it { is_expected.to include(created_yesterday) }
      it { is_expected.not_to include(created_today, created_eleven_days_ago) }
    end

    describe '.search_invite_email' do
      it 'returns only members the matching e-mail' do
        create(:group_member, :invited)

        invited = described_class.search_invite_email(@invited_member.invite_email)

        expect(invited.count).to eq(1)
        expect(invited.first).to eq(@invited_member)

        expect(described_class.search_invite_email('bad-email@example.com').count).to eq(0)
      end
    end

    describe '.developers' do
      subject { described_class.developers.to_a }

      it { is_expected.not_to include @owner }
      it { is_expected.not_to include @maintainer }
      it { is_expected.to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.not_to include @blocked_maintainer }
      it { is_expected.not_to include @blocked_developer }
    end

    describe '.owners_and_maintainers' do
      it { expect(described_class.owners_and_maintainers).to include @owner }
      it { expect(described_class.owners_and_maintainers).to include @maintainer }
      it { expect(described_class.owners_and_maintainers).not_to include @invited_member }
      it { expect(described_class.owners_and_maintainers).not_to include @accepted_invite_member }
      it { expect(described_class.owners_and_maintainers).not_to include @requested_member }
      it { expect(described_class.owners_and_maintainers).not_to include @accepted_request_member }
      it { expect(described_class.owners_and_maintainers).not_to include @blocked_maintainer }
    end

    describe '.has_access' do
      subject { described_class.has_access.to_a }

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.not_to include @blocked_maintainer }
      it { is_expected.not_to include @blocked_developer }
    end

    describe '.active' do
      subject { described_class.active.to_a }

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.not_to include @blocked_maintainer }
      it { is_expected.not_to include @blocked_developer }
      it { is_expected.not_to include @member_with_minimal_access }
    end

    describe '.active_without_invites_and_requests' do
      subject { described_class.active_without_invites_and_requests.to_a }

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.not_to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.not_to include @blocked_maintainer }
      it { is_expected.not_to include @blocked_developer }
      it { is_expected.not_to include @member_with_minimal_access }
    end
  end

  describe "Delegate methods" do
    it { is_expected.to respond_to(:user_name) }
    it { is_expected.to respond_to(:user_email) }
  end

  describe '.add_user' do
    %w[project group].each do |source_type|
      context "when source is a #{source_type}" do
        let_it_be(:source, reload: true) { create(source_type, :public) }
        let_it_be(:user) { create(:user) }
        let_it_be(:admin) { create(:admin) }

        it 'returns a <Source>Member object' do
          member = described_class.add_user(source, user, :maintainer)

          expect(member).to be_a "#{source_type.classify}Member".constantize
          expect(member).to be_persisted
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'sets members.created_by to the given admin current_user' do
            member = described_class.add_user(source, user, :maintainer, current_user: admin)

            expect(member.created_by).to eq(admin)
          end
        end

        context 'when admin mode is disabled' do
          # Skipped because `Group#max_member_access_for_user` needs to be migrated to use admin mode
          # https://gitlab.com/gitlab-org/gitlab/-/issues/207950
          xit 'rejects setting members.created_by to the given admin current_user' do
            member = described_class.add_user(source, user, :maintainer, current_user: admin)

            expect(member.created_by).not_to be_persisted
          end
        end

        it 'sets members.expires_at to the given expires_at' do
          member = described_class.add_user(source, user, :maintainer, expires_at: Date.new(2016, 9, 22))

          expect(member.expires_at).to eq(Date.new(2016, 9, 22))
        end

        described_class.access_levels.each do |sym_key, int_access_level|
          it "accepts the :#{sym_key} symbol as access level" do
            expect(source.users).not_to include(user)

            member = described_class.add_user(source, user.id, sym_key)

            expect(member.access_level).to eq(int_access_level)
            expect(source.users.reload).to include(user)
          end

          it "accepts the #{int_access_level} integer as access level" do
            expect(source.users).not_to include(user)

            member = described_class.add_user(source, user.id, int_access_level)

            expect(member.access_level).to eq(int_access_level)
            expect(source.users.reload).to include(user)
          end
        end

        context 'with no current_user' do
          context 'when called with a known user id' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, user.id, :maintainer)

              expect(source.users.reload).to include(user)
            end
          end

          context 'when called with an unknown user id' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, non_existing_record_id, :maintainer)

              expect(source.users.reload).not_to include(user)
            end
          end

          context 'when called with a user object' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, user, :maintainer)

              expect(source.users.reload).to include(user)
            end
          end

          context 'when called with a requester user object' do
            before do
              source.request_access(user)
            end

            it 'adds the requester as a member' do
              expect(source.users).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy

              expect { described_class.add_user(source, user, :maintainer) }
                .to raise_error(Gitlab::Access::AccessDeniedError)

              expect(source.users.reload).not_to include(user)
              expect(source.requesters.reload.exists?(user_id: user)).to be_truthy
            end
          end

          context 'when called with a known user email' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, user.email, :maintainer)

              expect(source.users.reload).to include(user)
            end
          end

          context 'when called with an unknown user email' do
            it 'creates an invited member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, 'user@example.com', :maintainer)

              expect(source.members.invite.pluck(:invite_email)).to include('user@example.com')
            end
          end

          context 'when called with an unknown user email starting with a number' do
            it 'creates an invited member', :aggregate_failures do
              email_starting_with_number = "#{user.id}_email@example.com"

              described_class.add_user(source, email_starting_with_number, :maintainer)

              expect(source.members.invite.pluck(:invite_email)).to include(email_starting_with_number)
              expect(source.users.reload).not_to include(user)
            end
          end
        end

        context 'when current_user can update member', :enable_admin_mode do
          it 'creates the member' do
            expect(source.users).not_to include(user)

            described_class.add_user(source, user, :maintainer, current_user: admin)

            expect(source.users.reload).to include(user)
          end

          context 'when called with a requester user object' do
            before do
              source.request_access(user)
            end

            it 'adds the requester as a member' do
              expect(source.users).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy

              described_class.add_user(source, user, :maintainer, current_user: admin)

              expect(source.users.reload).to include(user)
              expect(source.requesters.reload.exists?(user_id: user)).to be_falsy
            end
          end
        end

        context 'when current_user cannot update member' do
          it 'does not create the member' do
            expect(source.users).not_to include(user)

            member = described_class.add_user(source, user, :maintainer, current_user: user)

            expect(source.users.reload).not_to include(user)
            expect(member).not_to be_persisted
          end

          context 'when called with a requester user object' do
            before do
              source.request_access(user)
            end

            it 'does not destroy the requester' do
              expect(source.users).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy

              described_class.add_user(source, user, :maintainer, current_user: user)

              expect(source.users.reload).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy
            end
          end
        end

        context 'when member already exists' do
          before do
            source.add_user(user, :developer)
          end

          context 'with no current_user' do
            it 'updates the member' do
              expect(source.users).to include(user)

              described_class.add_user(source, user, :maintainer)

              expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MAINTAINER)
            end
          end

          context 'when current_user can update member', :enable_admin_mode do
            it 'updates the member' do
              expect(source.users).to include(user)

              described_class.add_user(source, user, :maintainer, current_user: admin)

              expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MAINTAINER)
            end
          end

          context 'when current_user cannot update member' do
            it 'does not update the member' do
              expect(source.users).to include(user)

              described_class.add_user(source, user, :maintainer, current_user: user)

              expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::DEVELOPER)
            end
          end
        end
      end
    end
  end

  describe '.add_users' do
    %w[project group].each do |source_type|
      context "when source is a #{source_type}" do
        let_it_be(:source) { create(source_type, :public) }
        let_it_be(:admin) { create(:admin) }
        let_it_be(:user1) { create(:user) }
        let_it_be(:user2) { create(:user) }

        it 'returns a <Source>Member objects' do
          members = described_class.add_users(source, [user1, user2], :maintainer)

          expect(members).to be_a Array
          expect(members.size).to eq(2)
          expect(members.first).to be_a "#{source_type.classify}Member".constantize
          expect(members.first).to be_persisted
        end

        it 'returns an empty array' do
          members = described_class.add_users(source, [], :maintainer)

          expect(members).to be_a Array
          expect(members).to be_empty
        end

        it 'supports differents formats' do
          list = ['joe@local.test', admin, user1.id, user2.id.to_s]

          members = described_class.add_users(source, list, :maintainer)

          expect(members.size).to eq(4)
          expect(members.first).to be_invite
        end
      end
    end
  end

  describe '#accept_request' do
    let(:member) { create(:project_member, requested_at: Time.current.utc) }

    it { expect(member.accept_request).to be_truthy }

    it 'clears requested_at' do
      member.accept_request

      expect(member.requested_at).to be_nil
    end

    it 'calls #after_accept_request' do
      expect(member).to receive(:after_accept_request)

      member.accept_request
    end
  end

  describe '#invite?' do
    subject { create(:project_member, invite_email: "user@example.com", user: nil) }

    it { is_expected.to be_invite }
  end

  describe '#request?' do
    subject { create(:project_member, requested_at: Time.current.utc) }

    it { is_expected.to be_request }
  end

  describe '#pending?' do
    let(:invited_member) { create(:project_member, invite_email: "user@example.com", user: nil) }
    let(:requester) { create(:project_member, requested_at: Time.current.utc) }

    it { expect(invited_member).to be_invite }
    it { expect(requester).to be_pending }
  end

  describe "#accept_invite!" do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }
    let(:user) { create(:user) }

    it "resets the invite token" do
      member.accept_invite!(user)

      expect(member.invite_token).to be_nil
    end

    it "sets the invite accepted timestamp" do
      member.accept_invite!(user)

      expect(member.invite_accepted_at).not_to be_nil
    end

    it "sets the user" do
      member.accept_invite!(user)

      expect(member.user).to eq(user)
    end

    it "calls #after_accept_invite" do
      expect(member).to receive(:after_accept_invite)

      member.accept_invite!(user)
    end

    it "refreshes user's authorized projects", :delete do
      project = member.source

      expect(user.authorized_projects).not_to include(project)

      member.accept_invite!(user)

      expect(user.authorized_projects.reload).to include(project)
    end
  end

  describe "#decline_invite!" do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it "destroys the member" do
      member.decline_invite!

      expect(member).to be_destroyed
    end

    it "calls #after_decline_invite" do
      expect(member).to receive(:after_decline_invite)

      member.decline_invite!
    end
  end

  describe "#generate_invite_token" do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it "sets the invite token" do
      expect { member.generate_invite_token }.to change { member.invite_token}
    end
  end

  describe '.find_by_invite_token' do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it 'finds the member' do
      expect(described_class.find_by_invite_token(member.raw_invite_token)).to eq member
    end
  end

  describe '#send_invitation_reminder' do
    subject { member.send_invitation_reminder(0) }

    context 'an invited group member' do
      let!(:member) { create(:group_member, :invited) }

      it 'sends a reminder' do
        expect_any_instance_of(NotificationService).to receive(:invite_member_reminder).with(member, member.raw_invite_token, 0)

        subject
      end
    end

    context 'an invited member without a raw invite token set' do
      let!(:member) { create(:group_member, :invited) }

      before do
        member.instance_variable_set(:@raw_invite_token, nil)
        allow_any_instance_of(NotificationService).to receive(:invite_member_reminder)
      end

      it 'generates a new token' do
        expect(member).to receive(:generate_invite_token!)

        subject
      end
    end

    context 'an uninvited member' do
      let!(:member) { create(:group_member) }

      it 'does not send a reminder' do
        expect_any_instance_of(NotificationService).not_to receive(:invite_member_reminder)

        subject
      end
    end
  end

  describe "#invite_to_unknown_user?" do
    subject { member.invite_to_unknown_user? }

    let(:member) { create(:project_member, invite_email: "user@example.com", invite_token: '1234', user: user) }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to eq(true) }
    end

    context 'when user is set' do
      let(:user) { build(:user) }

      it { is_expected.to eq(false) }
    end
  end

  describe "destroying a record", :delete do
    it "refreshes user's authorized projects" do
      project = create(:project, :private)
      user    = create(:user)
      member  = project.add_reporter(user)

      member.destroy

      expect(user.authorized_projects).not_to include(project)
    end
  end

  context 'when after_commit :update_highest_role' do
    let!(:user) { create(:user) }
    let(:user_id) { user.id }

    where(:member_type, :source_type) do
      :project_member | :project
      :group_member   | :group
    end

    with_them do
      describe 'create member' do
        let!(:source) { create(source_type) }

        subject { create(member_type, :guest, user: user, source: source) }

        include_examples 'update highest role with exclusive lease'
      end

      context 'when member exists' do
        let!(:member) { create(member_type, user: user) }

        describe 'update member' do
          context 'when access level was changed' do
            subject { member.update(access_level: Gitlab::Access::GUEST) }

            include_examples 'update highest role with exclusive lease'
          end

          context 'when access level was not changed' do
            subject { member.update(notification_level: NotificationSetting.levels[:disabled]) }

            include_examples 'does not update the highest role'
          end
        end

        describe 'destroy member' do
          subject { member.destroy }

          include_examples 'update highest role with exclusive lease'
        end
      end
    end
  end
end
