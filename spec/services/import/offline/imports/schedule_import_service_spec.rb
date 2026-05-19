# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::ScheduleImportService, :aggregate_failures, feature_category: :importers do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:destination_group) { create(:group, owners: user) }
    let(:bulk_import) { create(:bulk_import, :with_offline_configuration, user: user) }
    let(:fake_metadata) do
      {
        instance_version: "19.0.0",
        instance_enterprise: true,
        export_prefix: "export_2025-09-18_1hrwkrv",
        source_hostname: "https://offline-environment-gitlab.example.com",
        batched: true,
        entities_mapping:
          {
            "top_level_group" => "group_1",
            "top_level_group/group" => "group_2",
            "top_level_group/group/first_project" => "project_1",
            "top_level_group/group/second_project" => "project_2",
            "top_level_group/another_group" => "group_3"
          }
      }
    end

    let(:object_storage_configuration) { build(:import_offline_configuration) }

    let(:entities) do
      [
        {
          "source_type" => 'group_entity',
          "source_full_path" => 'top_level_group',
          "destination_namespace" => destination_group.full_path,
          "destination_slug" => 'dest-grp-0123'
        }
      ]
    end

    subject(:service) do
      described_class.new(
        bulk_import,
        entities
      )
    end

    before do
      stub_offline_import_object_storage(object_storage_configuration)

      allow_next_instance_of(Import::Offline::Imports::MetadataFileReader) do |reader|
        allow(reader).to receive(:read).and_return(fake_metadata)
      end
    end

    it 'returns a success result' do
      expect(service.execute).to be_success
    end

    it 'enqueues BulkImportWorker' do
      expect(BulkImportWorker).to receive(:perform_async).with(bulk_import.id)

      service.execute
    end

    it 'enables importer user mapping' do
      expect_next_instance_of(::Import::BulkImports::EphemeralData, bulk_import.id) do |ephemeral_data|
        expect(ephemeral_data).to receive(:enable_importer_user_mapping)
      end

      service.execute
    end

    context 'when the metadata file raises UnsupportedVersionError' do
      before do
        allow_next_instance_of(Import::Offline::Imports::MetadataFileReader) do |reader|
          allow(reader).to receive(:read).and_raise(
            Import::Offline::Imports::MetadataFileReader::UnsupportedVersionError, 'Invalid source version'
          )
        end
      end

      it 'returns an error result and fails the import' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Invalid source version')
        expect(bulk_import.reload.failed?).to be(true)
      end
    end

    context 'when the entity path has no mapping in metadata' do
      let(:entities) do
        [{ "source_type" => 'group_entity', "source_full_path" => 'unmapped_group',
           "destination_namespace" => destination_group.full_path, "destination_slug" => 'dest' }]
      end

      it 'returns an error result and fails the import' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to match(/no mapping for entity path 'unmapped_group'/)
        expect(bulk_import.reload.failed?).to be(true)
      end
    end

    context 'when the metadata file cannot be parsed' do
      before do
        allow_next_instance_of(Import::Offline::Imports::MetadataFileReader) do |reader|
          allow(reader).to receive(:read).and_raise(
            Import::Offline::Imports::MetadataFileReader::MetadataParseError, 'Failed to parse metadata'
          )
        end
      end

      it 'returns an error result and fails the import' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Failed to parse metadata')
        expect(bulk_import.reload.failed?).to be(true)
      end
    end

    it 'updates the bulk import record' do
      expect { service.execute }
        .to change { bulk_import.reload.source_version }.to("19.0.0")
        .and change { bulk_import.reload.source_enterprise }.to(true)
    end

    it 'updates the offline configuration with the entity prefix mapping' do
      expect { service.execute }
        .to change { bulk_import.offline_configuration.reload.entity_prefix_mapping }
        .to(fake_metadata[:entities_mapping].stringify_keys)
    end

    it 'creates a bulk import entity for the group' do
      expect { service.execute }
        .to change { BulkImports::Entity.count }.by(1)

      expect(BulkImports::Entity.last).to have_attributes(
        source_type: "group_entity",
        source_full_path: "top_level_group",
        destination_name: "dest-grp-0123",
        destination_namespace: destination_group.full_path
      )
    end

    it 'is safe to retry - clears existing entities before creating new ones' do
      described_class.new(bulk_import.reload, entities).execute
      expect { described_class.new(bulk_import.reload, entities).execute }.not_to change { BulkImports::Entity.count }
      expect(BulkImports::Entity.count).to eq(1)
    end

    it 'tracks the user role' do
      service.execute

      expect_snowplow_event(
        category: 'Import::Offline::Imports::ScheduleImportService',
        action: 'create',
        label: 'import_access_level',
        user: user,
        extra: { user_role: 'Owner', import_type: 'offline_import_group' }
      )
    end
  end
end
