# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItemsHelper, feature_category: :team_planning do
  include Devise::Test::ControllerHelpers

  before do
    stub_feature_flags(work_item_planning_view: false)
  end

  describe '#work_items_data' do
    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:generate_feed_token).with(:atom).and_return('atom-feed-token')
      allow(helper).to receive(:generate_feed_token).with(:ics).and_return('ics-feed-token')
    end

    shared_examples 'show new work item link' do
      def fetch_new_work_item(resource_parent, current_user)
        helper.work_items_data(resource_parent, current_user)[:show_new_work_item]
      end

      it 'is true when the current user can create_work_item in resource parent' do
        allow(helper).to receive(:can?).and_call_original
        expect(helper).to receive(:can?).with(current_user, :create_work_item, resource_parent)
                                        .and_return(true)

        expect(fetch_new_work_item(resource_parent, current_user)).to eq('true')
      end

      it 'is false when the current user cannot create_work_item in resource parent' do
        allow(helper).to receive(:can?).and_call_original
        expect(helper).to receive(:can?).with(current_user, :create_work_item, resource_parent)
                                        .and_return(false)

        expect(fetch_new_work_item(resource_parent, current_user)).to eq('false')
      end

      it 'is false when resource parent is archived' do
        resource_parent.update!(archived: true)

        expect(fetch_new_work_item(resource_parent, current_user)).to eq('false')
      end

      it "is false when resource parent's parent is archived" do
        resource_parent.parent.update!(archived: true)

        expect(fetch_new_work_item(resource_parent, current_user)).to eq('false')
      end
    end

    describe 'with project context' do
      let_it_be(:project) { build(:project) }
      let_it_be(:current_user) { build(:user, owner_of: project) }

      before do
        allow(helper).to receive_messages(
          can?: true,
          safe_params: ActionController::Parameters.new(
            namespace_id: project.namespace.to_param,
            project_id: project.to_param
          ).permit!)
      end

      it 'returns the expected data properties' do
        expect(helper.work_items_data(project, current_user)).to include(
          {
            autocomplete_award_emojis_path: autocomplete_award_emojis_path,
            can_admin_label: 'true',
            can_bulk_update: 'true',
            full_path: project.full_path,
            group_path: nil,
            issues_list_path: project_issues_path(project),
            labels_manage_path: project_labels_path(project),
            project_namespace_full_path: project.namespace.full_path,
            register_path: new_user_registration_path(redirect_to_referer: 'yes'),
            sign_in_path: user_session_path(redirect_to_referer: 'yes'),
            report_abuse_path: add_category_abuse_reports_path,
            default_branch: project.default_branch_or_main,
            initial_sort: current_user&.user_preference&.issues_sort,
            is_signed_in: current_user.present?.to_s,
            is_issue_repositioning_disabled: 'false',
            time_tracking_limit_to_hours: "false",
            can_read_crm_organization: 'true',
            releases_path: project_releases_path(project, format: :json),
            project_import_jira_path: project_import_jira_path(project),
            can_read_crm_contact: 'true',
            rss_path: project_work_items_path(project, format: :atom, feed_token: 'atom-feed-token'),
            calendar_path: project_work_items_path(project,
              format: :ics,
              feed_token: 'ics-feed-token',
              due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
              sort: 'closest_future_date'),
            can_import_work_items: "true",
            can_edit: "true",
            export_csv_path: export_csv_project_issues_path(project),
            has_projects: 'false',
            new_issue_path: new_project_issue_path(project)
          }
        )
      end

      describe 'when project has parent group' do
        let_it_be(:group_project) { build(:project, group: build(:group)) }
        let_it_be(:current_user) { build(:user, owner_of: group_project) }

        it 'returns the expected data properties' do
          expect(helper.work_items_data(group_project, current_user)).to include(
            {
              group_path: group_project.group.full_path,
              show_new_work_item: 'true',
              has_projects: 'false'
            }
          )
        end
      end

      it 'returns the correct new trial path' do
        expect(helper).to respond_to(:self_managed_new_trial_url)
        allow(helper).to receive(:self_managed_new_trial_url).and_return('subscription_portal_trial_url')
        expect(helper.work_items_data(project, current_user)).to include(
          { new_trial_path: "subscription_portal_trial_url" }
        )
      end

      describe 'issue repositioning disabled' do
        context 'when project root namespace has issue repositioning disabled' do
          before do
            allow(project.root_namespace).to receive(:issue_repositioning_disabled?).and_return(true)
          end

          it 'returns is_issue_repositioning_disabled as true' do
            expect(helper.work_items_data(project, current_user)).to include(
              { is_issue_repositioning_disabled: 'true' }
            )
          end
        end

        context 'when project root namespace has issue repositioning enabled' do
          before do
            allow(project.root_namespace).to receive(:issue_repositioning_disabled?).and_return(false)
          end

          it 'returns is_issue_repositioning_disabled as false' do
            expect(helper.work_items_data(project, current_user)).to include(
              { is_issue_repositioning_disabled: 'false' }
            )
          end
        end
      end

      describe 'show_new_work_item' do
        let_it_be_with_reload(:resource_parent) { create(:project, group: create(:group)) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needed for .self_or_ancestors_archived?

        it_behaves_like 'show new work item link'

        it 'is true when the user is not logged in' do
          expect(helper.work_items_data(resource_parent, nil)[:show_new_work_item]).to eq('true')
        end
      end
    end

    context 'with group context' do
      let_it_be(:group) { build(:group) }
      let_it_be(:current_user) { build(:user, owner_of: group) }

      before do
        allow(helper).to receive_messages(
          safe_params: ActionController::Parameters.new(group_id: group.to_param).permit!
        )
      end

      it 'returns the expected group_path' do
        expect(helper.work_items_data(group, current_user)).to include(
          {
            issues_list_path: issues_group_path(group),
            labels_manage_path: group_labels_path(group),
            project_namespace_full_path: group.full_path,
            default_branch: nil,
            is_issue_repositioning_disabled: 'false',
            rss_path: group_work_items_path(group, format: :atom, feed_token: 'atom-feed-token'),
            calendar_path: group_work_items_path(group,
              format: :ics,
              feed_token: 'ics-feed-token',
              due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
              sort: 'closest_future_date')
          }
        )
      end

      it 'does not include project-specific data' do
        expect(helper.work_items_data(group, current_user)).not_to have_key(:releases_path)
        expect(helper.work_items_data(group, current_user)).not_to have_key(:export_csv_path)
      end

      describe 'issue repositioning disabled' do
        context 'when group root ancestor has issue repositioning disabled' do
          before do
            allow(group.root_ancestor).to receive(:issue_repositioning_disabled?).and_return(true)
          end

          it 'returns is_issue_repositioning_disabled as true' do
            expect(helper.work_items_data(group, current_user)).to include(
              { is_issue_repositioning_disabled: 'true' }
            )
          end
        end

        context 'when group root ancestor has issue repositioning enabled' do
          before do
            allow(group.root_ancestor).to receive(:issue_repositioning_disabled?).and_return(false)
          end

          it 'returns is_issue_repositioning_disabled as false' do
            expect(helper.work_items_data(group, current_user)).to include(
              { is_issue_repositioning_disabled: 'false' }
            )
          end
        end
      end

      describe 'has_projects' do
        context 'when a group has a project' do
          before do
            expect_next_instance_of(GroupProjectsFinder) do |finder|
              allow(finder).to receive_message_chain(:execute, :exists?).and_return(true)
            end
          end

          it 'returns true' do
            expect(helper.work_items_data(group, current_user)).to include(
              { has_projects: 'true' }
            )
          end
        end

        context 'when a group has no projects' do
          before do
            expect_next_instance_of(GroupProjectsFinder) do |finder|
              allow(finder).to receive_message_chain(:execute, :exists?).and_return(false)
            end
          end

          it 'returns false' do
            expect(helper.work_items_data(group, current_user)).to include(
              { has_projects: 'false' }
            )
          end
        end
      end
    end
  end

  describe '#work_item_views_only_data' do
    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:generate_feed_token).with(:atom).and_return('atom-feed-token')
      allow(helper).to receive(:generate_feed_token).with(:ics).and_return('ics-feed-token')
    end

    describe 'with project context' do
      let_it_be(:project) { build(:project) }
      let_it_be(:current_user) { build(:user, owner_of: project) }

      before do
        allow(helper).to receive_messages(
          can?: true,
          safe_params: ActionController::Parameters.new(
            namespace_id: project.namespace.to_param,
            project_id: project.to_param
          ).permit!)
      end

      it 'returns minimal server data' do
        expect(helper.work_item_views_only_data(project, current_user)).to include(
          {
            autocomplete_award_emojis_path: autocomplete_award_emojis_path,
            can_bulk_update: 'true',
            can_edit: 'true',
            full_path: project.full_path,
            group_path: nil,
            issues_list_path: project_issues_path(project),
            project_namespace_full_path: project.namespace.full_path,
            default_branch: project.default_branch_or_main,
            initial_sort: current_user&.user_preference&.issues_sort,
            is_signed_in: current_user.present?.to_s,
            is_issue_repositioning_disabled: 'false',
            time_tracking_limit_to_hours: "false",
            can_read_crm_organization: 'true',
            releases_path: project_releases_path(project, format: :json),
            project_import_jira_path: project_import_jira_path(project),
            can_read_crm_contact: 'true',
            rss_path: project_work_items_path(project, format: :atom, feed_token: 'atom-feed-token'),
            can_import_work_items: "true",
            export_csv_path: export_csv_project_issues_path(project),
            new_issue_path: new_project_issue_path(project),
            has_projects: 'false'
          }
        )
      end

      it 'does not include properties provided by GraphQL' do
        data = helper.work_item_views_only_data(project, current_user)
        # These are provided by GraphQL metadata provider, not server
        expect(data).not_to have_key(:can_admin_label)
        expect(data).not_to have_key(:can_create_projects)
        expect(data).not_to have_key(:labels_manage_path)
        expect(data).not_to have_key(:register_path)
        expect(data).not_to have_key(:sign_in_path)
        expect(data).not_to have_key(:new_comment_template_paths)
        expect(data).not_to have_key(:report_abuse_path)
        expect(data).not_to have_key(:new_project_path)
      end
    end
  end

  describe '#add_work_item_show_breadcrumb' do
    subject(:add_work_item_show_breadcrumb) { helper.add_work_item_show_breadcrumb(resource_parent, work_item.iid) }

    context 'on a group' do
      let_it_be(:resource_parent) { build_stubbed(:group) }
      let_it_be(:work_item) { build(:work_item, namespace: resource_parent) }

      it 'adds the correct breadcrumb' do
        expect(helper).to receive(:add_to_breadcrumbs).with('Issues', issues_group_path(resource_parent))

        add_work_item_show_breadcrumb
      end
    end

    context 'on a project' do
      let_it_be(:resource_parent) { build_stubbed(:project) }
      let_it_be(:work_item) { build(:work_item, namespace: resource_parent.namespace) }

      it 'adds the correct breadcrumb' do
        expect(helper).to receive(:add_to_breadcrumbs).with('Issues', project_issues_path(resource_parent))

        add_work_item_show_breadcrumb
      end
    end
  end
end
