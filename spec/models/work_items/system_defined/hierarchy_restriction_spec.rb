# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SystemDefined::HierarchyRestriction, feature_category: :team_planning do
  describe 'included modules' do
    subject { described_class }

    it { is_expected.to include(ActiveRecord::FixedItemsModel::Model) }
  end

  describe 'ITEMS configuration' do
    it 'has the correct structure for each item' do
      expect(described_class::ITEMS).to all(
        include(:id, :parent_type_id, :child_type_id, :maximum_depth)
      )
    end

    it 'defines unique IDs' do
      ids = described_class::ITEMS.map { |item| item[:id] } # rubocop:disable Rails/Pluck -- Not an ActiveRecord object
      expect(ids).to eq(ids.uniq)
    end

    it 'defines unique hierarchy restrictions' do
      parent_child_pairs = described_class::ITEMS.map do |item|
        [item[:parent_type_id], item[:child_type_id]]
      end

      expect(parent_child_pairs).to eq(parent_child_pairs.uniq)
    end

    it 'references valid work item type IDs' do
      valid_type_ids = [
        described_class::EPIC_ID,
        described_class::ISSUE_ID,
        described_class::TASK_ID,
        described_class::OBJECTIVE_ID,
        described_class::KEY_RESULT_ID,
        described_class::INCIDENT_ID,
        described_class::TICKET_ID
      ]

      described_class::ITEMS.each do |item|
        expect(valid_type_ids).to include(item[:parent_type_id])
        expect(valid_type_ids).to include(item[:child_type_id])
      end
    end

    describe 'defined hierarchies' do
      using RSpec::Parameterized::TableSyntax

      # This tests that the system defined data contains the expected restrictions
      where(:parent_type_sym, :child_type_sym, :max_depth) do
        :issue      | :task       | 1
        :incident   | :task       | 1
        :epic       | :epic       | 7
        :epic       | :issue      | 1
        :objective  | :objective  | 9
        :objective  | :key_result | 1
        :ticket     | :task       | 1
      end

      with_them do
        it 'correctly defines hierarchy restrictions' do
          parent_id = described_class.const_get("#{parent_type_sym.upcase}_ID", false)
          child_id = described_class.const_get("#{child_type_sym.upcase}_ID", false)

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
        parent_type_id: described_class::EPIC_ID,
        child_type_id: described_class::ISSUE_ID
      )

      expect(restriction).not_to be_nil
      expect(restriction.maximum_depth).to eq(1)
    end
  end
end
