# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Member, feature_category: :groups_and_projects do
  include ExclusiveLeaseHelpers

  using RSpec::Parameterized::TableSyntax

  describe 'default values' do
    subject(:member) { build(:project_member) }

    it { expect(member.notification_level).to eq(NotificationSetting.levels[:global]) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:member_namespace) }
  end

  describe 'Validation' do
    subject { described_class.new(access_level: Member::GUEST) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:source) }

    context 'expires_at' do
      it { is_expected.not_to allow_value(Date.yesterday).for(:expires_at) }
      it { is_expected.to allow_value(Date.tomorrow).for(:expires_at) }
      it { is_expected.to allow_value(Date.today).for(:expires_at) }
      it { is_expected.to allow_value(nil).for(:expires_at) }
    end

    it_behaves_like 'an object with email-formatted attributes', :invite_email do
      subject { build(:project_member) }
    end

    context 'when an invite email is provided' do
      let_it_be(:project) { create(:project) }

      let(:member) { build(:project_member, source: project, invite_email: "user@example.com", user: nil) }

      it "doesn't require a user" do
        expect(member).to be_valid
      end

      it 'requires a valid invite email' do
        member.invite_email = "nope"

        expect(member).not_to be_valid
      end

      it 'requires a unique invite email scoped to this source' do
        create(:project_member, source: member.source, invite_email: member.invite_email)

        expect(member).not_to be_valid
      end

      it 'must not be a placeholder email' do
        member.invite_email = 'gitlab_migration_placeholder_user@noreply.localhost'

        expect(member).not_to be_valid
      end
    end

    context 'when an invite email is not provided' do
      let(:member) { build(:project_member) }

      it 'requires a user' do
        member.user = nil

        expect(member).not_to be_valid
      end

      it 'does not allow placeholder users to be members' do
        member.user = create(:user, :placeholder)

        expect(member).not_to be_valid
      end

      it 'is valid otherwise' do
        expect(member).to be_valid
      end
    end

    context 'with admin signup restrictions' do
      let(:expected_message) { _('is not allowed for this group. Check with your administrator.') }

      context 'when allowed domains for signup is enabled' do
        before do
          stub_application_setting(domain_allowlist: ['example.com'])
        end

        it 'adds an error message when email is not accepted' do
          member = build(:group_member, :invited, invite_email: 'info@gitlab.com')

          expect(member).not_to be_valid
          expect(member.errors.messages[:user].first).to eq(expected_message)
        end
      end

      context 'when denylist is enabled' do
        before do
          stub_application_setting(domain_denylist_enabled: true)
          stub_application_setting(domain_denylist: ['example.org'])
        end

        it 'adds an error message when email is denied' do
          member = build(:group_member, :invited, invite_email: 'denylist@example.org')

          expect(member).not_to be_valid
          expect(member.errors.messages[:user].first).to eq(expected_message)
        end
      end

      context 'when email restrictions is enabled' do
        before do
          stub_application_setting(email_restrictions_enabled: true)
          stub_application_setting(email_restrictions: '([\+]|\b(\w*gitlab.com\w*)\b)')
        end

        it 'adds an error message when email is not accepted' do
          member = build(:group_member, :invited, invite_email: 'info@gitlab.com')

          expect(member).not_to be_valid
          expect(member.errors.messages[:user].first).to eq(expected_message)
        end
      end
    end

    context 'when a child member inherits its access level' do
      let(:user) { create(:user) }
      let(:member) { create(:group_member, :developer, user: user) }
      let(:child_group) { create(:group, parent: member.group) }
      let(:child_member) { build(:group_member, group: child_group, user: user) }

      it 'requires a higher level' do
        child_member.access_level = GroupMember::REPORTER

        child_member.validate

        expect(child_member).not_to be_valid
      end

      # Membership in a subgroup confers certain access rights, such as being
      # able to merge or push code to protected branches.
      it 'is valid with an equal level' do
        child_member.access_level = GroupMember::DEVELOPER

        child_member.validate

        expect(child_member).to be_valid
      end

      it 'is valid with a higher level' do
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

    context 'when access_level is nil' do
      let_it_be(:group) { create(:group) }
      let_it_be(:user) { create(:user) }
      let_it_be(:member) { create(:group_member, source: group, user: user) }

      shared_examples 'returns the correct validation error' do
        specify do
          member.access_level = nil

          member.validate

          expect(member.errors.messages[:access_level]).to include("is not included in the list")
        end
      end

      it_behaves_like 'returns the correct validation error'

      context 'for a subgroup member' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:member) { create(:group_member, source: subgroup, user: user) }

        it_behaves_like 'returns the correct validation error'
      end
    end
  end

  describe 'Scopes & finders' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:group) { create(:group) }
    let_it_be(:blocked_pending_approval_user) { create(:user, :blocked_pending_approval) }
    let_it_be(:blocked_pending_approval_project_member) { create(:project_member, :invited, :developer, project: project, invite_email: blocked_pending_approval_user.email) }
    let_it_be(:awaiting_group_member) { create(:group_member, :awaiting, group: group) }
    let_it_be(:awaiting_project_member) { create(:project_member, :awaiting, project: project) }

    before_all do
      @owner_user = create(:user, owner_of: group)
      @owner = group.members.find_by(user_id: @owner_user.id)
      @blocked_owner_user = create(:user).tap do |u|
        group.add_owner(u)

        u.block!
      end
      @blocked_owner = group.members.find_by(user_id: @blocked_owner_user.id)

      @maintainer_user = create(:user, maintainer_of: project)
      @maintainer = project.members.find_by(user_id: @maintainer_user.id)

      @developer_user = create(:user).tap { |u| group.add_developer(u) }
      @developer = project.members.find_by(user_id: @developer_user.id)

      @blocked_maintainer_user = create(:user).tap do |u|
        project.add_maintainer(u)

        u.block!
      end
      @blocked_developer_user = create(:user).tap do |u|
        project.add_developer(u)

        u.block!
      end
      @blocked_maintainer = project.members.find_by(user_id: @blocked_maintainer_user.id, access_level: Gitlab::Access::MAINTAINER)
      @blocked_developer = project.members.find_by(user_id: @blocked_developer_user.id, access_level: Gitlab::Access::DEVELOPER)

      @invited_member = create(:project_member, :invited, :developer, project: project)

      accepted_invite_user = build(:user, state: :active)
      @accepted_invite_member = create(:project_member, :invited, :developer, project: project)
        .tap { |u| u.accept_invite!(accepted_invite_user) }

      requested_user = create(:user).tap { |u| project.request_access(u) }
      @requested_member = project.requesters.find_by(user_id: requested_user.id)

      accepted_request_user = create(:user).tap { |u| project.request_access(u) }
      @accepted_request_member = project.requesters.find_by(user_id: accepted_request_user.id).tap { |m| m.accept_request(@owner_user) }
      @member_with_minimal_access = create(:group_member, :minimal_access, source: group)
    end

    describe '.access_for_user_ids' do
      it 'returns the right access levels' do
        users = [@owner_user.id, @maintainer_user.id, @blocked_maintainer_user.id]
        expected = {
          @owner_user.id => Gitlab::Access::OWNER,
          @maintainer_user.id => Gitlab::Access::MAINTAINER
        }

        expect(described_class.access_for_user_ids(users)).to eq(expected)
      end
    end

    describe 'hierarchy related scopes' do
      let(:root_ancestor) { create(:group) }
      let(:project) { create(:project, group: root_ancestor) }
      let(:subgroup) { create(:group, parent: root_ancestor) }
      let(:subgroup_project) { create(:project, group: subgroup) }

      let!(:root_ancestor_member) { create(:group_member, group: root_ancestor) }
      let!(:project_member) { create(:project_member, project: project) }
      let!(:subgroup_member) { create(:group_member, group: subgroup) }
      let!(:subgroup_project_member) { create(:project_member, project: subgroup_project) }

      describe '.in_hierarchy' do
        let(:hierarchy_members) do
          [
            root_ancestor_member,
            project_member,
            subgroup_member,
            subgroup_project_member
          ]
        end

        context 'for a project' do
          subject { described_class.in_hierarchy(project) }

          it { is_expected.to contain_exactly(*hierarchy_members) }

          context 'with scope prefix' do
            subject { described_class.where.not(source: project).in_hierarchy(subgroup) }

            it { is_expected.to contain_exactly(root_ancestor_member, subgroup_member, subgroup_project_member) }
          end

          context 'with scope suffix' do
            subject { described_class.in_hierarchy(project).where.not(source: project) }

            it { is_expected.to contain_exactly(root_ancestor_member, subgroup_member, subgroup_project_member) }
          end
        end

        context 'for a group' do
          subject(:group_related_members) { described_class.in_hierarchy(subgroup) }

          it { is_expected.to contain_exactly(*hierarchy_members) }
        end
      end

      describe '.for_self_and_descendants' do
        let(:expected_members) do
          [
            subgroup_member,
            subgroup_project_member
          ]
        end

        subject(:self_and_descendant_members) { described_class.for_self_and_descendants(subgroup) }

        it { is_expected.to contain_exactly(*expected_members) }
      end
    end

    describe '.with_case_insensitive_invite_emails' do
      let_it_be(:email) { 'bob@example.com' }

      context 'when the invite_email is the same case' do
        let_it_be(:invited_member) do
          create(:project_member, :invited, invite_email: email)
        end

        it 'finds the members' do
          expect(described_class.with_case_insensitive_invite_emails([email])).to match_array([invited_member])
        end
      end

      context 'when the invite_email is lowercased and we have an uppercase email for searching' do
        let_it_be(:invited_member) do
          create(:project_member, :invited, invite_email: email)
        end

        it 'finds the members' do
          expect(described_class.with_case_insensitive_invite_emails([email.upcase])).to match_array([invited_member])
        end
      end

      context 'when the invite_email is non lower cased' do
        let_it_be(:invited_member) do
          create(:project_member, :invited, invite_email: email.upcase)
        end

        it 'finds the members' do
          expect(described_class.with_case_insensitive_invite_emails([email])).to match_array([invited_member])
        end
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

    describe '.expiring_and_not_notified' do
      let_it_be(:expiring_in_5_days) { create(:group_member, expires_at: 5.days.from_now) }
      let_it_be(:expiring_in_5_days_with_notified) { create(:group_member, expires_at: 5.days.from_now, expiry_notified_at: Date.today) }
      let_it_be(:expiring_in_7_days) { create(:group_member, expires_at: 7.days.from_now) }
      let_it_be(:expiring_in_10_days) { create(:group_member, expires_at: 10.days.from_now) }
      let_it_be(:not_expiring) { create(:group_member) }

      subject { described_class.expiring_and_not_notified(7.days.from_now.to_date) }

      it { is_expected.not_to include(expiring_in_5_days_with_notified, expiring_in_10_days, not_expiring) }
      it { is_expected.to include(expiring_in_5_days, expiring_in_7_days) }
    end

    describe '.created_today' do
      let_it_be(:now) { Time.current }
      let_it_be(:created_today) { create(:group_member, created_at: now.beginning_of_day) }
      let_it_be(:created_yesterday) { create(:group_member, created_at: now - 1.day) }

      before do
        travel_to now
      end

      subject { described_class.created_today }

      it { is_expected.not_to include(created_yesterday) }
      it { is_expected.to include(created_today) }
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
        invited_member = create(:group_member, :invited, invite_email: 'invited@example.com')

        invited = described_class.search_invite_email(invited_member.invite_email)

        expect(invited.count).to eq(1)
        expect(invited.first).to eq(invited_member)

        expect(described_class.search_invite_email('bad-email@example.com').count).to eq(0)
      end
    end

    describe '.by_access_level' do
      subject { described_class.by_access_level(access_levels) }

      context 'by owner' do
        let(:access_levels) { [Gitlab::Access::OWNER] }

        it { is_expected.to include @owner }
        it { is_expected.not_to include @maintainer }
        it { is_expected.not_to include @invited_member }
        it { is_expected.not_to include @accepted_invite_member }
        it { is_expected.not_to include @requested_member }
        it { is_expected.not_to include @accepted_requested_member }
        it { is_expected.not_to include @blocked_maintainer }
        it { is_expected.not_to include @blocked_developer }
      end

      context 'by maintainer' do
        let(:access_levels) { [Gitlab::Access::MAINTAINER] }

        it { is_expected.not_to include @owner }
        it { is_expected.to include @maintainer }
        it { is_expected.not_to include @invited_member }
        it { is_expected.not_to include @accepted_invite_member }
        it { is_expected.not_to include @requested_member }
        it { is_expected.not_to include @accepted_requested_member }
        it { is_expected.not_to include @blocked_maintainer }
        it { is_expected.not_to include @blocked_developer }
      end

      context 'by developer' do
        let(:access_levels) { [Gitlab::Access::DEVELOPER] }

        it { is_expected.not_to include @owner }
        it { is_expected.not_to include @maintainer }
        it { is_expected.to include @invited_member }
        it { is_expected.to include @accepted_invite_member }
        it { is_expected.not_to include @requested_member }
        it { is_expected.not_to include @accepted_requested_member }
        it { is_expected.not_to include @blocked_maintainer }
        it { is_expected.not_to include @blocked_developer }
      end

      context 'by owner and maintainer' do
        let(:access_levels) { [Gitlab::Access::OWNER, Gitlab::Access::MAINTAINER] }

        it { is_expected.to include @owner }
        it { is_expected.to include @maintainer }
        it { is_expected.not_to include @invited_member }
        it { is_expected.not_to include @accepted_invite_member }
        it { is_expected.not_to include @requested_member }
        it { is_expected.not_to include @accepted_requested_member }
        it { is_expected.not_to include @blocked_maintainer }
        it { is_expected.not_to include @blocked_developer }
      end

      context 'by owner, maintainer and developer' do
        let(:access_levels) { [Gitlab::Access::OWNER, Gitlab::Access::MAINTAINER, Gitlab::Access::DEVELOPER] }

        it { is_expected.to include @owner }
        it { is_expected.to include @maintainer }
        it { is_expected.to include @invited_member }
        it { is_expected.to include @accepted_invite_member }
        it { is_expected.not_to include @requested_member }
        it { is_expected.not_to include @accepted_requested_member }
        it { is_expected.not_to include @blocked_maintainer }
        it { is_expected.not_to include @blocked_developer }
      end
    end

    describe '.with_at_least_access_level' do
      it 'filters members with the at least the specified access level' do
        results = described_class.with_at_least_access_level(::Gitlab::Access::MAINTAINER)

        expect(results).to include(@owner, @maintainer)
        expect(results).not_to include(@developer)
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
      it { expect(described_class.owners_and_maintainers).not_to include @blocked_owner }
      it { expect(described_class.owners_and_maintainers).to include @maintainer }
      it { expect(described_class.owners_and_maintainers).not_to include @invited_member }
      it { expect(described_class.owners_and_maintainers).not_to include @accepted_invite_member }
      it { expect(described_class.owners_and_maintainers).not_to include @requested_member }
      it { expect(described_class.owners_and_maintainers).not_to include @accepted_request_member }
      it { expect(described_class.owners_and_maintainers).not_to include @blocked_maintainer }
    end

    describe '.owners' do
      it { expect(described_class.owners).to include @owner }
      it { expect(described_class.owners).not_to include @blocked_owner }
      it { expect(described_class.owners).not_to include @maintainer }
      it { expect(described_class.owners).not_to include @invited_member }
      it { expect(described_class.owners).not_to include @accepted_invite_member }
      it { expect(described_class.owners).not_to include @requested_member }
      it { expect(described_class.owners).not_to include @accepted_request_member }
      it { expect(described_class.owners).not_to include @blocked_maintainer }
    end

    describe '.all_owners' do
      it { expect(described_class.all_owners).to include @owner }
      it { expect(described_class.all_owners).to include @blocked_owner }
      it { expect(described_class.all_owners).not_to include @maintainer }
      it { expect(described_class.all_owners).not_to include @invited_member }
      it { expect(described_class.all_owners).not_to include @accepted_invite_member }
      it { expect(described_class.all_owners).not_to include @requested_member }
      it { expect(described_class.all_owners).not_to include @accepted_request_member }
      it { expect(described_class.all_owners).not_to include @blocked_maintainer }
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

    describe '.blocked' do
      subject { described_class.blocked.to_a }

      it { is_expected.not_to include @owner }
      it { is_expected.not_to include @maintainer }
      it { is_expected.not_to include @invited_member }
      it { is_expected.not_to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.not_to include @accepted_request_member }
      it { is_expected.to include @blocked_maintainer }
      it { is_expected.to include @blocked_developer }
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

    describe '.without_invites_and_requests' do
      subject { described_class.without_invites_and_requests.to_a }

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.not_to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.to include @blocked_maintainer }
      it { is_expected.to include @blocked_developer }
      it { is_expected.not_to include @member_with_minimal_access }
      it { is_expected.not_to include awaiting_group_member }
      it { is_expected.not_to include awaiting_project_member }

      context 'when minimal_access is true' do
        subject { described_class.without_invites_and_requests(minimal_access: true) }

        it { is_expected.to include @owner }
        it { is_expected.to include @maintainer }
        it { is_expected.not_to include @invited_member }
        it { is_expected.to include @accepted_invite_member }
        it { is_expected.not_to include @requested_member }
        it { is_expected.to include @accepted_request_member }
        it { is_expected.to include @blocked_maintainer }
        it { is_expected.to include @blocked_developer }
        it { is_expected.to include @member_with_minimal_access }
        it { is_expected.not_to include awaiting_group_member }
        it { is_expected.not_to include awaiting_project_member }
      end
    end

    describe '.connected_to_user' do
      subject { described_class.connected_to_user.to_a }

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.to include @blocked_maintainer }
      it { is_expected.to include @blocked_developer }
      it { is_expected.to include @requested_member }
      it { is_expected.to include @member_with_minimal_access }
      it { is_expected.not_to include @invited_member }
    end

    describe '.authorizable' do
      subject { described_class.authorizable.to_a }

      it 'includes the member who has an associated user record, but also having an invite_token' do
        member = create(:project_member, :developer, :invited, user: create(:user))

        expect(subject).to include(member)
      end

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.to include @blocked_maintainer }
      it { is_expected.to include @blocked_developer }
      it { is_expected.not_to include @invited_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.not_to include @member_with_minimal_access }
      it { is_expected.not_to include awaiting_group_member }
      it { is_expected.not_to include awaiting_project_member }
    end

    describe '.distinct_on_user_with_max_access_level' do
      let_it_be(:other_group) { create(:group) }
      let_it_be(:group_project) { create(:project, group: group) }
      let_it_be(:member_with_lower_access_level) { create(:group_member, :developer, group: other_group, user: @owner_user) }
      let_it_be(:member_with_same_access_level) { create(:group_member, :maintainer, group: other_group, user: @maintainer_user) }
      let_it_be(:project_member_with_same_access_level) { create(:project_member, :maintainer, project: group_project, user: @maintainer_user) }
      let_it_be(:member_with_higher_access_level) { create(:group_member, :maintainer, group: other_group, user: @developer_user) }

      let(:for_object) { group }

      subject { described_class.default_scoped.distinct_on_user_with_max_access_level(for_object).to_a }

      context 'for group' do
        it { is_expected.not_to include member_with_lower_access_level }
        it { is_expected.not_to include member_with_same_access_level }
        it { is_expected.not_to include @developer }
        it { is_expected.to include @owner }
        it { is_expected.to include @maintainer }
        it { is_expected.to include @invited_member }
        it { is_expected.to include @accepted_invite_member }
        it { is_expected.to include @requested_member }
        it { is_expected.to include @accepted_request_member }
        it { is_expected.to include @blocked_maintainer }
        it { is_expected.to include @blocked_developer }
        it { is_expected.to include @member_with_minimal_access }
        it { is_expected.to include member_with_higher_access_level }
      end

      context 'for other_group' do
        let(:for_object) { other_group }

        it { is_expected.not_to include member_with_lower_access_level }
        it { is_expected.not_to include @developer }
        it { is_expected.not_to include @maintainer }

        it { is_expected.to include @owner }
        it { is_expected.to include @invited_member }
        it { is_expected.to include @accepted_invite_member }
        it { is_expected.to include @requested_member }
        it { is_expected.to include @accepted_request_member }
        it { is_expected.to include @blocked_maintainer }
        it { is_expected.to include @blocked_developer }
        it { is_expected.to include @member_with_minimal_access }
        it { is_expected.to include member_with_same_access_level }
        it { is_expected.to include member_with_higher_access_level }
      end

      context 'for project' do
        let(:for_object) { group_project }

        it { is_expected.not_to include member_with_lower_access_level }
        it { is_expected.not_to include @developer }
        it { is_expected.not_to include @maintainer }
        it { is_expected.not_to include member_with_same_access_level }

        it { is_expected.to include @owner }
        it { is_expected.to include @invited_member }
        it { is_expected.to include @accepted_invite_member }
        it { is_expected.to include @requested_member }
        it { is_expected.to include @accepted_request_member }
        it { is_expected.to include @blocked_maintainer }
        it { is_expected.to include @blocked_developer }
        it { is_expected.to include @member_with_minimal_access }
        it { is_expected.to include project_member_with_same_access_level }
        it { is_expected.to include member_with_higher_access_level }
      end

      context 'for other object' do
        let(:for_object) { build(:organization) }

        it 'raises an error' do
          expect { subject }.to raise_error ArgumentError, "Invalid object: Organizations::Organization"
        end
      end

      context 'with where conditions' do
        let_it_be(:example_member) { create(:group_member, invite_email: 'user@example.com') }

        subject do
          described_class
            .default_scoped
            .where(invite_email: 'user@example.com')
            .distinct_on_user_with_max_access_level(group)
            .to_a
        end

        it { is_expected.to eq [example_member] }
      end
    end

    describe '.with_invited_user_state' do
      subject(:with_invited_user_state) { described_class.with_invited_user_state }

      it { is_expected.to include @owner }
      it { is_expected.to include @maintainer }
      it { is_expected.to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.to include @requested_member }
      it { is_expected.to include @accepted_request_member }

      context 'with invited pending members' do
        it 'includes invited user state' do
          invited_pending_members = with_invited_user_state.select { |m| m.invited_user_state.present? }
          expect(invited_pending_members.count).to eq 1
          expect(invited_pending_members).to include blocked_pending_approval_project_member
        end
      end
    end

    describe '.with_user' do
      it 'returns the member' do
        not_a_member = create(:user)

        expect(described_class.with_user(@owner_user)).to eq([@owner])
        expect(described_class.with_user(not_a_member)).to be_empty
      end
    end

    describe '.active_state' do
      let_it_be(:active_group_member) { create(:group_member, group: group) }
      let_it_be(:active_project_member) { create(:project_member, project: project) }

      it 'includes members with an active state' do
        expect(group.members.active_state).to include active_group_member
        expect(project.members.active_state).to include active_project_member
      end

      it 'does not include members with an awaiting state' do
        expect(group.members.active_state).not_to include awaiting_group_member
        expect(project.members.active_state).not_to include awaiting_project_member
      end
    end

    describe '.including_user_ids' do
      let_it_be(:active_group_member) { create(:group_member, group: group) }

      it 'includes members with given user ids' do
        expect(group.members.including_user_ids(active_group_member.user_id)).to include active_group_member
        expect(group.members.including_user_ids(non_existing_record_id)).to be_empty
      end
    end

    describe '.excluding_users' do
      let_it_be(:active_group_member) { create(:group_member, group: group) }

      it 'excludes members with given user ids' do
        expect(group.members.excluding_users([])).to include active_group_member
        expect(group.members.excluding_users(active_group_member.user_id)).not_to include active_group_member
      end
    end
  end

  describe 'Delegate methods' do
    it { is_expected.to respond_to(:user_name) }
    it { is_expected.to respond_to(:user_email) }
  end

  describe 'callbacks' do
    describe '#send_invite' do
      context 'with an invited group member' do
        it 'enqueues initial invite email' do
          allow(Members::InviteMailer).to receive(:initial_email).and_call_original

          expect do
            member = create(:group_member, :invited)
            expect(Members::InviteMailer).to have_received(:initial_email).with(member, member.raw_invite_token)
          end.to have_enqueued_mail(Members::InviteMailer, :initial_email)
        end
      end

      context 'with an uninvited member' do
        it 'does not enqueue the initial invite email' do
          expect { create(:group_member) }.not_to have_enqueued_mail(Members::InviteMailer, :initial_email)
        end
      end
    end
  end

  describe '.with_created_by' do
    it 'only returns members that are created_by a user' do
      invited_member_by_user = create(:group_member, :created_by)
      another_member_by_user = create(:group_member, :created_by, source: invited_member_by_user.group)
      create(:group_member)

      expect(described_class.with_created_by).to contain_exactly(invited_member_by_user, another_member_by_user)
    end
  end

  describe '.valid_email?' do
    it 'is a valid email format' do
      expect(described_class.valid_email?('foo')).to eq(false)
    end

    it 'is not a valid email format' do
      expect(described_class.valid_email?('foo@example.com')).to eq(true)
    end
  end

  describe '.filter_by_user_type' do
    let_it_be(:service_account) { create(:user, :service_account) }
    let_it_be(:service_account_member) { create(:group_member, user: service_account) }
    let_it_be(:other_member) { create(:group_member) }

    context 'when the user type is valid' do
      it 'returns service accounts' do
        expect(described_class.filter_by_user_type('service_account')).to match_array([service_account_member])
      end
    end

    context 'when the user type is invalid' do
      it 'returns nil' do
        expect(described_class.filter_by_user_type('invalid_type')).to eq(nil)
      end
    end
  end

  describe '.distinct_on_source_and_case_insensitive_invite_email' do
    it 'finds distinct members on email' do
      email = 'bob@example.com'
      project = create(:project)
      project_owner_member = project.members.first
      member = create(:project_member, :invited, source: project, invite_email: email)
      # The one below is the duplicate and will not be returned.
      create(:project_member, :invited, source: project, invite_email: email.upcase)

      another_project = create(:project)
      another_project_owner_member = another_project.members.first
      another_project_member = create(:project_member, :invited, source: another_project, invite_email: email)
      # The one below is the duplicate and will not be returned.
      create(:project_member, :invited, source: another_project, invite_email: email.upcase)

      expect(described_class.distinct_on_source_and_case_insensitive_invite_email)
        .to match_array([project_owner_member, member, another_project_owner_member, another_project_member])
    end
  end

  describe '.order_updated_desc' do
    it 'contains only the latest updated case insensitive email invite' do
      project = create(:project)
      member = project.members.first
      another_member = create(:project_member, source: member.project)

      travel_to 10.minutes.ago do
        another_member.touch # in past, so shouldn't get accepted over the one created
      end

      member.touch # ensure updated_at is being verified. This one should be first now.

      travel_to 10.minutes.from_now do
        another_member.touch # now we'll make the original first so we are verifying updated_at

        expect(described_class.order_updated_desc).to eq([another_member, member])
      end
    end
  end

  describe '.with_static_role' do
    let_it_be(:membership_without_custom_role) { create(:group_member) }

    subject { described_class.with_static_role }

    it { is_expected.to contain_exactly(membership_without_custom_role) }
  end

  describe '.coerce_to_no_access' do
    let_it_be(:member) { create(:group_member) }

    it 'returns NO_ACCESS for the member' do
      members = described_class.id_in(member.id).coerce_to_no_access.to_a

      expect(members.first.access_level).to eq(Gitlab::Access::NO_ACCESS)
    end
  end

  describe '.with_group_group_sharing_access' do
    let_it_be(:shared_group) { create(:group) }
    let_it_be(:invited_group) { create(:group) }

    where(:member_access_in_invited_group, :group_sharing_access) do
      Gitlab::Access::REPORTER | Gitlab::Access::DEVELOPER
      Gitlab::Access::DEVELOPER | Gitlab::Access::REPORTER
    end

    with_them do
      before do
        create(:group_group_link,
          shared_group: shared_group,
          shared_with_group: invited_group,
          group_access: group_sharing_access)
      end

      let(:member) { create(:group_member, source: invited_group, access_level: member_access_in_invited_group) }

      shared_examples 'returns the minimum of member access level and group sharing access level' do
        specify do
          members = invited_group
                         .members
                         .with_group_group_sharing_access(shared_group, false)
                         .id_in(member.id)
                         .to_a

          expect(members.size).to eq(1)
          expect(members.first.access_level).to eq(Gitlab::Access::REPORTER)
        end
      end

      it_behaves_like 'returns the minimum of member access level and group sharing access level'

      context 'with multiple group group links' do
        before_all do
          create(:group_group_link, :owner, shared_with_group: invited_group)
          create(:group_group_link, :owner, shared_group: shared_group)
        end

        it_behaves_like 'returns the minimum of member access level and group sharing access level'
      end
    end
  end

  describe '#accept_request', :freeze_time do
    let(:member) { create(:project_member, requested_at: Time.current.utc) }
    let(:current_time) { Time.current.utc }

    it { expect(member.accept_request(@owner_user)).to be_truthy }
    it { expect(member.accept_request(nil)).to be_truthy }

    it 'clears requested_at' do
      member.accept_request(@owner_user)

      expect(member.requested_at).to be_nil
    end

    it 'saves the approving user' do
      member.accept_request(@owner_user)

      expect(member.created_by).to eq(@owner_user)
    end

    it 'sets the request accepted timestamp' do
      member.accept_request(@owner_user)

      expect(member.request_accepted_at).to eq(current_time)
    end

    it 'calls #after_accept_request' do
      expect(member).to receive(:after_accept_request)

      member.accept_request(@owner_user)
    end
  end

  describe '#invite?' do
    subject { create(:project_member, invite_email: "user@example.com", user: nil) }

    it { is_expected.to be_invite }
  end

  describe '#request?' do
    shared_examples 'calls notification service and todo service' do
      subject { create(source_type, requested_at: Time.current.utc) }

      specify do
        expect_next_instance_of(NotificationService) do |instance|
          expect(instance).to receive(:new_access_request)
        end

        expect_next_instance_of(TodoService) do |instance|
          expect(instance).to receive(:create_member_access_request_todos)
        end

        is_expected.to be_request
      end
    end

    context 'when requests for project and group are raised' do
      %i[project_member group_member].each do |source_type|
        it_behaves_like 'calls notification service and todo service' do
          let_it_be(:source_type) { source_type }
        end
      end
    end
  end

  describe '#pending?' do
    let(:invited_member) { create(:project_member, invite_email: "user@example.com", user: nil) }
    let(:requester) { create(:project_member, requested_at: Time.current.utc) }

    it { expect(invited_member).to be_pending }
    it { expect(requester).to be_pending }
  end

  describe '#hook_prerequisites_met?' do
    let(:member) { create(:project_member) }

    context 'when the member does not have an associated user' do
      it 'returns false' do
        member.update_column(:user_id, nil)
        expect(member.reload.hook_prerequisites_met?).to eq(false)
      end
    end

    context 'when the member has an associated user' do
      it 'returns true' do
        expect(member.hook_prerequisites_met?).to eq(true)
      end
    end
  end

  describe '#accept_invite!' do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }
    let(:user) { create(:user) }

    it 'resets the invite token' do
      member.accept_invite!(user)

      expect(member.invite_token).to be_nil
    end

    it 'sets the invite accepted timestamp' do
      member.accept_invite!(user)

      expect(member.invite_accepted_at).not_to be_nil
    end

    it 'sets the user' do
      member.accept_invite!(user)

      expect(member.user).to eq(user)
    end

    it 'calls #after_accept_invite' do
      expect(member).to receive(:after_accept_invite)

      member.accept_invite!(user)
    end

    context 'authorized projects' do
      let(:project) { member.source }

      before do
        expect(user.authorized_projects).not_to include(project)
      end

      it 'successfully completes a refresh', :delete, :sidekiq_inline do
        expect(member).to receive(:refresh_member_authorized_projects).and_call_original

        member.accept_invite!(user)

        expect(user.authorized_projects.reload).to include(project)
      end
    end

    it 'does not accept the invite if saving a new user fails' do
      invalid_user = User.new(first_name: '', last_name: '')

      member.accept_invite! invalid_user

      expect(member.invite_accepted_at).to be_nil
      expect(member.invite_token).not_to be_nil
      expect_any_instance_of(described_class).not_to receive(:after_accept_invite)
    end

    context 'when after accepting invite' do
      include NotificationHelpers

      let_it_be(:group) { create(:group, require_two_factor_authentication: true) }
      let_it_be(:member, reload: true) { create(:group_member, :invited, source: group) }
      let_it_be(:email) { member.invite_email }
      let(:user) { build(:user, email: email) }

      it 'enqueues an email to user' do
        member.accept_invite!(user)

        expect_enqueud_email(member.real_source_type, member.id, mail: 'member_invite_accepted_email')
      end

      it 'calls updates the two factor requirement' do
        expect(user).to receive(:require_two_factor_authentication_from_group).and_call_original

        member.accept_invite!(user)

        expect(user.require_two_factor_authentication_from_group).to be_truthy
      end

      context 'when member source is a project' do
        let_it_be(:project) { create(:project, namespace: group) }
        let_it_be(:member) { create(:project_member, :invited, source: project, invite_email: email) }

        it 'calls updates the two factor requirement' do
          expect(user).not_to receive(:require_two_factor_authentication_from_group)

          member.accept_invite!(user)
        end
      end
    end
  end

  describe '#decline_invite!' do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it 'destroys the member' do
      member.decline_invite!

      expect(member).to be_destroyed
    end

    it 'enqueues an invite declined email' do
      allow(Members::InviteDeclinedMailer).to receive(:email).with(member: member).and_call_original

      expect do
        member.decline_invite!
      end.to have_enqueued_mail(Members::InviteDeclinedMailer, :email)
    end
  end

  describe '#generate_invite_token' do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it 'sets the invite token' do
      expect { member.generate_invite_token }.to change { member.invite_token }
    end
  end

  describe 'generate invite token on create' do
    let(:project) { create(:project) }
    let!(:member) { build(:project_member, invite_email: "user@example.com", project: project) }

    it 'sets the invite token' do
      expect { member.save! }.to change { member.invite_token }.to(kind_of(String))
    end

    context 'when invite was already accepted' do
      it 'does not set invite token' do
        member.invite_accepted_at = 1.day.ago

        expect { member.save! }.not_to change { member.invite_token }.from(nil)
      end
    end
  end

  describe '.find_by_invite_token' do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it 'finds the member' do
      expect(described_class.find_by_invite_token(member.raw_invite_token)).to eq member
    end
  end

  describe '.pluck_user_ids' do
    let(:member) { create(:group_member) }

    it 'plucks the user ids' do
      expect(described_class.where(id: member).pluck_user_ids).to match([member.user_id])
    end
  end

  describe '#send_invitation_reminder' do
    subject(:send_invitation_reminder) { member.send_invitation_reminder(0) }

    context 'an invited group member' do
      let!(:member) { create(:group_member, :invited) }

      it 'enqueues a reminder email' do
        expect(Members::InviteReminderMailer)
          .to receive(:email).with(member, member.raw_invite_token, 0).and_call_original

        expect { send_invitation_reminder }.to have_enqueued_mail(Members::InviteReminderMailer, :email)
      end
    end

    context 'an invited member without a raw invite token set' do
      let!(:member) { create(:group_member, :invited) }

      before do
        member.instance_variable_set(:@raw_invite_token, nil)
        allow(Members::InviteReminderMailer).to receive(:email).and_call_original
      end

      it 'generates a new token' do
        expect(member).to receive(:generate_invite_token!)

        send_invitation_reminder
      end
    end

    context 'an uninvited member' do
      let!(:member) { create(:group_member) }

      it 'does not send a reminder' do
        expect(Members::InviteReminderMailer).not_to receive(:email)

        send_invitation_reminder
      end
    end
  end

  describe '#invite_to_unknown_user?' do
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

  describe 'destroying a record', :delete, :sidekiq_inline do
    it "refreshes user's authorized projects" do
      project = create(:project, :private)
      user    = create(:user)
      member  = project.add_reporter(user)

      member.destroy!

      expect(user.authorized_projects).not_to include(project)
    end
  end

  context 'for updating organization_users' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:group) { create(:group, organization: organization) }
    let_it_be(:user) { create(:user) }
    let(:member) { create(:group_member, source: group, user: user) }

    subject(:commit_member) { member }

    before do
      allow(Organizations::OrganizationUser).to receive(:create_organization_record_for).once.and_call_original
    end

    shared_examples_for 'does not create an organization_user entry' do
      specify do
        expect { commit_member }.not_to change { Organizations::OrganizationUser.count }
      end
    end

    context 'when creating' do
      it 'inserts new record on member creation' do
        expect { member }.to change { Organizations::OrganizationUser.count }.by(1)
        record_attrs = { organization: group.organization, user: member.user, access_level: :default }
        expect(Organizations::OrganizationUser.exists?(record_attrs)).to be(true)
      end

      context 'when user already exists in the organization_users' do
        let_it_be(:user) { create(:user) }
        let_it_be(:common_attrs) { { organization: group.organization, user: user } }
        let(:new_member) { create(:group_member, :owner, source: group, user: user) }

        context 'for an already existing default organization_user' do
          before_all do
            create(:organization_user, common_attrs)
          end

          it 'does not insert a new record in organization_users' do
            expect { new_member }.not_to change { Organizations::OrganizationUser.count }
            expect(
              Organizations::OrganizationUser.exists?(
                organization: group.organization, user: user, access_level: :default
              )
            ).to be(true)
          end

          it 'does not update timestamps' do
            travel_to(1.day.from_now) do
              expect { new_member }.not_to change { Organizations::OrganizationUser.last.updated_at }
            end
          end
        end

        context 'for an already existing owner organization_user' do
          before_all do
            create(:organization_user, :owner, common_attrs)
          end

          it 'does not insert a new record in organization_users nor update the access_level' do
            expect do
              create(:group_member, :owner, source: group, user: user)
            end.not_to change { Organizations::OrganizationUser.count }

            expect(
              Organizations::OrganizationUser.exists?(common_attrs.merge(access_level: :default))
            ).to be(false)
            expect(
              Organizations::OrganizationUser.exists?(common_attrs.merge(access_level: :owner))
            ).to be(true)
          end
        end
      end

      context 'when updating the organization_users is not successful' do
        it 'rolls back the member creation' do
          allow(Organizations::OrganizationUser)
            .to receive(:create_organization_record_for).once.and_raise(ActiveRecord::StatementTimeout)

          expect { commit_member }.to raise_error(ActiveRecord::StatementTimeout)
          expect(Organizations::OrganizationUser.exists?(organization: group.organization)).to be(false)
          expect(group.group_members).to be_empty
        end
      end

      context 'when member is an invite' do
        let(:member) { create(:group_member, :invited, source: group, user: nil) }

        it_behaves_like 'does not create an organization_user entry'
      end

      context 'when member is an access request' do
        let(:member) { create(:group_member, :access_request, source: group, user: user) }

        it_behaves_like 'does not create an organization_user entry'
      end
    end

    context 'when updating' do
      shared_examples 'an action that creates an organization record after commit' do
        it 'inserts new record on member creation' do
          expect { commit_member }.to change { Organizations::OrganizationUser.count }.by(1)
          expect(group.organization.user?(user)).to be(true)
        end

        context 'when organization does not exist' do
          let_it_be(:member) { create(:group_member) }

          it_behaves_like 'does not create an organization_user entry'
        end
      end

      context 'when member accept invite' do
        let_it_be_with_reload(:member, reload: true) { create(:group_member, :invited, source: group) }

        subject(:commit_member) { member.accept_invite!(user) }

        it_behaves_like 'an action that creates an organization record after commit'

        context 'when updating the organization_users is not successful' do
          before do
            allow(Organizations::OrganizationUser)
              .to receive(:create_organization_record_for).once.and_raise(ActiveRecord::StatementTimeout)
          end

          it 'rolls back the member creation', :aggregate_failures do
            expect { commit_member }.to raise_error(ActiveRecord::StatementTimeout)
            expect(group.organization.user?(user)).to be(false)
            expect(member.reset.user).to be_nil
          end
        end
      end

      context "when member's access request is approved" do
        let_it_be_with_reload(:member) { create(:group_member, :access_request, source: group, user: user) }

        subject(:commit_member) { member.accept_request(@owner_user) }

        it_behaves_like 'an action that creates an organization record after commit'

        context 'when updating the organization_users is not successful' do
          before do
            allow(Organizations::OrganizationUser)
              .to receive(:create_organization_record_for).once.and_raise(ActiveRecord::StatementTimeout)
          end

          it 'rolls back the member creation', :aggregate_failures do
            expect { commit_member }.to raise_error(ActiveRecord::StatementTimeout)
            expect(group.organization.user?(user)).to be(false)
            expect(member.reset.requested_at).not_to be_nil
          end
        end
      end

      context 'when updating a non user_id/requested_at attribute' do
        let_it_be(:member) { create(:group_member, :reporter, source: group) }

        subject(:commit_member) { member.update!(access_level: GroupMember::DEVELOPER) }

        it_behaves_like 'does not create an organization_user entry'
      end
    end
  end

  context 'when after_commit :update_highest_role' do
    let_it_be(:user) { create(:user) }

    let(:user_id) { user.id }

    where(:member_type, :source_type) do
      :project_member | :project
      :group_member   | :group
    end

    with_them do
      describe 'create member' do
        let!(:source) { create(source_type) } # rubocop:disable Rails/SaveBang

        subject { create(member_type, :guest, user: user, source: source) }

        include_examples 'update highest role with exclusive lease'
      end

      context 'when member exists' do
        let!(:member) { create(member_type, user: user) }

        describe 'update member' do
          context 'when access level was changed' do
            subject { member.update!(access_level: Gitlab::Access::GUEST) }

            include_examples 'update highest role with exclusive lease'
          end

          context 'when access level was not changed' do
            subject { member.update!(notification_level: NotificationSetting.levels[:disabled]) }

            include_examples 'does not update the highest role'
          end
        end

        describe 'destroy member' do
          subject { member.reload.destroy! }

          include_examples 'update highest role with exclusive lease'
        end
      end
    end
  end

  context 'when after_update :post_update_hook' do
    let_it_be(:member) { create(:group_member, :developer) }

    context 'when access_level is changed' do
      it 'calls NotificationService.update_member' do
        expect(NotificationService).to receive_message_chain(:new, :updated_member_access_level).with(member)

        member.update_attribute(:access_level, Member::MAINTAINER)
      end

      it 'does not send an email when the access level has not changed' do
        expect(NotificationService).not_to receive(:new)

        member.touch
      end
    end

    context 'when expiration is changed' do
      it 'calls the notification service when membership expiry has changed' do
        expect(NotificationService).to receive_message_chain(:new, :updated_member_expiration).with(member)

        member.update!(expires_at: 5.days.from_now)
      end
    end
  end

  context 'when after_create :post_create_hook' do
    include NotificationHelpers

    let_it_be(:source) { create(:group) }
    let(:member) { create(:group_member, source: source) }

    subject(:create_member) { member }

    shared_examples_for 'invokes a notification' do
      it 'enqueues an email to user' do
        create_member

        expect_delivery_jobs_count(1)
        expect_enqueud_email(member.real_source_type, member.id, mail: 'member_access_granted_email')
      end
    end

    shared_examples_for 'performs all the common hooks' do
      it_behaves_like 'invokes a notification'

      it 'creates an event' do
        expect { create_member }.to change { Event.count }.by(1)
      end
    end

    it 'calls the system hook service' do
      expect_next_instance_of(SystemHooksService) do |instance|
        expect(instance).to receive(:execute_hooks_for).with(an_instance_of(GroupMember), :create)
      end

      create_member
    end

    context 'when member is a requested member' do
      let(:member) { create(:group_member, source: source, requested_at: Time.current.utc) }

      it 'calls the system hook service' do
        expect_next_instance_of(SystemHooksService) do |instance|
          expect(instance).to receive(:execute_hooks_for).with(an_instance_of(GroupMember), :request)
        end

        create_member
      end
    end

    context 'when source is a group' do
      it_behaves_like 'invokes a notification'

      it 'does not create an event' do
        expect { create_member }.not_to change { Event.count }
      end
    end

    context 'when source is a project' do
      context 'when source is a personal project' do
        let_it_be(:namespace) { create(:namespace) }

        context 'when member is the owner of the namespace' do
          subject(:create_member) { create(:project, namespace: namespace) }

          it 'does not enqueue an email' do
            create_member

            expect_delivery_jobs_count(0)
          end

          it 'does not create an event' do
            expect { create_member }.not_to change { Event.count }
          end
        end

        context 'when member is not the namespace owner' do
          let_it_be(:project) { create(:project, namespace: namespace) }
          let(:member) { create(:project_member, source: project) }

          subject(:create_member) { member }

          it_behaves_like 'performs all the common hooks'
        end
      end

      context 'when source is not a personal project' do
        let_it_be(:project) { create(:project, namespace: create(:group)) }
        let(:member) { create(:project_member, source: project) }

        subject(:create_member) { member }

        it_behaves_like 'performs all the common hooks'
      end
    end
  end

  context 'when after_create :update_two_factor_requirement' do
    it 'calls update_two_factor_requirement after creation' do
      user = create(:user)

      expect(user).to receive(:update_two_factor_requirement)

      create(:group_member, user: user)
    end
  end

  context 'when after_destroy :update_two_factor_requirement' do
    it 'calls update_two_factor_requirement after deletion' do
      group_member = create(:group_member)

      expect(group_member.user).to receive(:update_two_factor_requirement)

      group_member.destroy!
    end
  end

  describe 'log_invitation_token_cleanup' do
    let_it_be(:project) { create :project }

    context 'when on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return true
      end

      it "doesn't log info for members without invitation or accepted invitation" do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        create :project_member
        create :project_member, :invited, invite_accepted_at: nil
        create :project_member, invite_token: nil, invite_accepted_at: Time.zone.now
      end

      it 'logs error for accepted members with token and creates membership' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(kind_of(StandardError), kind_of(Hash))

        expect do
          create :project_member, :invited, source: project, invite_accepted_at: Time.zone.now
        end.to change { Member.count }.by(1)
      end
    end

    context 'when not on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
      end

      it 'does not log error for accepted members with token and creates membership' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        expect do
          create :project_member, :invited, source: project, invite_accepted_at: Time.zone.now
        end.to change { Member.count }.by(1)
      end
    end
  end

  describe '#set_member_namespace_id' do
    let(:group) { create(:group) }
    let(:member) { create(:group_member, group: group) }

    describe 'on create' do
      it 'sets the member_namespace_id' do
        expect(member.member_namespace_id).to eq group.id
      end
    end
  end

  describe '.sort_by_attribute' do
    let_it_be(:user1) { create(:user, created_at: Date.today, last_sign_in_at: Date.today, last_activity_on: Date.today, name: 'Alpha') }
    let_it_be(:user2) { create(:user, created_at: Date.today - 1, last_sign_in_at: Date.today - 1, last_activity_on: Date.today - 1, name: 'Omega') }
    let_it_be(:user3) { create(:user, created_at: Date.today - 2, name: 'Beta') }
    let_it_be(:group) { create(:group) }
    let_it_be(:member1) { create(:group_member, :reporter, group: group, user: user1) }
    let_it_be(:member2) { create(:group_member, :developer, group: group, user: user2) }
    let_it_be(:member3) { create(:group_member, :maintainer, group: group, user: user3) }

    it 'sort users in ascending order by access-level' do
      expect(described_class.sort_by_attribute('access_level_asc')).to eq([member1, member2, member3])
    end

    it 'sort users in descending order by access-level' do
      expect(described_class.sort_by_attribute('access_level_desc')).to eq([member3, member2, member1])
    end

    context 'when sort by recent_sign_in' do
      subject { described_class.sort_by_attribute('recent_sign_in') }

      it 'sorts users by recent sign-in time' do
        expect(subject.first).to eq(member1)
        expect(subject.second).to eq(member2)
      end

      it 'pushes users who never signed in to the end' do
        expect(subject.third).to eq(member3)
      end
    end

    context 'when sort by oldest_sign_in' do
      subject { described_class.sort_by_attribute('oldest_sign_in') }

      it 'sorts users by the oldest sign-in time' do
        expect(subject.first).to eq(member2)
        expect(subject.second).to eq(member1)
      end

      it 'pushes users who never signed in to the end' do
        expect(subject.third).to eq(member3)
      end
    end

    it 'sorts users in descending order by their creation time' do
      expect(described_class.sort_by_attribute('recent_created_user')).to eq([member1, member2, member3])
    end

    it 'sorts users in ascending order by their creation time' do
      expect(described_class.sort_by_attribute('oldest_created_user')).to eq([member3, member2, member1])
    end

    it 'sort users by recent last activity' do
      expect(described_class.sort_by_attribute('recent_last_activity')).to eq([member1, member2, member3])
    end

    it 'sort users by oldest last activity' do
      expect(described_class.sort_by_attribute('oldest_last_activity')).to eq([member3, member2, member1])
    end
  end

  context 'with loose foreign key on members.user_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) { create(:group_member, user: parent) }
    end
  end
end
