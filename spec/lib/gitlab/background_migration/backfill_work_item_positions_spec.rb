# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkItemPositions, feature_category: :team_planning do
  let(:organizations_table) { table(:organizations) }
  let(:issues_table) { table(:issues) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:work_item_positions_table) { table(:work_item_positions) }

  let(:work_item_type_id) { 1 }

  let!(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }
  let!(:group) do
    namespaces_table.create!(name: 'my test group1', path: 'my-test-group1', organization_id: organization.id)
  end

  let!(:project_namespace) { namespaces_table.create!(name: 'test', path: 'test', organization_id: organization.id) }
  let!(:project) do
    projects_table.create!(namespace_id: group.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: issues_table.minimum(:id),
      end_id: issues_table.maximum(:id),
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe '#perform' do
    context 'when there are issues with relative_position data' do
      let!(:issue_with_position) do
        issues_table.create!(
          title: 'Issue 1',
          project_id: project.id,
          namespace_id: project_namespace.id,
          work_item_type_id: work_item_type_id,
          relative_position: 100
        )
      end

      let!(:issue_with_nil_position) do
        issues_table.create!(
          title: 'Issue 2',
          project_id: project.id,
          namespace_id: project_namespace.id,
          work_item_type_id: work_item_type_id,
          relative_position: nil
        )
      end

      let!(:issue_without_position_record) do
        issues_table.create!(
          title: 'Issue 3',
          project_id: project.id,
          namespace_id: project_namespace.id,
          work_item_type_id: work_item_type_id,
          relative_position: 200
        )
      end

      before do
        work_item_positions_table.find_by!(work_item_id: issue_without_position_record.id).destroy!
      end

      it 'creates work_item_positions records for all issues' do
        expect { perform_migration }.to change { work_item_positions_table.count }.by(1)

        position = work_item_positions_table.find_by(work_item_id: issue_with_position.id)
        expect(position).to be_present
        expect(position.namespace_id).to eq(project_namespace.id)
        expect(position.relative_position).to eq(100)

        position = work_item_positions_table.find_by(work_item_id: issue_with_nil_position.id)
        expect(position).to be_present
        expect(position.namespace_id).to eq(project_namespace.id)
        expect(position.relative_position).to be_nil

        position = work_item_positions_table.find_by(work_item_id: issue_without_position_record.id)
        expect(position).to be_present
        expect(position.namespace_id).to eq(project_namespace.id)
        expect(position.relative_position).to eq(200)
      end

      it 'skips updates on conflict' do
        work_item_positions_table.find_by(work_item_id: issue_with_position.id)
          .update!(relative_position: 999)

        expect { perform_migration }.to change { work_item_positions_table.count }.by(1)
          .and not_change {
            work_item_positions_table.find_by(work_item_id: issue_with_position.id).relative_position
          }
      end

      it 'is idempotent' do
        perform_migration

        expect do
          described_class.new(
            start_id: issues_table.minimum(:id),
            end_id: issues_table.maximum(:id),
            batch_table: :issues,
            batch_column: :id,
            sub_batch_size: 2,
            pause_ms: 0,
            connection: ActiveRecord::Base.connection
          ).perform
        end.to not_change { work_item_positions_table.count }
      end
    end
  end
end
