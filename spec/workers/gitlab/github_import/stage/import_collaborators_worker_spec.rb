# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportCollaboratorsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:import_state) { create(:import_state, project: project) }
  let(:settings) { Gitlab::GithubImport::Settings.new(project) }
  let(:stage_enabled) { true }

  let(:worker) { described_class.new }
  let(:importer) { instance_double(Gitlab::GithubImport::Importer::CollaboratorsImporter) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#import' do
    let(:push_rights_granted) { true }

    before do
      settings.write({ collaborators_import: stage_enabled })
      allow(client).to receive(:repository).with(project.import_source)
        .and_return({ permissions: { push: push_rights_granted } })
    end

    context 'when user has push access for this repo' do
      it 'imports all collaborators' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)
        expect(importer).to receive(:execute).and_return(waiter)

        expect(import_state).to receive(:refresh_jid_expiration)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, :pull_requests_merged_by)

        worker.import(client, project)
      end
    end

    context 'when user do not have push access for this repo' do
      let(:push_rights_granted) { false }

      it 'skips stage' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, :pull_requests_merged_by)

        worker.import(client, project)
      end
    end

    context 'when stage is disabled' do
      let(:stage_enabled) { false }

      it 'skips collaborators import and calls next stage' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, :pull_requests_merged_by)

        worker.import(client, project)
      end
    end

    it 'raises an error' do
      exception = StandardError.new('_some_error_')

      expect_next_instance_of(Gitlab::GithubImport::Importer::CollaboratorsImporter) do |importer|
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
