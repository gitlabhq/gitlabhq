# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveTicketWorkItemTypeWrongHierarchyRestrictions, :migration_with_transaction, feature_category: :team_planning do
  describe '#up', :migration_with_transaction do
    let(:hierarchy_restrictions) { table(:work_item_hierarchy_restrictions) }
    let(:work_item_types) { table(:work_item_types) }
    let(:task_id) { described_class::TASK_ID }
    let(:ticket_id) { described_class::TICKET_ID }
    let!(:new_type1) { work_item_types.create!(name: 'Type1', base_type: 0, id: 100) }
    let!(:new_type2) { work_item_types.create!(name: 'Type2', base_type: 0, id: 101) }
    let!(:task_type) do
      work_item_types.find_or_create_by!(id: task_id) do |type|
        type.name = 'Task'
        type.base_type = 0
      end
    end

    let!(:ticket_type) do
      work_item_types.find_or_create_by!(id: ticket_id) do |type|
        type.name = 'Ticket'
        type.base_type = 0
      end
    end

    let(:valid_restriction1) do
      hierarchy_restrictions.create!(parent_type_id: ticket_type.id, child_type_id: task_type.id)
    end

    let(:valid_restriction2) do
      hierarchy_restrictions.create!(parent_type_id: task_type.id, child_type_id: task_type.id)
    end

    let(:invalid_restriction1) do
      hierarchy_restrictions.create!(parent_type_id: ticket_type.id, child_type_id: new_type1.id)
    end

    let(:invalid_restriction2) do
      hierarchy_restrictions.create!(parent_type_id: new_type2.id, child_type_id: ticket_type.id)
    end

    before do
      hierarchy_restrictions.delete_all

      valid_restriction1
      valid_restriction2
      invalid_restriction1
      invalid_restriction2
    end

    it 'removes any hierarchy restrictions for ticket type, but the valid one for task type' do
      expect do
        migrate!
      end.to change { hierarchy_restrictions.count }.from(4).to(2)

      expect(hierarchy_restrictions.pluck(:id)).to include(valid_restriction1.id, valid_restriction2.id)
    end
  end
end
