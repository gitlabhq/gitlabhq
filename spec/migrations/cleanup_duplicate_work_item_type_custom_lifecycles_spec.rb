# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupDuplicateWorkItemTypeCustomLifecycles, feature_category: :team_planning do
  let(:namespaces) { table(:namespaces) }
  let(:work_item_custom_statuses) { table(:work_item_custom_statuses) }
  let(:work_item_custom_lifecycles) { table(:work_item_custom_lifecycles) }
  let(:work_item_type_custom_lifecycles) { table(:work_item_type_custom_lifecycles) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:namespace_1) do
    namespaces.create!(name: 'namespace_1', path: 'namespace_1', type: 'Group', organization_id: organization.id)
  end

  let(:namespace_2) do
    namespaces.create!(name: 'namespace_2', path: 'namespace_2', type: 'Group', organization_id: organization.id)
  end

  let!(:lifecycle_1) { create_lifecycle(namespace_1.id) }
  let!(:lifecycle_2) { create_lifecycle(namespace_1.id) }
  let!(:lifecycle_3) { create_lifecycle(namespace_2.id) }

  let!(:type_custom_lifecycles_1) do
    work_item_type_custom_lifecycles.create!(
      namespace_id: namespace_1.id, lifecycle_id: lifecycle_1.id, work_item_type_id: 1
    )
  end

  let!(:type_custom_lifecycles_2) do
    work_item_type_custom_lifecycles.create!(
      namespace_id: namespace_1.id, lifecycle_id: lifecycle_1.id, work_item_type_id: 4
    )
  end

  let!(:type_custom_lifecycles_3) do
    work_item_type_custom_lifecycles.create!(
      namespace_id: namespace_2.id, lifecycle_id: lifecycle_3.id, work_item_type_id: 1
    )
  end

  describe '#up' do
    context 'when there are duplicate records' do
      let!(:type_custom_lifecycles_4) do
        work_item_type_custom_lifecycles.create!(
          namespace_id: namespace_1.id, lifecycle_id: lifecycle_2.id, work_item_type_id: 1
        )
      end

      it 'removes duplicate records keeping only the most recent one' do
        expect { migrate! }.to change { work_item_type_custom_lifecycles.count }.from(4).to(3)

        expect(work_item_type_custom_lifecycles.all).to contain_exactly(type_custom_lifecycles_2,
          type_custom_lifecycles_3, type_custom_lifecycles_4)
      end
    end

    context 'when there are no duplicate records' do
      it 'does not remove any records' do
        expect { migrate! }.not_to change { work_item_type_custom_lifecycles.count }

        expect(work_item_type_custom_lifecycles.all).to contain_exactly(type_custom_lifecycles_1,
          type_custom_lifecycles_2, type_custom_lifecycles_3)
      end
    end
  end

  describe '#down' do
    it 'is irreversible and does nothing' do
      expect { schema_migrate_down! }.not_to change { work_item_type_custom_lifecycles.count }
    end
  end

  def create_lifecycle(namespace_id)
    open_status = work_item_custom_statuses.create!(
      namespace_id: namespace_id,
      name: FFaker::Name.unique.name,
      category: 2,
      color: '#737278'
    )

    closed_status = work_item_custom_statuses.create!(
      namespace_id: namespace_id,
      name: FFaker::Name.unique.name,
      category: 4,
      color: '#108548'
    )

    duplicate_status = work_item_custom_statuses.create!(
      namespace_id: namespace_id,
      name: FFaker::Name.unique.name,
      category: 5,
      color: '#DD2B0E'
    )

    work_item_custom_lifecycles.create!(
      namespace_id: namespace_id,
      name: FFaker::Name.unique.name,
      default_open_status_id: open_status.id,
      default_closed_status_id: closed_status.id,
      default_duplicate_status_id: duplicate_status.id
    )
  end
end
