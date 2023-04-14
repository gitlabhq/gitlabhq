# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Attachments::ImportIssueWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#import' do
    let(:import_state) { create(:import_state, :started) }

    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:client) { instance_double('Gitlab::GithubImport::Client') }

    let(:issue_hash) do
      {
        'record_db_id' => rand(100),
        'record_type' => 'Issue',
        'iid' => 2,
        'text' => <<-TEXT
          Some text...

          ![special-image](https://user-images.githubusercontent.com...)
        TEXT
      }
    end

    it 'imports an issue attachments' do
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

      worker.import(project, client, issue_hash)
    end
  end
end
