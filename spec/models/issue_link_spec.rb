# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLink, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }

  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:issue_link) }
    let_it_be(:issuable) { create(:issue, project: project) }
    let_it_be(:issuable2) { create(:issue, project: project) }
    let_it_be(:issuable3) { create(:issue, project: project) }
    let(:issuable_class) { 'Issue' }
    let(:issuable_link_factory) { :issue_link }
  end

  describe '.issuable_type' do
    it { expect(described_class.issuable_type).to eq(:issue) }
  end

  describe '.issuable_name' do
    it { expect(described_class.issuable_name).to eq('issue') }
  end

  it_behaves_like 'includes LinkableItem concern' do
    let_it_be(:item) { create(:issue, project: project) }
    let_it_be(:item1) { create(:issue, project: project) }
    let_it_be(:item2) { create(:issue, project: project) }
    let_it_be(:link_factory) { :issue_link }
    let_it_be(:item_type) { 'issue' }
  end
end
