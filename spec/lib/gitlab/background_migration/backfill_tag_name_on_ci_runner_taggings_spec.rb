# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTagNameOnCiRunnerTaggings, feature_category: :runner_core do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:organizations_table) { table(:organizations, database: :main, primary_key: :id) }
  let(:namespaces_table) { table(:namespaces, database: :main, primary_key: :id) }
  let(:ci_runners_table) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:ci_runner_taggings_table) { table(:ci_runner_taggings, database: :ci, primary_key: :id) }
  let(:tags_table) { table(:tags, database: :ci, primary_key: :id) }

  let!(:organization) { organizations_table.create!(name: 'Test Org', path: 'test-org') }
  let!(:namespace) do
    namespaces_table.create!(name: 'Test Group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let!(:runner1) { ci_runners_table.create!(runner_type: 2, organization_id: organization.id) }
  let!(:runner2) { ci_runners_table.create!(runner_type: 2, organization_id: organization.id) }

  let!(:tag1) { tags_table.create!(name: 'ruby') }
  let!(:tag2) { tags_table.create!(name: 'python') }
  let!(:tag3) { tags_table.create!(name: 'docker') }

  let(:tagging_with_null_name) do
    ci_runner_taggings_table.create!(
      runner_id: runner1.id,
      runner_type: runner1.runner_type,
      tag_id: tag1.id,
      organization_id: organization.id,
      tag_name: nil
    )
  end

  let!(:tagging_with_existing_name) do
    ci_runner_taggings_table.create!(
      runner_id: runner1.id,
      runner_type: runner1.runner_type,
      tag_id: tag2.id,
      organization_id: organization.id,
      tag_name: 'existing-name'
    )
  end

  let!(:tagging_already_equal) do
    ci_runner_taggings_table.create!(
      runner_id: runner2.id,
      runner_type: runner2.runner_type,
      tag_id: tag1.id,
      organization_id: organization.id,
      tag_name: tag1.name
    )
  end

  let(:another_tagging_with_null_name) do
    ci_runner_taggings_table.create!(
      runner_id: runner1.id,
      runner_type: runner1.runner_type,
      tag_id: tag3.id,
      organization_id: organization.id,
      tag_name: nil
    )
  end

  let(:migration_args) do
    {
      start_id: ci_runner_taggings_table.minimum(:id),
      end_id: ci_runner_taggings_table.maximum(:id),
      batch_table: :ci_runner_taggings,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  before do
    without_check_constraint do
      tagging_with_null_name
      another_tagging_with_null_name
    end
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'backfills tag_name column for records with NULL name' do
      expect { perform_migration }
        .to change { tagging_with_null_name.reload.tag_name }.from(nil).to('ruby')
        .and change { another_tagging_with_null_name.reload.tag_name }.from(nil).to('docker')
        .and not_change { tagging_with_existing_name.reload.tag_name }.from('existing-name')
        .and not_change { tagging_already_equal.reload.tag_name }
    end

    context 'when records exist outside the batch range' do
      let(:migration_args) do
        super().merge(
          start_id: tagging_with_null_name.id,
          end_id: tagging_with_null_name.id
        )
      end

      let!(:outside_batch_tagging) do
        without_check_constraint do
          # Create a record outside the batch range
          ci_runner_taggings_table.create!(
            runner_id: runner2.id,
            runner_type: 2,
            tag_id: tag2.id,
            organization_id: organization.id,
            tag_name: nil
          )
        end
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { tagging_with_null_name.reload.tag_name }.from(nil).to('ruby')
          .and not_change { outside_batch_tagging.reload.tag_name }.from(nil)
      end
    end

    context 'when tag is missing' do
      let!(:tagging_with_missing_tag) do
        without_check_constraint do
          ci_runner_taggings_table.create!(
            runner_id: runner1.id,
            runner_type: 2,
            tag_id: non_existing_record_id, # non-existent tag
            organization_id: organization.id,
            tag_name: nil
          )
        end
      end

      it 'does not update records with missing tags' do
        expect { perform_migration }.not_to change { tagging_with_missing_tag.reload.tag_name }.from(nil)
      end
    end
  end

  private

  def without_check_constraint
    connection.execute('ALTER TABLE ci_runner_taggings DROP CONSTRAINT IF EXISTS check_tag_name_not_null')

    yield.tap do
      connection.execute <<~SQL
        ALTER TABLE ci_runner_taggings
          ADD CONSTRAINT check_tag_name_not_null CHECK ((tag_name IS NOT NULL)) NOT VALID
      SQL
    end
  end
end
