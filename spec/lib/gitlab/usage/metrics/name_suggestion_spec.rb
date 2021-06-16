# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::NameSuggestion do
  describe '#for' do
    shared_examples 'name suggestion' do
      it 'return correct name' do
        expect(described_class.for(operation, relation: relation, column: column)).to match name_suggestion
      end
    end

    context 'for count with nil column' do
      it_behaves_like 'name suggestion' do
        let(:operation) { :count }
        let(:relation) { Board }
        let(:column) { nil }
        let(:name_suggestion) { /count_boards/ }
      end
    end

    context 'for count with column :id' do
      it_behaves_like 'name suggestion' do
        let(:operation) { :count }
        let(:relation) { Board }
        let(:column) { :id }
        let(:name_suggestion) { /count_boards/ }
      end
    end

    context 'for count distinct with column defined metrics' do
      it_behaves_like 'name suggestion' do
        let(:operation) { :distinct_count }
        let(:relation) { ZoomMeeting }
        let(:column) { :issue_id }
        let(:name_suggestion) { /count_distinct_issue_id_from_zoom_meetings/ }
      end
    end

    context 'joined relations' do
      context 'counted attribute comes from source relation' do
        it_behaves_like 'name suggestion' do
          # corresponding metric is collected with count(Issue.with_alert_management_alerts.not_authored_by(::User.alert_bot), start: issue_minimum_id, finish: issue_maximum_id)
          let(:operation) { :count }
          let(:relation) { Issue.with_alert_management_alerts.not_authored_by(::User.alert_bot) }
          let(:column) { nil }
          let(:name_suggestion) { /count_<adjective describing\: '\(issues\.author_id != \d+\)'>_issues_<with>_alert_management_alerts/ }
        end
      end
    end

    context 'strips off time period constraint' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with distinct_count(::Clusters::Cluster.aws_installed.enabled.where(time_period), :user_id)
        let(:operation) { :distinct_count }
        let(:relation) { ::Clusters::Cluster.aws_installed.enabled.where(created_at: 30.days.ago..2.days.ago ) }
        let(:column) { :user_id }
        let(:constraints) { /<adjective describing\: '\(clusters.provider_type = \d+ AND \(cluster_providers_aws\.status IN \(\d+\)\) AND clusters\.enabled = TRUE\)'>/ }
        let(:name_suggestion) { /count_distinct_user_id_from_#{constraints}_clusters_<with>_#{constraints}_cluster_providers_aws/ }
      end
    end

    context 'for sum metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with sum(JiraImportState.finished, :imported_issues_count)
        let(:key_path) { 'counts.jira_imports_total_imported_issues_count' }
        let(:operation) { :sum }
        let(:relation) { JiraImportState.finished }
        let(:column) { :imported_issues_count}
        let(:name_suggestion) { /sum_imported_issues_count_from_<adjective describing\: '\(jira_imports\.status = \d+\)'>_jira_imports/ }
      end
    end

    context 'for redis metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with redis_usage_data { unique_visit_service.unique_visits_for(targets: :analytics) }
        let(:operation) { :redis }
        let(:column) { nil }
        let(:relation) { nil }
        let(:name_suggestion) { /<please fill metric name, suggested format is: {subject}_{verb}{ing|ed}_{object} eg: users_creating_epics or merge_requests_viewed_in_single_file_mode>/ }
      end
    end

    context 'for alt_usage_data metrics' do
      it_behaves_like 'name suggestion' do
        # corresponding metric is collected with alt_usage_data(fallback: nil) { operating_system }
        let(:operation) { :alt }
        let(:column) { nil }
        let(:relation) { nil }
        let(:name_suggestion) { /<please fill metric name>/ }
      end
    end
  end
end
