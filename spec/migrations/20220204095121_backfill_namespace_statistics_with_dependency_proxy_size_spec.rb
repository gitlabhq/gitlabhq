# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNamespaceStatisticsWithDependencyProxySize, feature_category: :dependency_proxy do
  let!(:groups) { table(:namespaces) }
  let!(:group1) { groups.create!(id: 10, name: 'test1', path: 'test1', type: 'Group') }
  let!(:group2) { groups.create!(id: 20, name: 'test2', path: 'test2', type: 'Group') }
  let!(:group3) { groups.create!(id: 30, name: 'test3', path: 'test3', type: 'Group') }
  let!(:group4) { groups.create!(id: 40, name: 'test4', path: 'test4', type: 'Group') }

  let!(:dependency_proxy_blobs) { table(:dependency_proxy_blobs) }
  let!(:dependency_proxy_manifests) { table(:dependency_proxy_manifests) }

  let!(:group1_manifest) { create_manifest(10, 10) }
  let!(:group2_manifest) { create_manifest(20, 20) }
  let!(:group3_manifest) { create_manifest(30, 30) }

  let!(:group1_blob) { create_blob(10, 10) }
  let!(:group2_blob) { create_blob(20, 20) }
  let!(:group3_blob) { create_blob(30, 30) }

  describe '#up' do
    it 'correctly schedules background migrations' do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          aggregate_failures do
            expect(described_class::MIGRATION)
              .to be_scheduled_migration([10, 30], ['dependency_proxy_size'])

            expect(described_class::MIGRATION)
              .to be_scheduled_delayed_migration(2.minutes, [20], ['dependency_proxy_size'])

            expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          end
        end
      end
    end
  end

  def create_manifest(group_id, size)
    dependency_proxy_manifests.create!(
      group_id: group_id,
      size: size,
      file_name: 'test-file',
      file: 'test',
      digest: 'abc123'
    )
  end

  def create_blob(group_id, size)
    dependency_proxy_blobs.create!(
      group_id: group_id,
      size: size,
      file_name: 'test-file',
      file: 'test'
    )
  end
end
