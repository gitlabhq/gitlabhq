# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::IssuesImporter do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#sequential_import', :clean_gitlab_redis_cache do
    let_it_be(:issue_1) { create(:issue, project: project) }
    let_it_be(:issue_2) { create(:issue, project: project) }

    let(:importer_stub) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }
    let(:importer_attrs) { [instance_of(Gitlab::GithubImport::Representation::NoteText), project, client] }

    it 'imports each project issue attachments' do
      expect(project.issues).to receive(:select).with(:id, :description, :iid).and_call_original

      expect_next_instances_of(
        Gitlab::GithubImport::Importer::NoteAttachmentsImporter, 2, false, *importer_attrs
      ) do |note_attachments_importer|
        expect(note_attachments_importer).to receive(:execute)
      end

      importer.sequential_import
    end

    context 'when issue is already processed' do
      it "doesn't import this issue attachments" do
        importer.mark_as_imported(issue_1)

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
