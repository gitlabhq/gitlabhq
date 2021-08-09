# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataMetrics do
  describe '.uncached_data' do
    subject { described_class.uncached_data }

    around do |example|
      described_class.instance_variable_set(:@definitions, nil)
      example.run
      described_class.instance_variable_set(:@definitions, nil)
    end

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'with instrumentation_class' do
      it 'includes top level keys' do
        expect(subject).to include(:uuid)
        expect(subject).to include(:hostname)
      end

      it 'includes counts keys' do
        expect(subject[:counts]).to include(:boards)
      end

      it 'includes i_quickactions_approve monthly and weekly key' do
        expect(subject[:redis_hll_counters][:quickactions]).to include(:i_quickactions_approve_monthly)
        expect(subject[:redis_hll_counters][:quickactions]).to include(:i_quickactions_approve_weekly)
      end

      it 'includes ide_edit monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:ide_edit].keys).to contain_exactly(*[
          :g_edit_by_web_ide_monthly, :g_edit_by_web_ide_weekly,
          :g_edit_by_sfe_monthly, :g_edit_by_sfe_weekly,
          :g_edit_by_sse_monthly, :g_edit_by_sse_weekly,
          :g_edit_by_snippet_ide_monthly, :g_edit_by_snippet_ide_weekly,
          :ide_edit_total_unique_counts_monthly, :ide_edit_total_unique_counts_weekly
        ])
      end

      it 'includes incident_management_alerts monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:incident_management_alerts].keys).to contain_exactly(*[
          :incident_management_alert_create_incident_monthly, :incident_management_alert_create_incident_weekly
      ])
      end

      it 'includes incident_management monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:incident_management]).to include(
          :incident_management_incident_created_monthly, :incident_management_incident_created_weekly,
          :incident_management_incident_reopened_monthly, :incident_management_incident_reopened_weekly,
          :incident_management_incident_closed_monthly, :incident_management_incident_closed_weekly,
          :incident_management_incident_assigned_monthly, :incident_management_incident_assigned_weekly,
          :incident_management_incident_todo_monthly, :incident_management_incident_todo_weekly,
          :incident_management_incident_comment_monthly, :incident_management_incident_comment_weekly,
          :incident_management_incident_zoom_meeting_monthly, :incident_management_incident_zoom_meeting_weekly,
          :incident_management_incident_relate_monthly, :incident_management_incident_relate_weekly,
          :incident_management_incident_unrelate_monthly, :incident_management_incident_unrelate_weekly,
          :incident_management_incident_change_confidential_monthly, :incident_management_incident_change_confidential_weekly,
          :incident_management_alert_status_changed_monthly, :incident_management_alert_status_changed_weekly,
          :incident_management_alert_assigned_monthly, :incident_management_alert_assigned_weekly,
          :incident_management_alert_todo_monthly, :incident_management_alert_todo_weekly,
          :incident_management_total_unique_counts_monthly, :incident_management_total_unique_counts_weekly
        )
      end

      it 'includes testing monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:testing]).to include(
          :i_testing_test_case_parsed_monthly, :i_testing_test_case_parsed_weekly,
          :users_expanding_testing_code_quality_report_monthly, :users_expanding_testing_code_quality_report_weekly,
          :users_expanding_testing_accessibility_report_monthly, :users_expanding_testing_accessibility_report_weekly,
          :i_testing_summary_widget_total_monthly, :i_testing_summary_widget_total_weekly,
          :testing_total_unique_counts_monthly
        )
      end

      it 'includes source_code monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:source_code].keys).to contain_exactly(*[
          :wiki_action_monthly, :wiki_action_weekly,
          :design_action_monthly, :design_action_weekly,
          :project_action_monthly, :project_action_weekly,
          :git_write_action_monthly, :git_write_action_weekly,
          :merge_request_action_monthly, :merge_request_action_weekly,
          :i_source_code_code_intelligence_monthly, :i_source_code_code_intelligence_weekly
        ])
      end

      it 'includes issues_edit monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:issues_edit].keys).to include(
          :g_project_management_issue_title_changed_monthly, :g_project_management_issue_title_changed_weekly,
          :g_project_management_issue_description_changed_monthly, :g_project_management_issue_description_changed_weekly,
          :g_project_management_issue_assignee_changed_monthly, :g_project_management_issue_assignee_changed_weekly,
          :g_project_management_issue_made_confidential_monthly, :g_project_management_issue_made_confidential_weekly,
          :g_project_management_issue_made_visible_monthly, :g_project_management_issue_made_visible_weekly,
          :g_project_management_issue_created_monthly, :g_project_management_issue_created_weekly,
          :g_project_management_issue_closed_monthly, :g_project_management_issue_closed_weekly,
          :g_project_management_issue_reopened_monthly, :g_project_management_issue_reopened_weekly,
          :g_project_management_issue_label_changed_monthly, :g_project_management_issue_label_changed_weekly,
          :g_project_management_issue_milestone_changed_monthly, :g_project_management_issue_milestone_changed_weekly,
          :g_project_management_issue_cross_referenced_monthly, :g_project_management_issue_cross_referenced_weekly,
          :g_project_management_issue_moved_monthly, :g_project_management_issue_moved_weekly,
          :g_project_management_issue_related_monthly, :g_project_management_issue_related_weekly,
          :g_project_management_issue_unrelated_monthly, :g_project_management_issue_unrelated_weekly,
          :g_project_management_issue_marked_as_duplicate_monthly, :g_project_management_issue_marked_as_duplicate_weekly,
          :g_project_management_issue_locked_monthly, :g_project_management_issue_locked_weekly,
          :g_project_management_issue_unlocked_monthly, :g_project_management_issue_unlocked_weekly,
          :g_project_management_issue_designs_added_monthly, :g_project_management_issue_designs_added_weekly,
          :g_project_management_issue_designs_modified_monthly, :g_project_management_issue_designs_modified_weekly,
          :g_project_management_issue_designs_removed_monthly, :g_project_management_issue_designs_removed_weekly,
          :g_project_management_issue_due_date_changed_monthly, :g_project_management_issue_due_date_changed_weekly,
          :g_project_management_issue_time_estimate_changed_monthly, :g_project_management_issue_time_estimate_changed_weekly,
          :g_project_management_issue_time_spent_changed_monthly, :g_project_management_issue_time_spent_changed_weekly,
          :g_project_management_issue_comment_added_monthly, :g_project_management_issue_comment_added_weekly,
          :g_project_management_issue_comment_edited_monthly, :g_project_management_issue_comment_edited_weekly,
          :g_project_management_issue_comment_removed_monthly, :g_project_management_issue_comment_removed_weekly,
          :g_project_management_issue_cloned_monthly, :g_project_management_issue_cloned_weekly,
          :issues_edit_total_unique_counts_monthly, :issues_edit_total_unique_counts_weekly
        )
      end

      it 'includes counts keys' do
        expect(subject[:counts]).to include(:issues)
      end

      it 'includes usage_activity_by_stage keys' do
        expect(subject[:usage_activity_by_stage][:plan]).to include(:issues)
      end

      it 'includes usage_activity_by_stage_monthly keys' do
        expect(subject[:usage_activity_by_stage_monthly][:plan]).to include(:issues)
      end

      it 'includes settings keys' do
        expect(subject[:settings]).to include(:collected_data_categories)
      end
    end
  end
end
