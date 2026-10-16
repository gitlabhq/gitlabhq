# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePolicy, feature_category: :team_planning do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:planner) { create(:user) }
  let_it_be_with_reload(:author) { create(:user) }
  let_it_be_with_reload(:assignee) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:reporter_from_group_link) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let(:alert_bot) { Users::Internal.in_organization(issue.project.organization).alert_bot }
  let(:support_bot) { Users::Internal.in_organization(project.organization_id).support_bot }

  subject(:policy) { described_class.new(user, issue) }

  describe 'delegation' do
    let(:user) { guest }
    let(:issue) { build(:issue) }

    it { is_expected.to delegate_to(ProjectPolicy) }
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end

  shared_examples 'support bot' do
    let(:user) { support_bot }

    context 'with service desk enabled' do
      let(:support_bot_permissions) do
        [
          :read_issue, :read_note, :read_issue_iid, :create_issue, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
        ]
      end

      before do
        allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?) { true }
        allow(::Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?) { true }

        project.update!(service_desk_enabled: true)
      end

      context 'on an issue' do
        it { expect_allowed(*support_bot_permissions) }
      end

      context 'on an issue without assignee' do
        let(:issue) { issue_no_assignee }

        it { expect_allowed(*support_bot_permissions) }
      end

      context 'on a new issue' do
        let(:issue) { new_issue }

        it { expect_allowed(*support_bot_permissions) }
      end
    end

    context 'with service desk disabled' do
      let(:all_permissions) { described_class.ability_map.map.keys }

      context 'on an issue' do
        it { expect_disallowed(*all_permissions) }
      end

      context 'on an issue without assignee' do
        let(:issue) { issue_no_assignee }

        it { expect_disallowed(*all_permissions) }
      end

      context 'on a new issue' do
        let(:issue) { new_issue }

        it { expect_disallowed(*all_permissions) }
      end
    end
  end

  shared_examples 'alert bot' do
    let(:user) { alert_bot }
    let(:alert_bot_permissions) do
      [
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :move_issue, :clone_issue
      ]
    end

    context 'on an issue' do
      it { expect_allowed(*alert_bot_permissions) }
    end

    context 'on an issue without assignee' do
      let(:issue) { issue_no_assignee }

      it { expect_allowed(*alert_bot_permissions) }
    end

    context 'on a new issue' do
      let(:issue) { new_issue }

      it { expect_allowed(*alert_bot_permissions) }
    end
  end

  # Role permissions on a plain issue come from the role YAML and are checked by
  # ee/spec/lib/authz/role_definitions_spec.rb. These contexts cover IssuePolicy's own rules.
  context 'a private project' do
    let_it_be_with_reload(:project) { create(:project, :private) }
    let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let_it_be_with_reload(:issue_no_assignee) { create(:issue, project: project) }
    let_it_be_with_reload(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }

    let(:new_issue) { build(:issue, project: project) }

    before_all do
      project.add_guest(guest)
      project.add_guest(author)
      project.add_guest(assignee)
      project.add_reporter(reporter)
    end

    context 'for a guest' do
      let(:user) { guest }

      context 'on an issue' do
        it { expect_allowed(:create_todo, :update_subscription, :admin_issue_link) }
        it { expect_disallowed(:set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue) }
      end

      context 'on a new issue' do
        let(:issue) { new_issue }

        it { expect_allowed(:set_issue_metadata, :set_confidentiality) }
      end

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it 'disallows the permissions' do
          expect_disallowed(
            :read_issue, :read_issue_iid, :read_note, :create_note, :award_emoji, :admin_issue_relation,
            :admin_issue_link, :create_todo, :update_subscription
          )
        end
      end
    end

    context 'for a reporter' do
      let(:user) { reporter }

      context 'on an issue' do
        it { expect_allowed(:set_issue_metadata, :set_confidentiality, :admin_issue_link, :move_issue, :clone_issue) }
      end

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it { expect_allowed(:read_issue, :update_issue, :admin_issue) }
      end
    end

    context 'for the issue author' do
      let(:user) { author }

      context 'on an issue' do
        it { expect_allowed(:update_issue, :reopen_issue, :destroy_issue) }
      end

      context 'on an issue they did not create' do
        let(:issue) { issue_no_assignee }

        it { expect_disallowed(:update_issue, :reopen_issue, :destroy_issue) }
      end

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it { expect_allowed(:read_issue, :read_note, :update_issue) }
      end

      context 'on a confidential issue moved to a private project' do
        let(:issue) { confidential_issue }

        before do
          confidential_issue.project = create(:project, :private)
        end

        it { expect_disallowed(:read_issue, :read_note, :update_issue) }
      end
    end

    context 'for the issue assignee' do
      let(:user) { assignee }

      context 'on an issue' do
        it { expect_allowed(:update_issue, :reopen_issue) }
        it { expect_disallowed(:destroy_issue) }
      end

      context 'on an issue they are not assigned to' do
        let(:issue) { issue_no_assignee }

        it { expect_disallowed(:update_issue, :reopen_issue) }
      end

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it { expect_allowed(:read_issue, :read_note, :update_issue) }
      end

      context 'on a confidential issue moved to a private project' do
        let(:issue) { confidential_issue }

        before do
          confidential_issue.project = create(:project, :private)
        end

        it { expect_disallowed(:read_issue, :read_note, :update_issue) }
      end
    end

    context 'for a non-member' do
      let(:user) { non_member }

      context 'on an issue' do
        it { expect_disallowed(:read_issue, :read_issue_iid, :read_note, :create_note, :update_issue, :create_todo) }
      end
    end

    it_behaves_like 'alert bot'
    it_behaves_like 'support bot'
  end

  context 'a public project' do
    let_it_be_with_reload(:project) { create(:project, :public) }
    let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let_it_be_with_reload(:issue_no_assignee) { create(:issue, project: project) }
    let_it_be_with_reload(:issue_locked) { create(:issue, :locked, project: project, author: author, assignees: [assignee]) }

    let(:new_issue) { build(:issue, project: project) }

    before_all do
      project.add_guest(guest)
      project.add_planner(planner)
      project.add_reporter(reporter)
      project.add_maintainer(maintainer)
      project.add_owner(owner)

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    context 'for an anonymous user' do
      let(:user) { nil }

      context 'on an issue' do
        it { expect_allowed(:read_issue, :read_note) }
        it { expect_disallowed(:create_todo, :update_subscription, :admin_issue_link) }
      end
    end

    context 'for a non-member' do
      let(:user) { non_member }

      context 'on an issue' do
        it { expect_allowed(:read_issue, :read_note, :create_note, :award_emoji, :create_todo, :update_subscription) }
        it { expect_disallowed(:admin_issue_link) }
      end

      context 'on a locked issue' do
        let(:issue) { issue_locked }

        it { expect_disallowed(:create_note, :award_emoji) }
      end

      context 'on a new issue' do
        let(:issue) { new_issue }

        # Non-members can mark new issues confidential so they can report security issues.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/337665
        it { expect_allowed(:create_issue, :set_confidentiality) }
        it { expect_disallowed(:set_issue_metadata) }
      end
    end

    context 'for a guest' do
      let(:user) { guest }

      context 'on an issue' do
        it { expect_allowed(:admin_issue_link) }
      end

      context 'on a locked issue' do
        let(:issue) { issue_locked }

        it { expect_allowed(:create_note, :award_emoji) }
      end
    end

    context 'for a reporter' do
      let(:user) { reporter }

      context 'on an issue' do
        it { expect_allowed(:reopen_issue) }
      end

      context 'on a locked issue' do
        let(:issue) { issue_locked }

        it { expect_disallowed(:reopen_issue) }
      end
    end

    context 'for the issue author who is not a member' do
      let(:user) { author }

      context 'on an issue' do
        it { expect_allowed(:update_issue, :reopen_issue) }
        it { expect_disallowed(:destroy_issue) }
      end

      context 'on a locked issue' do
        let(:issue) { issue_locked }

        it { expect_allowed(:update_issue) }
        it { expect_disallowed(:reopen_issue) }
      end
    end

    it_behaves_like 'support bot'
    it_behaves_like 'alert bot'

    context 'when issues are private' do
      before_all do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
      end

      let_it_be_with_reload(:issue) { create(:issue, project: project, author: author) }

      context 'for a non-member' do
        let(:user) { non_member }

        context 'on an issue' do
          it { expect_disallowed(:read_issue, :read_note, :create_note, :create_todo, :update_subscription) }
        end
      end

      context 'for a guest' do
        let(:user) { guest }

        context 'on an issue' do
          it { expect_allowed(:read_issue, :read_note, :create_note, :create_todo, :update_subscription) }
        end
      end

      context 'for an admin' do
        let(:user) { admin }

        context 'when admin mode is enabled', :enable_admin_mode do
          it { expect_allowed(:read_issue, :create_note, :admin_issue_link) }
        end

        context 'when admin mode is disabled' do
          it { expect_disallowed(:read_issue, :create_note, :admin_issue_link) }
        end
      end

      it_behaves_like 'alert bot'
      it_behaves_like 'support bot'
    end

    context 'with confidential issues' do
      let_it_be(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }
      let_it_be(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(guest, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows planners to read, update, and admin confidential issues' do
        expect(permissions(planner, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(planner, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue)
        expect(permissions(reporter, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows reporter from group links to read, update, and admin confidential issues' do
        expect(permissions(reporter_from_group_link, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(reporter_from_group_link, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue
        )
        expect(permissions(author, confidential_issue)).to be_disallowed(
          :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
        )

        expect(permissions(author, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue
        )
        expect(permissions(assignee, confidential_issue)).to be_disallowed(
          :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
        )

        expect(permissions(assignee, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows admins to read confidential issues' do
        expect(permissions(admin, confidential_issue)).to be_allowed(:read_issue)
      end
    end

    context 'with a hidden issue' do
      let_it_be(:user) { create(:user) }
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be(:hidden_issue) { create(:issue, project: project, author: banned_user) }

      it 'does not allow non-admin user to access or modify the issue' do
        expect(permissions(user, hidden_issue)).not_to be_allowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows admin to access and modify the issue', :enable_admin_mode do
        expect(permissions(admin, hidden_issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      end
    end

    context 'when accounting for notes widget' do
      context 'and notes widget is disabled for issue' do
        before do
          stub_work_item_widget(issue, notes: false)
        end

        it 'does not allow accessing notes' do
          # if notes widget is disabled not even maintainer can access notes
          expect(permissions(maintainer, issue)).to be_disallowed(
            :create_note, :read_note, :mark_note_as_internal, :read_internal_note, :admin_note
          )
          expect(permissions(admin, issue)).to be_disallowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
        end
      end

      context 'and notes widget is enabled for issue' do
        it 'allows accessing notes' do
          # with notes widget enabled, even guests can access notes
          expect(permissions(guest, issue)).to be_allowed(:create_note, :read_note)
          expect(permissions(guest, issue)).to be_disallowed(
            :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
          expect(permissions(planner, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal
          )
          expect(permissions(reporter, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal
          )
          expect(permissions(reporter, issue)).to be_disallowed(:admin_note)
          expect(permissions(maintainer, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :admin_note
          )
          expect(permissions(owner, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
        end
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers -- Need helpers for testing multiple scenarios
  context 'with group level issues' do
    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:private_project) { create(:project, :private, group: private_group) }
    let_it_be(:public_project) { create(:project, :public, group: public_group) }

    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:non_member_user) { create(:user) }

    let_it_be(:guest) { create(:user, guest_of: [private_project, public_project]) }
    let_it_be(:planner) { create(:user, planner_of: [private_project, public_project]) }
    let_it_be(:guest_author) { create(:user, guest_of: [private_project, public_project]) }
    let_it_be(:reporter) { create(:user, reporter_of: [private_project, public_project]) }

    let_it_be(:group_guest) { create(:user, guest_of: [private_group, public_group]) }
    let_it_be(:group_planner) { create(:user, planner_of: [private_group, public_group]) }
    let_it_be(:group_guest_author) { create(:user, guest_of: [private_group, public_group]) }
    let_it_be(:group_reporter) { create(:user, reporter_of: [private_group, public_group]) }

    context 'with public group' do
      let_it_be(:work_item) { create(:issue, :group_level, namespace: public_group) }
      let_it_be(:confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: public_group) }
      let_it_be(:authored_work_item) { create(:issue, :group_level, namespace: public_group, author: group_guest_author) }
      let_it_be(:authored_confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: public_group, author: group_guest_author) }
      let(:not_persisted_work_item) { build(:issue, :group_level, namespace: public_group) }

      # only checking abilities without group level work items license, because in FOSS there is no license available
      it_behaves_like 'abilities without group level work items license'
    end

    context 'with private group' do
      let_it_be(:work_item) { create(:issue, :group_level, namespace: private_group) }
      let_it_be(:confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: private_group) }
      let_it_be(:authored_work_item) { create(:issue, :group_level, namespace: private_group, author: group_guest_author) }
      let_it_be(:authored_confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: private_group, author: group_guest_author) }
      let(:not_persisted_work_item) { build(:issue, :group_level, namespace: private_group) }

      # only checking abilities without group level work items license, because in FOSS there is no license available
      it_behaves_like 'abilities without group level work items license'
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'with external authorization enabled' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project, :public) }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }
    let(:policies) { described_class.new(user, issue) }

    before do
      enable_external_authorization_service_check
    end

    it 'can read the issue iid without accessing the external service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(policies).to be_allowed(:read_issue_iid)
    end
  end

  describe 'crm permissions' do
    let(:user) { create(:user) }
    let(:subgroup) { create(:group, parent: create(:group)) }
    let(:project) { create(:project, group: subgroup) }
    let(:issue) { create(:issue, project: project) }
    let(:policies) { described_class.new(user, issue) }

    %i[planner reporter].each do |role|
      context "when project #{role}" do
        it 'is disallowed' do
          project.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context "when subgroup #{role}" do
        it 'is allowed' do
          subgroup.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context "when root group #{role}" do
        it 'is allowed' do
          subgroup.parent.try(:"add_#{role}", user)

          expect(policies).to be_allowed(:read_crm_contacts)
          expect(policies).to be_allowed(:set_issue_crm_contacts)
        end
      end

      context 'when crm disabled on subgroup' do
        let(:subgroup) { create(:group, :crm_disabled, parent: create(:group)) }

        it 'is disallowed' do
          subgroup.parent.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context 'when personal namespace' do
        let(:project) { create(:project) }

        it 'is disallowed' do
          project.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context 'when custom crm_group configured' do
        let_it_be_with_reload(:crm_settings) { create(:crm_settings, source_group: create(:group)) }
        let_it_be_with_reload(:subgroup) { create(:group, parent: create(:group), crm_settings: crm_settings) }
        let_it_be_with_reload(:project) { create(:project, group: subgroup) }

        subject { policies }

        context 'for support bot' do
          let(:user) { support_bot }

          context 'with service desk enabled' do
            before do
              allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?) { true }
              allow(::Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?) { true }

              project.update!(service_desk_enabled: true)
            end

            it { expect_allowed(:read_crm_contacts, :set_issue_crm_contacts) }
          end

          context 'with service desk disabled' do
            let(:all_permissions) { described_class.ability_map.map.keys }

            it { expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts) }
          end
        end

        context 'when custom crm_group guest' do
          it 'is disallowed' do
            subgroup.parent.try(:"add_#{role}", user)
            crm_settings.source_group.add_guest(user)

            expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts)
          end
        end

        context "when custom crm_group #{role}" do
          it 'is allowed' do
            subgroup.parent.try(:"add_#{role}", user)
            crm_settings.source_group.try(:"add_#{role}", user)

            expect_allowed(:read_crm_contacts, :set_issue_crm_contacts)
          end
        end
      end
    end
  end

  describe 'set_issue_metadata rule for new issues' do
    context 'when user has set_new_issue_metadata permission' do
      let_it_be_with_reload(:project) { create(:project, :private) }
      let_it_be(:persisted_issue) { create(:issue, project: project) }
      let(:new_issue) { build(:issue, project: project) }

      before_all do
        project.add_guest(guest)
      end

      it 'allows guest to set metadata on new issues when they have set_new_issue_metadata permission' do
        # The rule: ~persisted & can?(:set_new_issue_metadata) should enable :set_issue_metadata
        expect(permissions(guest, new_issue)).to be_allowed(:set_issue_metadata)
      end

      it 'does not allow guest to set metadata on persisted issues without higher permissions' do
        expect(permissions(guest, persisted_issue)).to be_disallowed(:set_issue_metadata)
      end
    end

    context 'when user does not have set_new_issue_metadata permission' do
      let_it_be_with_reload(:project) { create(:project, :private) }
      let(:new_issue) { build(:issue, project: project) }
      let_it_be(:non_member) { create(:user) }

      it 'does not allow non-member to set metadata on new issues' do
        expect(permissions(non_member, new_issue)).to be_disallowed(:set_issue_metadata)
      end
    end
  end

  context 'with incident issue type' do
    let_it_be_with_reload(:project) { create(:project, group: group, guests: guest, planners: planner, reporters: reporter, owners: owner) }
    let_it_be(:incident) { create(:issue, :incident, project: project) }

    it 'allows accessing an incident' do
      expect(permissions(guest, incident)).to be_disallowed(:update_issue, :admin_issue)
      expect(permissions(planner, incident)).to be_disallowed(:update_issue, :admin_issue, :destroy_issue)
      expect(permissions(reporter, incident)).to be_allowed(:update_issue, :admin_issue)
      expect(permissions(reporter, incident)).to be_disallowed(:destroy_issue)
      expect(permissions(owner, incident)).to be_allowed(:update_issue, :admin_issue, :destroy_issue)
    end
  end
end
