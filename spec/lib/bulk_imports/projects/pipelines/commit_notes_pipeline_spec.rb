# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::CommitNotesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'destination-project',
      destination_namespace: group.full_path
    )
  end

  let(:ci_pipeline_note) do
    {
      "note" => "Commit note 1",
      "noteable_type" => "Commit",
      "author_id" => 101,
      "created_at" => "2023-01-30T19:27:36.585Z",
      "updated_at" => "2023-02-10T14:43:01.308Z",
      "project_id" => 1,
      "commit_id" => "sha-notes",
      "system" => false,
      "updated_by_id" => 101,
      "discussion_id" => "e3fde7d585c6467a7a5147e83617eb6daa61aaf4",
      "last_edited_at" => "2023-02-10T14:43:01.306Z",
      "author" => {
        "name" => "Administrator"
      },
      "events" => [
        {
          "project_id" => 1,
          "author_id" => 101,
          "action" => "commented",
          "target_type" => "Note"
        }
      ]
    }
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:importer_user_mapping_enabled) { false }

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: [ci_pipeline_note])
        )
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      allow(context).to receive(:importer_user_mapping_enabled?).and_return(importer_user_mapping_enabled)
      allow(Import::PlaceholderReferences::PushService).to receive(:from_record).and_call_original
    end

    it 'imports ci pipeline notes into destination project' do
      expect { pipeline.run }.to change { project.notes.for_commit_id("sha-notes").count }.by(1)
    end

    context 'when importer_user_mapping is enabled' do
      let(:importer_user_mapping_enabled) { true }

      let_it_be(:source_user) do
        create(:import_source_user,
          import_type: ::Import::SOURCE_DIRECT_TRANSFER,
          namespace: group,
          source_user_identifier: 101,
          source_hostname: bulk_import.configuration.url
        )
      end

      it 'imports merge_requests and maps user references to placeholder users', :aggregate_failures do
        pipeline.run

        note = project.notes.for_commit_id("sha-notes").first
        event = note.events.first

        expect(note.author).to be_placeholder
        expect(note.updated_by).to be_placeholder
        expect(event.author).to be_placeholder

        source_user = Import::SourceUser.find_by(source_user_identifier: 101)
        expect(source_user.placeholder_user).to be_placeholder
        expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).exactly(3).times
      end
    end
  end
end
