# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTagNameOnDastProfilesTags,
  feature_category: :dynamic_application_security_testing do
  let(:dast_scanner_profiles_table) { table(:dast_scanner_profiles, database: :sec) }
  let(:dast_sites_table) { table(:dast_sites, database: :sec) }
  let(:dast_site_profiles_table) { table(:dast_site_profiles, database: :sec) }
  let(:dast_profiles_table) { table(:dast_profiles, database: :sec) }
  let(:dast_profiles_tags_table) { table(:dast_profiles_tags, database: :sec, primary_key: :id) }
  let(:tags_table) { table(:tags, database: :ci, primary_key: :id) }

  let!(:scanner_profile) do
    dast_scanner_profiles_table.create!(project_id: 1, name: 'test_scanner', created_at: Time.current,
      updated_at: Time.current)
  end

  let!(:dast_site) do
    dast_sites_table.create!(project_id: 1, url: 'https://example.com', created_at: Time.current,
      updated_at: Time.current)
  end

  let!(:site_profile) do
    dast_site_profiles_table.create!(project_id: 1, dast_site_id: dast_site.id, name: 'test_site',
      created_at: Time.current, updated_at: Time.current)
  end

  let!(:dast_profile) do
    dast_profiles_table.create!(project_id: 1, dast_site_profile_id: site_profile.id,
      dast_scanner_profile_id: scanner_profile.id, name: 'test_profile', description: 'test',
      created_at: Time.current, updated_at: Time.current)
  end

  let!(:tag1) { tags_table.create!(name: 'ruby') }
  let!(:tag2) { tags_table.create!(name: 'python') }
  let!(:tag3) { tags_table.create!(name: 'docker') }

  let(:tagging_with_null_name) do
    dast_profiles_tags_table.create!(dast_profile_id: dast_profile.id, tag_id: tag1.id, project_id: 1,
      tag_name: nil)
  end

  let!(:tagging_with_existing_name) do
    dast_profiles_tags_table.create!(dast_profile_id: dast_profile.id, tag_id: tag2.id, project_id: 1,
      tag_name: 'existing-name')
  end

  let(:another_tagging_with_null_name) do
    dast_profiles_tags_table.create!(dast_profile_id: dast_profile.id, tag_id: tag3.id, project_id: 1,
      tag_name: nil)
  end

  let(:migration_args) do
    {
      start_id: dast_profiles_tags_table.minimum(:id),
      end_id: dast_profiles_tags_table.maximum(:id),
      batch_table: :dast_profiles_tags,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ::SecApplicationRecord.connection
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
          dast_profiles_tags_table.create!(dast_profile_id: dast_profile.id, tag_id: tag2.id, project_id: 1,
            tag_name: nil)
        end
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { tagging_with_null_name.reload.tag_name }.from(nil).to('ruby')
          .and not_change { outside_batch_tagging.reload.tag_name }.from(nil)
      end
    end

    context 'when all records in the sub_batch already have tag_name set' do
      let(:migration_args) do
        super().merge(
          start_id: tagging_with_existing_name.id,
          end_id: tagging_with_existing_name.id
        )
      end

      it 'does not modify any tag_name values' do
        expect { perform_migration }.not_to change { tagging_with_existing_name.reload.tag_name }.from('existing-name')
      end
    end

    context 'when tag is missing' do
      let!(:tagging_with_missing_tag) do
        without_check_constraint do
          dast_profiles_tags_table.create!(dast_profile_id: dast_profile.id, tag_id: non_existing_record_id,
            project_id: 1, tag_name: nil)
        end
      end

      it 'does not update records with missing tags' do
        expect { perform_migration }.not_to change { tagging_with_missing_tag.reload.tag_name }.from(nil)
      end
    end
  end

  private

  def without_check_constraint
    conn = ::SecApplicationRecord.connection
    conn.execute('ALTER TABLE dast_profiles_tags DROP CONSTRAINT IF EXISTS check_tag_name_not_null')

    yield.tap do
      conn.execute <<~SQL
        ALTER TABLE dast_profiles_tags
          ADD CONSTRAINT check_tag_name_not_null CHECK ((tag_name IS NOT NULL)) NOT VALID
      SQL
    end
  end
end
