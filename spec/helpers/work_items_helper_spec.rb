# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItemsHelper, feature_category: :team_planning do
  include Devise::Test::ControllerHelpers

  describe '#work_items_show_data' do
    describe 'with project context' do
      let_it_be(:project) { build(:project) }
      let_it_be(:current_user) { build(:user, owner_of: project) }

      before do
        allow(helper).to receive(:can?).and_return(true)
      end

      it 'returns the expected data properties' do
        expect(helper.work_items_show_data(project, current_user)).to include(
          {
            autocomplete_award_emojis_path: autocomplete_award_emojis_path,
            can_admin_label: 'true',
            full_path: project.full_path,
            group_path: nil,
            issues_list_path: project_issues_path(project),
            labels_manage_path: project_labels_path(project),
            register_path: new_user_registration_path(redirect_to_referer: 'yes'),
            sign_in_path: user_session_path(redirect_to_referer: 'yes'),
            new_comment_template_paths:
              [{ text: "Your comment templates", href: profile_comment_templates_path }].to_json,
            report_abuse_path: add_category_abuse_reports_path,
            default_branch: project.default_branch_or_main,
            initial_sort: current_user&.user_preference&.issues_sort,
            is_signed_in: current_user.present?.to_s
          }
        )
      end

      describe 'when project has parent group' do
        let_it_be(:group_project) { build(:project, group: build(:group)) }
        let_it_be(:current_user) { build(:user, owner_of: group_project) }

        it 'returns the expected data properties' do
          expect(helper.work_items_show_data(group_project, current_user)).to include(
            {
              group_path: group_project.group.full_path,
              show_new_issue_link: 'true'
            }
          )
        end
      end
    end

    context 'with group context' do
      let_it_be(:group) { build(:group) }
      let_it_be(:current_user) { build(:user, owner_of: group) }

      it 'returns the expected group_path' do
        expect(helper.work_items_show_data(group, current_user)).to include(
          {
            issues_list_path: issues_group_path(group),
            labels_manage_path: group_labels_path(group),
            default_branch: nil
          }
        )
      end
    end
  end

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needed for querying the work item type
  describe '#add_work_item_show_breadcrumb' do
    subject(:add_work_item_show_breadcrumb) { helper.add_work_item_show_breadcrumb(resource_parent, work_item.iid) }

    context 'on a group' do
      let_it_be(:resource_parent) { create(:group) }
      let_it_be(:work_item) { build(:work_item, namespace: resource_parent) }

      it 'adds the correct breadcrumb' do
        expect(helper).to receive(:add_to_breadcrumbs).with('Issues', issues_group_path(resource_parent))

        add_work_item_show_breadcrumb
      end
    end

    context 'on a project' do
      let_it_be(:resource_parent) { build(:project) }
      let_it_be(:work_item) { build(:work_item, namespace: resource_parent.namespace) }

      it 'adds the correct breadcrumb' do
        expect(helper).to receive(:add_to_breadcrumbs).with('Issues', project_issues_path(resource_parent))

        add_work_item_show_breadcrumb
      end
    end
  end
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  describe '#work_items_list_data' do
    let_it_be(:group) { build(:group) }

    let(:current_user) { double.as_null_object }

    subject(:work_items_list_data) { helper.work_items_list_data(group, current_user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns expected data' do
      expect(work_items_list_data).to include(
        {
          autocomplete_award_emojis_path: autocomplete_award_emojis_path,
          full_path: group.full_path,
          initial_sort: current_user&.user_preference&.issues_sort,
          is_signed_in: current_user.present?.to_s,
          show_new_issue_link: 'true',
          issues_list_path: issues_group_path(group),
          report_abuse_path: add_category_abuse_reports_path,
          labels_manage_path: group_labels_path(group),
          can_admin_label: 'true'
        }
      )
    end
  end
end
