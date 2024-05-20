# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsClosingIssues, feature_category: :code_review_workflow do
  let_it_be(:namespace) { create_default(:namespace).freeze }
  let_it_be(:project) { create_default(:project, :repository).freeze }
  let_it_be(:merge_request) { create_default(:merge_request, source_project: project).freeze }

  describe 'scopes' do
    describe '.from_mr_description' do
      let(:issue1) { create(:issue, project: project) }
      let(:issue2) { create(:issue, project: project) }
      let!(:closes_issue1) { create(:merge_requests_closing_issues, issue: issue1, merge_request: merge_request) }

      before do
        create(:merge_requests_closing_issues, issue: issue2, merge_request: merge_request, from_mr_description: false)
      end

      subject { described_class.from_mr_description }

      it { is_expected.to contain_exactly(closes_issue1) }
    end
  end
end
