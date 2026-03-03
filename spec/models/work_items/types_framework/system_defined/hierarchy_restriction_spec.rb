# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::SystemDefined::HierarchyRestriction, feature_category: :team_planning do
  let_it_be(:issue_id) { build(:work_item_system_defined_type, :issue).id }
  let_it_be(:task_id) { build(:work_item_system_defined_type, :task).id }
  let_it_be(:ticket_id) { build(:work_item_system_defined_type, :ticket).id }

  describe 'included modules' do
    subject { described_class }

    it { is_expected.to include(ActiveRecord::FixedItemsModel::Model) }
  end

  describe '.fixed_items' do
    it 'has the correct structure for each item' do
      expect(described_class.fixed_items).to all(
        include(:parent_type_id, :child_type_id, :maximum_depth)
      )
    end

    context 'when child type is not found' do
      it 'skips invalid child type configurations' do
        type_with_invalid_child = build(:work_item_system_defined_type, :issue)

        allow(WorkItems::TypesFramework::SystemDefined::Type).to receive(:all).and_return([type_with_invalid_child])
        allow(WorkItems::TypesFramework::SystemDefined::Type).to receive(:find_by_type)
          .with(:task).and_return(nil)

        expect(described_class.fixed_items).to eq([[]])
      end
    end

    it 'defines unique hierarchy restrictions' do
      parent_child_pairs = described_class.fixed_items.map do |item|
        [item[:parent_type_id], item[:child_type_id]]
      end

      expect(parent_child_pairs).to eq(parent_child_pairs.uniq)
    end

    describe 'defined hierarchies' do
      using RSpec::Parameterized::TableSyntax

      # This tests that the system defined data contains the expected restrictions
      where(:parent_type_sym, :child_type_sym, :max_depth) do
        :issue      | :task       | 1
        :incident   | :task       | 1
        :epic       | :epic       | 7
        :epic       | :issue      | 1
        :epic       | :ticket     | 1
        :objective  | :objective  | 9
        :objective  | :key_result | 1
        :ticket     | :task       | 1
      end

      with_them do
        it 'correctly defines hierarchy restrictions' do
          # Define EE-only types
          ee_types = %i[epic objective key_result]

          # Skip if either type is EE-only and we're in CE
          if (ee_types.include?(parent_type_sym) || ee_types.include?(child_type_sym)) && !Gitlab.ee?
            skip 'EE-only type'
          end

          base_class = "WorkItems::TypesFramework::SystemDefined::Definitions"
          parent_id = "#{base_class}::#{parent_type_sym.to_s.classify}".constantize.configuration[:id]
          child_id = "#{base_class}::#{child_type_sym.to_s.classify}".constantize.configuration[:id]

          expect(described_class.all).to include(
            have_attributes(
              parent_type_id: parent_id,
              child_type_id: child_id,
              maximum_depth: max_depth
            )
          )
        end
      end
    end
  end

  describe 'usage by ParentLink' do
    it 'can be queried by parent and child type IDs' do
      restriction = described_class.find_by(
        parent_type_id: issue_id,
        child_type_id: task_id
      )

      expect(restriction).not_to be_nil
      expect(restriction.maximum_depth).to eq(1)
    end
  end

  describe '.with_parent_type_id' do
    it 'returns hierarchy restrictions with the specified parent type' do
      restrictions = described_class.with_parent_type_id(issue_id)
      expect(restrictions.map(&:parent_type_id).uniq).to match_array([issue_id])
    end
  end

  describe '.hierarchy_relationship_allowed?' do
    it 'returns true if a hierarchical relationship is allowed' do
      result = described_class.hierarchy_relationship_allowed?(
        parent_type_id: issue_id,
        child_type_id: task_id
      )

      expect(result).to be true
    end

    it 'returns false if a hierarchical relationship is not allowed' do
      result = described_class.hierarchy_relationship_allowed?(
        parent_type_id: issue_id,
        child_type_id: ticket_id
      )

      expect(result).to be false
    end
  end
end
