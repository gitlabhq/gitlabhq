# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsClosingIssuesPolicy, feature_category: :team_planning do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:merge_requests_closing_issue) { build_stubbed(:merge_requests_closing_issues) }

  describe 'read_merge_request_closing_issue' do
    using RSpec::Parameterized::TableSyntax

    where(:read_issue, :read_merge_request, :allowed) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      let(:policy) { described_class.new(user, merge_requests_closing_issue) }
      subject { policy.allowed?(:read_merge_request_closing_issue) }

      before do
        allow(policy).to receive(:can?).with(:read_issue, instance_of(Issue)).and_return(read_issue)
        allow(policy).to receive(:can?).with(
          :read_merge_request,
          instance_of(MergeRequest)
        ).and_return(read_merge_request)
      end

      it { is_expected.to eq(allowed) }
    end
  end
end
