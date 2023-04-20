# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::ReleasesImporter do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#sequential_import', :clean_gitlab_redis_cache do
    let_it_be(:release_1) { create(:release, project: project) }
    let_it_be(:release_2) { create(:release, project: project) }

    let(:importer_stub) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }
    let(:importer_attrs) { [instance_of(Gitlab::GithubImport::Representation::NoteText), project, client] }

    it 'imports each project release' do
      expect(project.releases).to receive(:select).with(:id, :description, :tag).and_call_original

      expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).to receive(:new)
        .with(*importer_attrs).twice.and_return(importer_stub)
      expect(importer_stub).to receive(:execute).twice

      importer.sequential_import
    end

    context 'when note is already processed' do
      it "doesn't import this release" do
        importer.mark_as_imported(release_1)

        expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).to receive(:new)
          .with(*importer_attrs).once.and_return(importer_stub)
        expect(importer_stub).to receive(:execute).once

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
