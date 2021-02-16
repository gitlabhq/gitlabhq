# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectUpdatedAtAfterRepositoryStorageMove, :migration, schema: 20210210093901 do
  let(:projects) { table(:projects) }
  let(:project_repository_storage_moves) { table(:project_repository_storage_moves) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }

  subject { described_class.new }

  describe '#perform' do
    it 'updates project updated_at column if they were moved to a different repository storage' do
      freeze_time do
        project_1 = projects.create!(id: 1, namespace_id: namespace.id, updated_at: 1.day.ago)
        project_2 = projects.create!(id: 2, namespace_id: namespace.id, updated_at: Time.current)
        original_project_3_updated_at = 2.minutes.from_now
        project_3 = projects.create!(id: 3, namespace_id: namespace.id, updated_at: original_project_3_updated_at)
        original_project_4_updated_at = 10.days.ago
        project_4 = projects.create!(id: 4, namespace_id: namespace.id, updated_at: original_project_4_updated_at)

        repository_storage_move_1 = project_repository_storage_moves.create!(project_id: project_1.id, updated_at: 2.hours.ago, source_storage_name: 'default', destination_storage_name: 'default')
        repository_storage_move_2 = project_repository_storage_moves.create!(project_id: project_2.id, updated_at: Time.current, source_storage_name: 'default', destination_storage_name: 'default')
        project_repository_storage_moves.create!(project_id: project_3.id, updated_at: Time.current, source_storage_name: 'default', destination_storage_name: 'default')

        subject.perform([1, 2, 3, 4, non_existing_record_id])

        expect(project_1.reload.updated_at).to eq(repository_storage_move_1.updated_at + 1.second)
        expect(project_2.reload.updated_at).to eq(repository_storage_move_2.updated_at + 1.second)
        expect(project_3.reload.updated_at).to eq(original_project_3_updated_at)
        expect(project_4.reload.updated_at).to eq(original_project_4_updated_at)
      end
    end
  end
end
