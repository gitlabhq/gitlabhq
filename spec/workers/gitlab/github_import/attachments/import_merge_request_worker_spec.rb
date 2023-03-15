# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Attachments::ImportMergeRequestWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#import' do
    let(:import_state) { create(:import_state, :started) }

    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:client) { instance_double('Gitlab::GithubImport::Client') }

    it 'imports an merge request attachments' do
      expect_next_instance_of(
        Gitlab::GithubImport::Importer::NoteAttachmentsImporter,
        an_instance_of(Gitlab::GithubImport::Representation::NoteText),
        project,
        client
      ) do |note_attachments_importer|
        expect(note_attachments_importer).to receive(:execute)
      end

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(project, client, {})
    end
  end
end
