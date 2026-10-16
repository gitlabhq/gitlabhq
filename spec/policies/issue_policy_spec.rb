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

    context 'for the support bot' do
      let(:user) { support_bot }

      context 'with service desk enabled' do
        before do
          allow(::Gitlab::Email::IncomingEmail).to receive_messages(enabled?: true, supports_wildcard?: true)

          project.update!(service_desk_enabled: true)
        end

        context 'on an issue' do
          it { expect_allowed(:read_issue, :update_issue, :admin_issue_relation) }
          it { expect_disallowed(:admin_issue_link) }
        end
      end

      context 'with service desk disabled' do
        context 'on an issue' do
          it { expect_disallowed(*described_class.ability_map.map.keys) }
        end
      end
    end

    context 'for the alert bot' do
      let(:user) { alert_bot }

      context 'on an issue' do
        it { expect_allowed(:read_issue, :update_issue, :admin_issue_relation) }
        it { expect_disallowed(:admin_issue_link) }
      end
    end
  end

  context 'a public project' do
    let_it_be_with_reload(:project) { create(:project, :public) }
    let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let_it_be_with_reload(:issue_locked) { create(:issue, :locked, project: project, author: author, assignees: [assignee]) }
    let_it_be(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }
    let_it_be(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }
    let_it_be(:hidden_issue) { create(:issue, project: project, author: create(:user, :banned)) }

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

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it { expect_disallowed(:read_issue, :read_issue_iid, :read_note, :create_note, :update_issue) }
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
        it { expect_allowed(:read_issue, :update_issue, :admin_issue, :reopen_issue) }
      end

      context 'on a locked issue' do
        let(:issue) { issue_locked }

        it { expect_disallowed(:reopen_issue) }
      end

      context 'on a hidden issue' do
        let(:issue) { hidden_issue }

        it { expect_disallowed(:read_issue, :update_issue, :admin_issue) }
      end
    end

    context 'for an owner' do
      let(:user) { owner }

      context 'on an issue with the notes widget' do
        it 'allows the note permissions' do
          expect_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
        end
      end

      context 'on an issue without the notes widget' do
        before do
          stub_work_item_widget(issue, notes: false)
        end

        it 'disallows the note permissions' do
          expect_disallowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
        end
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

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it { expect_allowed(:read_issue, :read_issue_iid, :read_note, :update_issue) }
      end

      context 'on a confidential issue they did not create' do
        let(:issue) { confidential_issue_no_assignee }

        it { expect_disallowed(:read_issue, :read_issue_iid, :read_note, :update_issue) }
      end
    end

    context 'for an admin' do
      let(:user) { admin }

      context 'on a confidential issue without admin mode' do
        let(:issue) { confidential_issue }

        it { expect_allowed(:read_issue) }
      end

      context 'on a hidden issue', :enable_admin_mode do
        let(:issue) { hidden_issue }

        it { expect_allowed(:read_issue, :update_issue, :admin_issue) }
      end
    end

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
    end
  end

  # Group level issues need the epics license, which FOSS never has, so these only check the denied side.
  # spec/policies/work_item_policy_spec.rb checks group level work items with the license.
  context 'a group level issue without the epics license' do
    let_it_be(:group_reporter) { create(:user) }
    let_it_be(:issue_group) { create(:group, :public) }
    let_it_be(:issue) { create(:issue, :group_level, namespace: issue_group) }
    let_it_be(:confidential_issue) { create(:issue, :group_level, :confidential, namespace: issue_group) }

    before_all do
      issue_group.add_reporter(group_reporter)
    end

    before do
      stub_licensed_features(epics: false)
    end

    context 'for a group reporter' do
      let(:user) { group_reporter }

      context 'on an issue' do
        it { expect_disallowed(:read_issue, :read_note, :create_note, :award_emoji, :update_issue, :admin_issue) }
      end

      context 'on a confidential issue' do
        let(:issue) { confidential_issue }

        it { expect_disallowed(:read_issue, :read_note, :create_note, :award_emoji, :update_issue, :admin_issue) }
      end
    end
  end

  context 'with external authorization enabled' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project, :public) }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }

    before do
      enable_external_authorization_service_check
    end

    it 'can read the issue iid without accessing the external service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect_allowed(:read_issue_iid)
    end
  end

  describe 'crm permissions' do
    let(:user) { create(:user) }
    let(:subgroup) { create(:group, parent: create(:group)) }
    let(:project) { create(:project, group: subgroup) }
    let(:issue) { create(:issue, project: project) }

    context 'when project reporter' do
      it 'is disallowed' do
        project.add_reporter(user)

        expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts)
      end
    end

    context 'when subgroup reporter' do
      it 'is disallowed' do
        subgroup.add_reporter(user)

        expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts)
      end
    end

    context 'when root group reporter' do
      it 'is allowed' do
        subgroup.parent.add_reporter(user)

        expect_allowed(:read_crm_contacts, :set_issue_crm_contacts)
      end
    end

    context 'when crm disabled on subgroup' do
      let(:subgroup) { create(:group, :crm_disabled, parent: create(:group)) }

      it 'is disallowed' do
        subgroup.parent.add_reporter(user)

        expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts)
      end
    end

    context 'when personal namespace' do
      let(:project) { create(:project) }

      it 'is disallowed' do
        project.add_reporter(user)

        expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts)
      end
    end

    context 'when custom crm_group configured' do
      let_it_be_with_reload(:crm_settings) { create(:crm_settings, source_group: create(:group)) }
      let_it_be_with_reload(:subgroup) { create(:group, parent: create(:group), crm_settings: crm_settings) }
      let_it_be_with_reload(:project) { create(:project, group: subgroup) }

      context 'for support bot' do
        let(:user) { support_bot }

        context 'with service desk enabled' do
          before do
            allow(::Gitlab::Email::IncomingEmail).to receive_messages(enabled?: true, supports_wildcard?: true)

            project.update!(service_desk_enabled: true)
          end

          it { expect_allowed(:read_crm_contacts, :set_issue_crm_contacts) }
        end

        context 'with service desk disabled' do
          it { expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts) }
        end
      end

      context 'when custom crm_group guest' do
        it 'is disallowed' do
          subgroup.parent.add_reporter(user)
          crm_settings.source_group.add_guest(user)

          expect_disallowed(:read_crm_contacts, :set_issue_crm_contacts)
        end
      end

      context 'when custom crm_group reporter' do
        it 'is allowed' do
          subgroup.parent.add_reporter(user)
          crm_settings.source_group.add_reporter(user)

          expect_allowed(:read_crm_contacts, :set_issue_crm_contacts)
        end
      end
    end
  end

  context 'with incident issue type' do
    let_it_be_with_reload(:project) { create(:project, group: group, planners: planner, reporters: reporter, owners: owner) }
    let_it_be(:incident) { create(:issue, :incident, project: project) }
    let_it_be(:issue) { create(:issue, project: project) }

    context 'for a planner' do
      let(:user) { planner }

      context 'on an issue' do
        it { expect_allowed(:update_issue, :admin_issue, :destroy_issue) }
      end

      context 'on an incident' do
        let(:issue) { incident }

        it { expect_disallowed(:update_issue, :admin_issue, :destroy_issue) }
      end
    end

    context 'for a reporter' do
      let(:user) { reporter }

      context 'on an incident' do
        let(:issue) { incident }

        it { expect_allowed(:update_issue, :admin_issue) }
      end
    end

    context 'for an owner' do
      let(:user) { owner }

      context 'on an incident' do
        let(:issue) { incident }

        it { expect_allowed(:destroy_issue) }
      end
    end
  end
end
