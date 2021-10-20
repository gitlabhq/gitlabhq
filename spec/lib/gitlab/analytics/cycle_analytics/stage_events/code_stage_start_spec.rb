# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::CodeStageStart do
  let(:subject) { described_class.new({}) }
  let(:project) { create(:project) }

  it_behaves_like 'value stream analytics event'

  it 'needs connection with an issue via merge_requests_closing_issues table' do
    issue = create(:issue, project: project)
    merge_request = create(:merge_request, source_project: project)
    create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)

    other_merge_request = create(:merge_request, source_project: project, source_branch: 'a', target_branch: 'master')

    records = subject.apply_query_customization(MergeRequest.all).where.not('merge_requests_closing_issues.issue_id' => nil)
    expect(records).to eq([merge_request])
    expect(records).not_to include(other_merge_request)
  end

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:record_with_data) do
      mr_closing_issue = FactoryBot.create(:merge_requests_closing_issues)
      issue = mr_closing_issue.issue
      issue.metrics.update!(first_mentioned_in_commit_at: Time.current)

      mr_closing_issue.merge_request
    end

    let_it_be(:record_without_data) { create(:merge_request) }
  end
end
