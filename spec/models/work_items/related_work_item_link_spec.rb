# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLink, type: :model, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:work_item, :issue, project: project) }

  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:work_item_link) }
    let_it_be(:issuable) { issue }
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

  describe 'validations' do
    let_it_be(:task1) { create(:work_item, :task, project: project) }
    let_it_be(:task2) { create(:work_item, :task, project: project) }
    let_it_be(:task3) { create(:work_item, :task, project: project) }

    subject(:link) { build(:work_item_link, source_id: task1.id, target_id: task2.id) }

    describe '#validate_max_number_of_links' do
      shared_examples 'invalid due to exceeding max number of links' do
        let(:error_msg) { 'This work item would exceed the maximum number of linked items.' }

        before do
          create(:work_item_link, source: source, target: target)
          stub_const("#{described_class}::MAX_LINKS_COUNT", 1)
        end

        specify do
          is_expected.to be_invalid
          expect(link.errors.messages[error_item]).to include(error_msg)
        end
      end

      context 'when source exceeds max' do
        let(:source) { task1 }
        let(:target) { task3 }
        let(:error_item) { :source }

        it_behaves_like 'invalid due to exceeding max number of links'
      end

      context 'when target exceeds max' do
        let(:source) { task2 }
        let(:target) { task3 }
        let(:error_item) { :target }

        it_behaves_like 'invalid due to exceeding max number of links'
      end
    end
  end

  describe '.issuable_type' do
    it { expect(described_class.issuable_type).to eq(:issue) }
  end

  describe '.issuable_name' do
    it { expect(described_class.issuable_name).to eq('work item') }
  end
end
