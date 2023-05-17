# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportBaseDataWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:import_state) { create(:import_state, project: project) }

  let(:worker) { described_class.new }
  let(:importer) { double(:importer) }
  let(:client) { double(:client) }

  describe '#import' do
    it 'imports the base data of a project' do
      described_class::IMPORTERS.each do |klass|
        expect(klass)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer).to receive(:execute)
      end

      expect(import_state).to receive(:refresh_jid_expiration)

      expect(Gitlab::GithubImport::Stage::ImportPullRequestsWorker)
        .to receive(:perform_async)
        .with(project.id)

      worker.import(client, project)
    end

    it 'raises an error' do
      exception = StandardError.new('_some_error_')

      expect_next_instance_of(Gitlab::GithubImport::Importer::LabelsImporter) do |importer|
        expect(importer).to receive(:execute).and_raise(exception)
      end
      expect(Gitlab::Import::ImportFailureService).to receive(:track)
                                                        .with(
                                                          project_id: project.id,
                                                          exception: exception,
                                                          error_source: described_class.name,
                                                          fail_import: true,
                                                          metrics: true
                                                        ).and_call_original

      expect { worker.import(client, project) }.to raise_error(StandardError)
    end
  end
end
