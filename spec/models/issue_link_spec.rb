# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLink do
  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:issue_link) }
    let_it_be(:issuable) { create(:issue) }
    let(:issuable_class) { 'Issue' }
    let(:issuable_link_factory) { :issue_link }
  end

  describe '.issuable_type' do
    it { expect(described_class.issuable_type).to eq(:issue) }
  end

  describe 'Scopes' do
    let_it_be(:issue1) { create(:issue) }
    let_it_be(:issue2) { create(:issue) }

    describe '.for_source_issue' do
      it 'includes linked issues for source issue' do
        source_issue = create(:issue)
        issue_link_1 = create(:issue_link, source: source_issue, target: issue1)
        issue_link_2 = create(:issue_link, source: source_issue, target: issue2)

        result = described_class.for_source_issue(source_issue)

        expect(result).to contain_exactly(issue_link_1, issue_link_2)
      end
    end

    describe '.for_target_issue' do
      it 'includes linked issues for target issue' do
        target_issue = create(:issue)
        issue_link_1 = create(:issue_link, source: issue1, target: target_issue)
        issue_link_2 = create(:issue_link, source: issue2, target: target_issue)

        result = described_class.for_target_issue(target_issue)

        expect(result).to contain_exactly(issue_link_1, issue_link_2)
      end
    end
  end
end
