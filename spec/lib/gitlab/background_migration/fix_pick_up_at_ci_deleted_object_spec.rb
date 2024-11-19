# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixPickUpAtCiDeletedObject, schema: 20241004064933, migration: :gitlab_ci, feature_category: :job_artifacts do
  let(:deleted_objects) { table(:ci_deleted_objects, database: :ci) }
  let(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { deleted_objects.connection }

  let!(:deleted_object1) do
    deleted_objects.create!(pick_up_at: Time.current, store_dir: "dir", file: "file")
  end

  let!(:deleted_object2) do
    deleted_objects.create!(pick_up_at: 16.minutes.from_now, store_dir: "dir", file: "file")
  end

  let!(:deleted_object3) do
    deleted_objects.create!(pick_up_at: 1.year.from_now, store_dir: "dir", file: "file")
  end

  let!(:deleted_object4) do
    deleted_objects.create!(pick_up_at: 2.years.from_now, store_dir: "dir", file: "file")
  end

  let(:migration_attrs) do
    {
      start_id: deleted_objects.minimum(:id),
      end_id: deleted_objects.maximum(:id),
      batch_table: :ci_deleted_objects,
      batch_column: :id,
      sub_batch_size: 4,
      pause_ms: 0,
      connection: connection
    }
  end

  around do |example|
    freeze_time { example.run }
  end

  describe '#perform' do
    context 'when there are invalid records' do
      it 'resets pick_up_at values', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/500119' do
        expect { migration.perform }
          .to not_change { deleted_object1.reload.pick_up_at }
          .and not_change { deleted_object2.reload.pick_up_at }

        expect(deleted_object3.reload.pick_up_at).to be_within(10.seconds).of(1.hour.from_now)
        expect(deleted_object4.reload.pick_up_at).to be_within(10.seconds).of(1.hour.from_now)
      end
    end
  end
end
