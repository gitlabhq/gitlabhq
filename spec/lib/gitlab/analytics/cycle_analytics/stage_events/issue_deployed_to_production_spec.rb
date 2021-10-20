# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::IssueDeployedToProduction do
  it_behaves_like 'value stream analytics event'

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:record_with_data) do
      mr_closing_issue = FactoryBot.create(:merge_requests_closing_issues)
      mr = mr_closing_issue.merge_request
      mr.metrics.update!(first_deployed_to_production_at: Time.current)

      mr_closing_issue.issue
    end

    let_it_be(:record_without_data) { create(:issue) }
  end
end
