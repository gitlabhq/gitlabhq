# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::WorkItemHierarchy, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }

  let_it_be(:epic1) { create(:work_item, :epic, project: project) }
  let_it_be(:epic2) { create(:work_item, :epic, project: project) }
  let_it_be(:epic3) { create(:work_item, :epic, project: project) }
  let_it_be(:issue1) { create(:work_item, :issue, project: project) }
  let_it_be(:task1) { create(:work_item, :task, project: project) }

  let_it_be(:ignored_epic) { create(:work_item, :epic, project: project) }
  let_it_be(:ignored_issue) { create(:work_item, :issue, project: project) }

  # Create hierarchy: epic1 -> epic2 -> epic3 -> issue1 -> task1
  let_it_be(:link1) { create(:parent_link, work_item_parent: epic1, work_item: epic2) }
  let_it_be(:link2) { create(:parent_link, work_item_parent: epic2, work_item: epic3) }
  let_it_be(:link3) { create(:parent_link, work_item_parent: epic3, work_item: issue1) }
  let_it_be(:link4) { create(:parent_link, work_item_parent: issue1, work_item: task1) }

  let(:options) { {} }

  describe '#base_and_ancestors' do
    subject { described_class.new(::WorkItem.where(id: issue1.id), options: options) }

    it 'includes the base and its ancestors' do
      relation = subject.base_and_ancestors

      expect(relation).to match_array([issue1, epic3, epic2, epic1])
    end

    context 'when same_type option is used' do
      # Use epic3 as subject since it has same-type ancestors
      subject { described_class.new(::WorkItem.where(id: epic3.id), options: options) }

      let(:options) { { same_type: true } }

      it 'includes the base and its ancestors of the same type' do
        relation = subject.base_and_ancestors

        expect(relation).to match_array([epic3, epic2, epic1])
      end
    end

    it 'can find ancestors upto a certain level' do
      relation = subject.base_and_ancestors(upto: epic2)

      expect(relation).to match_array([issue1, epic3])
    end

    describe 'hierarchy_order option' do
      let(:relation) do
        subject.base_and_ancestors(hierarchy_order: hierarchy_order)
      end

      context 'for :asc' do
        let(:hierarchy_order) { :asc }

        it 'orders by child to ancestor' do
          expect(relation).to match_array([issue1, epic3, epic2, epic1])
        end
      end

      context 'for :desc' do
        let(:hierarchy_order) { :desc }

        it 'orders by ancestor to child' do
          expect(relation).to match_array([epic1, epic2, epic3, issue1])
        end
      end
    end
  end

  describe '#base_and_descendants' do
    subject { described_class.new(::WorkItem.where(id: epic2.id), options: options) }

    it 'includes the base and its descendants' do
      relation = subject.base_and_descendants

      expect(relation).to match_array([epic2, epic3, issue1, task1])
    end

    context 'when same_type option is used' do
      let(:options) { { same_type: true } }

      it 'includes the base and its descendants of the same type' do
        relation = subject.base_and_descendants

        expect(relation).to match_array([epic2, epic3])
      end
    end

    context 'when with_depth is true' do
      let(:relation) do
        subject.base_and_descendants(with_depth: true)
      end

      it 'includes depth in the results' do
        object_depths = {
          epic2.id => 1,
          epic3.id => 2,
          issue1.id => 3,
          task1.id => 4
        }

        relation.each do |object|
          expect(object.depth).to eq(object_depths[object.id])
        end
      end
    end
  end

  describe 'with objective hierarchy' do
    let_it_be(:objective1) { create(:work_item, :objective, project: project) }
    let_it_be(:objective2) { create(:work_item, :objective, project: project) }
    let_it_be(:objective3) { create(:work_item, :objective, project: project) }
    let_it_be(:key_result) { create(:work_item, :key_result, project: project) }

    let_it_be(:obj_link1) { create(:parent_link, work_item_parent: objective1, work_item: objective2) }
    let_it_be(:obj_link2) { create(:parent_link, work_item_parent: objective2, work_item: objective3) }
    let_it_be(:obj_link3) { create(:parent_link, work_item_parent: objective3, work_item: key_result) }

    describe '#base_and_ancestors for objectives' do
      subject { described_class.new(::WorkItem.where(id: key_result.id), options: options) }

      it 'includes key result and all objective ancestors' do
        relation = subject.base_and_ancestors

        expect(relation).to match_array([key_result, objective3, objective2, objective1])
      end

      context 'when same_type option is used' do
        subject { described_class.new(::WorkItem.where(id: objective3.id), options: options) }

        let(:options) { { same_type: true } }

        it 'includes only objectives' do
          relation = subject.base_and_ancestors

          expect(relation).to match_array([objective3, objective2, objective1])
        end
      end
    end
  end
end
