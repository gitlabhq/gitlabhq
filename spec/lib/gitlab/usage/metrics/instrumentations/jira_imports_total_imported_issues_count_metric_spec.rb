# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::JiraImportsTotalImportedIssuesCountMetric do
  let_it_be(:jira_import_state_1) { create(:jira_import_state, :finished, imported_issues_count: 3) }
  let_it_be(:jira_import_state_2) { create(:jira_import_state, :finished, imported_issues_count: 2) }

  let(:expected_value) { 5 }
  let(:expected_query) do
    'SELECT SUM("jira_imports"."imported_issues_count") FROM "jira_imports" WHERE "jira_imports"."status" = 4'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
