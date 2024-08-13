# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::WorkItemHierarchy, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:type1) { create(:work_item_type, :non_default) }
  let_it_be(:type2) { create(:work_item_type, :non_default) }
  let_it_be(:hierarchy_restriction1) { create(:hierarchy_restriction, parent_type: type1, child_type: type2) }
  let_it_be(:hierarchy_restriction2) { create(:hierarchy_restriction, parent_type: type2, child_type: type2) }
  let_it_be(:hierarchy_restriction3) { create(:hierarchy_restriction, parent_type: type2, child_type: type1) }
  let_it_be(:item1) { create(:work_item, work_item_type: type1, project: project) }
  let_it_be(:item2) { create(:work_item, work_item_type: type2, project: project) }
  let_it_be(:item3) { create(:work_item, work_item_type: type2, project: project) }
  let_it_be(:item4) { create(:work_item, work_item_type: type1, project: project) }
  let_it_be(:ignored1) { create(:work_item, work_item_type: type1, project: project) }
  let_it_be(:ignored2) { create(:work_item, work_item_type: type2, project: project) }
  let_it_be(:link1) { create(:parent_link, work_item_parent: item1, work_item: item2) }
  let_it_be(:link2) { create(:parent_link, work_item_parent: item2, work_item: item3) }
  let_it_be(:link3) { create(:parent_link, work_item_parent: item3, work_item: item4) }

  let(:options) { {} }

  describe '#base_and_ancestors' do
    subject { described_class.new(::WorkItem.where(id: item3.id), options: options) }

    it 'includes the base and its ancestors' do
      relation = subject.base_and_ancestors

      expect(relation).to eq([item3, item2, item1])
    end

    context 'when same_type option is used' do
      let(:options) { { same_type: true } }

      it 'includes the base and its ancestors' do
        relation = subject.base_and_ancestors

        expect(relation).to eq([item3, item2])
      end
    end

    it 'can find ancestors upto a certain level' do
      relation = subject.base_and_ancestors(upto: item1)

      expect(relation).to eq([item3, item2])
    end

    describe 'hierarchy_order option' do
      let(:relation) do
        subject.base_and_ancestors(hierarchy_order: hierarchy_order)
      end

      context 'for :asc' do
        let(:hierarchy_order) { :asc }

        it 'orders by child to ancestor' do
          expect(relation).to eq([item3, item2, item1])
        end
      end

      context 'for :desc' do
        let(:hierarchy_order) { :desc }

        it 'orders by ancestor to child' do
          expect(relation).to eq([item1, item2, item3])
        end
      end
    end
  end

  describe '#base_and_descendants' do
    subject { described_class.new(::WorkItem.where(id: item2.id), options: options) }

    it 'includes the base and its descendants' do
      relation = subject.base_and_descendants

      expect(relation).to eq([item2, item3, item4])
    end

    context 'when same_type option is used' do
      let(:options) { { same_type: true } }

      it 'includes the base and its ancestors' do
        relation = subject.base_and_descendants

        expect(relation).to eq([item2, item3])
      end
    end

    context 'when with_depth is true' do
      let(:relation) do
        subject.base_and_descendants(with_depth: true)
      end

      it 'includes depth in the results' do
        object_depths = {
          item2.id => 1,
          item3.id => 2,
          item4.id => 3
        }

        relation.each do |object|
          expect(object.depth).to eq(object_depths[object.id])
        end
      end
    end
  end
end
