# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::MergeRequestsImporter do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#sequential_import', :clean_gitlab_redis_cache do
    let_it_be(:merge_request_1) { create(:merge_request, source_project: project, target_branch: 'feature1') }
    let_it_be(:merge_request_2) { create(:merge_request, source_project: project, target_branch: 'feature2') }

    let(:importer_stub) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }
    let(:importer_attrs) { [instance_of(Gitlab::GithubImport::Representation::NoteText), project, client] }

    it 'imports each project merge request attachments' do
      expect(project.merge_requests).to receive(:select).with(:id, :description, :iid).and_call_original

      expect_next_instances_of(
        Gitlab::GithubImport::Importer::NoteAttachmentsImporter, 2, false, *importer_attrs
      ) do |note_attachments_importer|
        expect(note_attachments_importer).to receive(:execute)
      end

      importer.sequential_import
    end

    context 'when merge request is already processed' do
      it "doesn't import this merge request attachments" do
        importer.mark_as_imported(merge_request_1)

        expect_next_instance_of(
          Gitlab::GithubImport::Importer::NoteAttachmentsImporter, *importer_attrs
        ) do |note_attachments_importer|
          expect(note_attachments_importer).to receive(:execute)
        end

        importer.sequential_import
      end
    end
  end

  describe '#sidekiq_worker_class' do
    it { expect(importer.sidekiq_worker_class).to eq(Gitlab::GithubImport::Attachments::ImportMergeRequestWorker) }
  end

  describe '#collection_method' do
    it { expect(importer.collection_method).to eq(:merge_request_attachments) }
  end

  describe '#object_type' do
    it { expect(importer.object_type).to eq(:merge_request_attachment) }
  end

  describe '#id_for_already_imported_cache' do
    let(:merge_request) { build_stubbed(:merge_request) }

    it { expect(importer.id_for_already_imported_cache(merge_request)).to eq(merge_request.id) }
  end
end
