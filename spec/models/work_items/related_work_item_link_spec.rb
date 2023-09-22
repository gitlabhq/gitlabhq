# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLink, type: :model, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:work_item, :issue, project: project) }

  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:work_item_link) }
    let_it_be(:issuable) { issue }
    let_it_be(:issuable2) { create(:work_item, :issue, project: project) }
    let_it_be(:issuable3) { create(:work_item, :issue, project: project) }
    let(:issuable_class) { 'WorkItem' }
    let(:issuable_link_factory) { :work_item_link }
  end

  it_behaves_like 'includes LinkableItem concern' do
    let_it_be(:item) { create(:work_item, project: project) }
    let_it_be(:item1) { create(:work_item, project: project) }
    let_it_be(:item2) { create(:work_item, project: project) }
    let_it_be(:link_factory) { :work_item_link }
    let_it_be(:item_type) { described_class.issuable_name }
  end

  describe '.issuable_type' do
    it { expect(described_class.issuable_type).to eq(:issue) }
  end

  describe '.issuable_name' do
    it { expect(described_class.issuable_name).to eq('work item') }
  end
end
