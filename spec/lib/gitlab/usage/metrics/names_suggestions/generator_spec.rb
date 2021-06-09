# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::NamesSuggestions::Generator do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
  end

  describe '#generate' do
    shared_examples 'name suggestion' do
      it 'return correct name' do
        expect(described_class.generate(key_path)).to match name_suggestion
      end
    end

    context 'for count with default column metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with count(Board)
        let(:key_path) { 'counts.boards' }
        let(:name_suggestion) { /count_boards/ }
      end
    end

    context 'for count distinct with column defined metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with distinct_count(ZoomMeeting, :issue_id)
        let(:key_path) { 'counts.issues_using_zoom_quick_actions' }
        let(:name_suggestion) { /count_distinct_issue_id_from_zoom_meetings/ }
      end
    end

    context 'joined relations' do
      context 'counted attribute comes from source relation' do
        it_behaves_like 'name suggestion' do
          # corresponding metric is collected with count(Issue.with_alert_management_alerts.not_authored_by(::User.alert_bot), start: issue_minimum_id, finish: issue_maximum_id)
          let(:key_path) { 'counts.issues_created_manually_from_alerts' }
          let(:name_suggestion) { /count_<adjective describing\: '\(issues\.author_id != \d+\)'>_issues_<with>_alert_management_alerts/ }
        end
      end
    end

    context 'strips off time period constraint' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with distinct_count(::Clusters::Cluster.aws_installed.enabled.where(time_period), :user_id)
        let(:key_path) { 'usage_activity_by_stage_monthly.configure.clusters_platforms_eks' }
        let(:constraints) { /<adjective describing\: '\(clusters.provider_type = \d+ AND \(cluster_providers_aws\.status IN \(\d+\)\) AND clusters\.enabled = TRUE\)'>/ }
        let(:name_suggestion) { /count_distinct_user_id_from_#{constraints}_clusters_<with>_#{constraints}_cluster_providers_aws/ }
      end
    end

    context 'for sum metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with sum(JiraImportState.finished, :imported_issues_count)
        let(:key_path) { 'counts.jira_imports_total_imported_issues_count' }
        let(:name_suggestion) { /sum_imported_issues_count_from_<adjective describing\: '\(jira_imports\.status = \d+\)'>_jira_imports/ }
      end
    end

    context 'for add metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with add(data[:personal_snippets], data[:project_snippets])
        let(:key_path) { 'counts.snippets' }
        let(:name_suggestion) { /add_count_<adjective describing\: '\(snippets\.type = 'PersonalSnippet'\)'>_snippets_and_count_<adjective describing\: '\(snippets\.type = 'ProjectSnippet'\)'>_snippets/ }
      end
    end

    context 'for redis metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with redis_usage_data { unique_visit_service.unique_visits_for(targets: :analytics) }
        let(:key_path) { 'analytics_unique_visits.analytics_unique_visits_for_any_target' }
        let(:name_suggestion) { /<please fill metric name, suggested format is: {subject}_{verb}{ing|ed}_{object} eg: users_creating_epics or merge_requests_viewed_in_single_file_mode>/ }
      end
    end

    context 'for alt_usage_data metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with alt_usage_data(fallback: nil) { operating_system }
        let(:key_path) { 'settings.operating_system' }
        let(:name_suggestion) { /<please fill metric name>/ }
      end
    end
  end
end
