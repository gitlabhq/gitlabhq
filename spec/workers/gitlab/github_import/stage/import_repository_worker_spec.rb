# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportRepositoryWorker do
  let(:project) { double(:project, id: 4) }
  let(:worker) { described_class.new }

  describe '#import' do
    before do
      expect(Gitlab::GithubImport::RefreshImportJidWorker)
        .to receive(:perform_in_the_future)
        .with(project.id, '123')

      expect(worker)
        .to receive(:jid)
        .and_return('123')
    end

    context 'when the import succeeds' do
      it 'schedules the importing of the base data' do
        client = double(:client)

        expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
          expect(instance).to receive(:execute).and_return(true)
        end

        expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
          .to receive(:perform_async)
          .with(project.id)

        worker.import(client, project)
      end
    end

    context 'when the import fails' do
      it 'does not schedule the importing of the base data' do
        client = double(:client)

        expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
          expect(instance).to receive(:execute).and_return(false)
        end

        expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
          .not_to receive(:perform_async)

        worker.import(client, project)
      end
    end
  end
end
