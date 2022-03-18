# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueSidebarBasicEntity do
  let_it_be(:group) { create(:group, :crm_enabled) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [user]) }

  let(:serializer) { IssueSerializer.new(current_user: user, project: project) }

  subject(:entity) { serializer.represent(issue, serializer: 'sidebar') }

  it 'contains keys related to issuables' do
    expect(entity).to include(
      :id, :iid, :type, :author_id, :project_id, :discussion_locked, :reference, :milestone,
      :labels, :current_user, :issuable_json_path, :namespace_path, :project_path,
      :project_full_path, :project_issuables_path, :create_todo_path, :project_milestones_path,
      :project_labels_path, :toggle_subscription_path, :move_issue_path, :projects_autocomplete_path,
      :project_emails_disabled, :create_note_email, :supports_time_tracking, :supports_milestone,
      :supports_severity, :supports_escalation
    )
  end

  it 'contains attributes related to the issue' do
    expect(entity).to include(:due_date, :confidential, :severity)
  end

  describe 'current_user' do
    it 'contains attributes related to the current user' do
      expect(entity[:current_user]).to include(
        :id, :name, :username, :state, :avatar_url, :web_url, :todo,
        :can_edit, :can_move, :can_admin_label
      )
    end

    describe 'can_update_escalation_status' do
      context 'for a standard issue' do
        it 'is not present' do
          expect(entity[:current_user]).not_to have_key(:can_update_escalation_status)
        end
      end

      context 'for an incident issue' do
        before do
          issue.update!(issue_type: Issue.issue_types[:incident])
        end

        it 'is present and true' do
          expect(entity[:current_user][:can_update_escalation_status]).to be(true)
        end

        context 'without permissions' do
          let(:serializer) { IssueSerializer.new(current_user: create(:user), project: project) }

          it 'is present and false' do
            expect(entity[:current_user]).to have_key(:can_update_escalation_status)
            expect(entity[:current_user][:can_update_escalation_status]).to be(false)
          end
        end

        context 'with :incident_escalations feature flag disabled' do
          before do
            stub_feature_flags(incident_escalations: false)
          end

          it 'is not present' do
            expect(entity[:current_user]).not_to include(:can_update_escalation_status)
          end
        end
      end
    end
  end

  describe 'show_crm_contacts' do
    using RSpec::Parameterized::TableSyntax

    where(:is_reporter, :contacts_exist_for_group, :expected) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      it 'sets proper boolean value for show_crm_contacts' do
        allow(CustomerRelations::Contact).to receive(:exists_for_group?).with(group).and_return(contacts_exist_for_group)

        if is_reporter
          project.root_ancestor.add_reporter(user)
        end

        expect(entity[:show_crm_contacts]).to be(expected)
      end
    end
  end
end
