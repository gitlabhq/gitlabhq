# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::ReleasesImporter, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#sequential_import', :clean_gitlab_redis_shared_state do
    let_it_be(:release) { create(:release, project: project) }

    let_it_be(:release_with_attachment) do
      create(:release,
        project: project,
        description: "![image](https://user-images.githubusercontent.com/1/uuid-1.png)"
      )
    end

    it 'selects both releases, and selects only properties it needs' do
      stubbed_collection = class_double(Release, each_batch: [])

      expect(project.releases).to receive(:id_not_in).with([]).and_return(stubbed_collection)
      expect(stubbed_collection).to receive(:select).with(:id, :description, :tag).and_return(stubbed_collection)

      importer.sequential_import
    end

    it 'executes importer only for the release with an attachment' do
      expect_next_instance_of(
        Gitlab::GithubImport::Importer::NoteAttachmentsImporter,
        have_attributes(record_db_id: release_with_attachment.id),
        project,
        client
      ) do |importer|
        expect(importer).to receive(:execute)
      end

      importer.sequential_import
    end

    context 'when release has already been processed' do
      before do
        importer.mark_as_imported(release_with_attachment)
      end

      it 'does not select releases that were processed' do
        expect(project.releases).to receive(:id_not_in).with([release_with_attachment.id.to_s]).and_call_original

        importer.sequential_import
      end

      it 'does not execute importer for the release with an attachment' do
        expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).not_to receive(:new)

        importer.sequential_import
      end
    end
  end

  describe '#sidekiq_worker_class' do
    it { expect(importer.sidekiq_worker_class).to eq(Gitlab::GithubImport::Attachments::ImportReleaseWorker) }
  end

  describe '#collection_method' do
    it { expect(importer.collection_method).to eq(:release_attachments) }
  end

  describe '#object_type' do
    it { expect(importer.object_type).to eq(:release_attachment) }
  end

  describe '#id_for_already_imported_cache' do
    let(:release) { build_stubbed(:release) }

    it { expect(importer.id_for_already_imported_cache(release)).to eq(release.id) }
  end
end
