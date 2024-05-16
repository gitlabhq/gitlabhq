# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::IssuesImporter, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#sequential_import', :clean_gitlab_redis_shared_state do
    let_it_be(:issue) { create(:issue, project: project) }

    let_it_be(:issue_with_attachment) do
      create(:issue,
        project: project,
        description: "![image](https://user-images.githubusercontent.com/1/uuid-1.png)"
      )
    end

    it 'selects both issues, and selects only properties it needs' do
      stubbed_collection = class_double(Issue, each_batch: [])

      expect(project.issues).to receive(:id_not_in).with([]).and_return(stubbed_collection)
      expect(stubbed_collection).to receive(:select).with(:id, :description, :iid).and_return(stubbed_collection)

      importer.sequential_import
    end

    it 'executes importer only for the issue with an attachment' do
      expect_next_instance_of(
        Gitlab::GithubImport::Importer::NoteAttachmentsImporter,
        have_attributes(record_db_id: issue_with_attachment.id),
        project,
        client
      ) do |importer|
        expect(importer).to receive(:execute)
      end

      importer.sequential_import
    end

    context 'when issue has already been processed' do
      before do
        importer.mark_as_imported(issue_with_attachment)
      end

      it 'does not select issues that were processed' do
        expect(project.issues).to receive(:id_not_in).with([issue_with_attachment.id.to_s]).and_call_original

        importer.sequential_import
      end

      it 'does not execute importer for the issue with an attachment' do
        expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).not_to receive(:new)

        importer.sequential_import
      end
    end
  end

  describe '#sidekiq_worker_class' do
    it { expect(importer.sidekiq_worker_class).to eq(Gitlab::GithubImport::Attachments::ImportIssueWorker) }
  end

  describe '#collection_method' do
    it { expect(importer.collection_method).to eq(:issue_attachments) }
  end

  describe '#object_type' do
    it { expect(importer.object_type).to eq(:issue_attachment) }
  end

  describe '#id_for_already_imported_cache' do
    let(:issue) { build_stubbed(:issue) }

    it { expect(importer.id_for_already_imported_cache(issue)).to eq(issue.id) }
  end
end
