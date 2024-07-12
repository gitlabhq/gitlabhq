# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsClosingIssues, feature_category: :code_review_workflow do
  let_it_be(:namespace) { create_default(:namespace).freeze }
  let_it_be(:project) { create_default(:project, :repository).freeze }
  let_it_be(:merge_request) { create_default(:merge_request, source_project: project).freeze }
  let_it_be(:issue1) { create(:issue, project: project) }
  let_it_be(:issue2) { create(:issue, project: project) }
  let_it_be(:closes_issue1) { create(:merge_requests_closing_issues, issue: issue1, merge_request: merge_request) }

  describe 'scopes' do
    describe '.with_opened_merge_request' do
      let(:closed_merge_request) do
        create(:merge_request, :closed, source_project: project, target_branch: 'f2')
      end

      subject { described_class.with_opened_merge_request }

      before do
        create(:merge_requests_closing_issues, issue: issue2, merge_request: closed_merge_request)
      end

      it { is_expected.to contain_exactly(closes_issue1) }
    end

    describe '.from_mr_description' do
      before do
        create(:merge_requests_closing_issues, issue: issue2, merge_request: merge_request, from_mr_description: false)
      end

      subject { described_class.from_mr_description }

      it { is_expected.to contain_exactly(closes_issue1) }
    end
  end
end
