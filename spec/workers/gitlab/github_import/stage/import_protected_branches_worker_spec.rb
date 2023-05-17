# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportProtectedBranchesWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:import_state) { create(:import_state, project: project) }

  let(:worker) { described_class.new }
  let(:importer) { instance_double('Gitlab::GithubImport::Importer::ProtectedBranchImporter') }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  describe '#import' do
    it 'imports all the pull requests' do
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::ProtectedBranchesImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer)
        .to receive(:execute)
        .and_return(waiter)

      expect(import_state)
        .to receive(:refresh_jid_expiration)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :lfs_objects)

      worker.import(client, project)
    end

    context 'when an error raised' do
      let(:exception) { StandardError.new('_some_error_') }

      before do
        allow_next_instance_of(Gitlab::GithubImport::Importer::ProtectedBranchesImporter) do |importer|
          allow(importer).to receive(:execute).and_raise(exception)
        end
      end

      it 'raises an error' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track)
          .with(
            project_id: project.id,
            exception: exception,
            error_source: described_class.name,
            metrics: true
          ).and_call_original

        expect { worker.import(client, project) }.to raise_error(StandardError)
      end
    end
  end
end
