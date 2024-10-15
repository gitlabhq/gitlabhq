# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueSidebarBasicEntity, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user, developer_of: project) }
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
          issue.update!(
            work_item_type: WorkItems::Type.default_by_type(:incident)
          )
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
      end
    end
  end

  describe 'show_crm_contacts' do
    using RSpec::Parameterized::TableSyntax

    where(:is_reporter, :contacts_exist_for_crm_group, :expected) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      it 'sets proper boolean value for show_crm_contacts' do
        allow(CustomerRelations::Contact).to receive(:exists_for_group?).with(group).and_return(contacts_exist_for_crm_group)

        if is_reporter
          project.crm_group.add_reporter(user)
        end

        expect(entity[:show_crm_contacts]).to be(expected)
      end
    end

    context 'in subgroup' do
      let(:subgroup_project) { create(:project, :repository, group: subgroup) }
      let(:subgroup_issue) { create(:issue, project: subgroup_project) }
      let(:serializer) { IssueSerializer.new(current_user: user, project: subgroup_project) }

      subject(:entity) { serializer.represent(subgroup_issue, serializer: 'sidebar') }

      before do
        subgroup_project.crm_group.add_reporter(user)
      end

      context 'with crm enabled' do
        let(:subgroup) { create(:group, parent: group) }

        it 'is true' do
          allow(CustomerRelations::Contact).to receive(:exists_for_group?).with(group).and_return(true)

          expect(entity[:show_crm_contacts]).to be_truthy
        end
      end

      context 'with crm disabled' do
        let(:subgroup) { create(:group, :crm_disabled, parent: group) }

        it 'is false' do
          allow(CustomerRelations::Contact).to receive(:exists_for_group?).with(group).and_return(true)

          expect(entity[:show_crm_contacts]).to be_falsy
        end
      end
    end
  end
end
