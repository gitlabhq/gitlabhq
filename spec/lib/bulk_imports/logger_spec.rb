# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Logger, feature_category: :importers do
  describe '#with_entity' do
    subject(:logger) { described_class.new('/dev/null').with_entity(entity) }

    let(:entity) { build(:bulk_import_entity) }

    it 'records the entity information' do
      output = logger.format_message('INFO', Time.zone.now, 'test', 'Hello world')
      data = Gitlab::Json.parse(output)

      expect(data).to include(
        'bulk_import_id' => entity.bulk_import_id,
        'bulk_import_entity_id' => entity.id,
        'bulk_import_entity_type' => entity.source_type,
        'source_full_path' => entity.source_full_path,
        'source_version' => entity.bulk_import.source_version_info.to_s,
        Labkit::Fields::GL_ORGANIZATION_ID => entity.organization_id
      )
    end
  end

  describe 'importer tag' do
    subject(:importer) do
      output = logger.format_message('INFO', Time.zone.now, 'test', 'Hello world')
      Gitlab::Json.parse(output)['importer']
    end

    context 'without an entity' do
      let(:logger) { described_class.new('/dev/null') }

      it 'defaults to gitlab_migration' do
        expect(importer).to eq('gitlab_migration')
      end
    end

    context 'with a direct transfer entity' do
      let(:logger) { described_class.new('/dev/null').with_entity(entity) }
      let(:entity) { build(:bulk_import_entity, bulk_import: build(:bulk_import)) }

      it 'tags the entry as gitlab_migration' do
        expect(importer).to eq('gitlab_migration')
      end
    end

    context 'with an offline transfer entity' do
      let(:logger) { described_class.new('/dev/null').with_entity(entity) }
      let(:entity) { build(:bulk_import_entity, bulk_import: build(:bulk_import, :offline)) }

      it 'tags the entry as offline_transfer' do
        expect(importer).to eq('offline_transfer')
      end
    end

    context 'with a direct transfer bulk import' do
      let(:logger) { described_class.new('/dev/null').with_bulk_import(bulk_import) }
      let(:bulk_import) { build(:bulk_import) }

      it 'tags the entry as gitlab_migration' do
        expect(importer).to eq('gitlab_migration')
      end
    end

    context 'with an offline transfer bulk import' do
      let(:logger) { described_class.new('/dev/null').with_bulk_import(bulk_import) }
      let(:bulk_import) { build(:bulk_import, :offline) }

      it 'tags the entry as offline_transfer' do
        expect(importer).to eq('offline_transfer')
      end
    end

    context 'with both an entity and a bulk import' do
      let(:logger) { described_class.new('/dev/null').with_entity(entity).with_bulk_import(bulk_import) }
      let(:entity) { build(:bulk_import_entity, bulk_import: build(:bulk_import, :offline)) }
      let(:bulk_import) { build(:bulk_import) }

      it "prefers the entity's bulk import over the one set via with_bulk_import" do
        expect(importer).to eq('offline_transfer')
      end
    end
  end

  describe '#with_tracker' do
    subject(:logger) { described_class.new('/dev/null').with_tracker(tracker) }

    let_it_be(:tracker) { build(:bulk_import_tracker) }

    it 'records the tracker information' do
      output = logger.format_message('INFO', Time.zone.now, 'test', 'Hello world')
      data = Gitlab::Json.parse(output)

      expect(data).to include(
        'tracker_id' => tracker.id,
        'pipeline_class' => tracker.pipeline_name,
        'tracker_state' => tracker.human_status_name
      )
    end

    it 'also loads the entity data' do
      expect_next_instance_of(described_class) do |logger|
        expect(logger).to receive(:with_entity).once
      end

      logger
    end
  end
end
