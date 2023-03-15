# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

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
      context 'with issues' do
        it 'schedules the importing of the base data' do
          client = double(:client)
          options = { state: 'all', sort: 'number', direction: 'desc', per_page: '1' }

          expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
            expect(instance).to receive(:execute).and_return(true)
          end

          expect(InternalId).to receive(:exists?).and_return(false)
          expect(client).to receive(:each_object).with(
            :issues, project.import_source, options
          ).and_return([{ number: 5 }].each)

          expect(Issue).to receive(:track_namespace_iid!).with(project.project_namespace, 5)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end

      context 'without issues' do
        it 'schedules the importing of the base data' do
          client = double(:client)
          options = { state: 'all', sort: 'number', direction: 'desc', per_page: '1' }

          expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
            expect(instance).to receive(:execute).and_return(true)
          end

          expect(InternalId).to receive(:exists?).and_return(false)
          expect(client).to receive(:each_object).with(:issues, project.import_source, options).and_return([nil].each)
          expect(Issue).not_to receive(:track_namespace_iid!)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end

      context 'when retrying' do
        it 'does not allocate internal ids' do
          client = double(:client)

          expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
            expect(instance).to receive(:execute).and_return(true)
          end

          expect(InternalId).to receive(:exists?).and_return(true)
          expect(client).not_to receive(:each_object)
          expect(Issue).not_to receive(:track_namespace_iid!)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end
    end

    context 'when the import fails' do
      it 'does not schedule the importing of the base data' do
        client = double(:client)
        exception_class = Gitlab::Git::Repository::NoRepository

        expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
          expect(instance).to receive(:execute).and_raise(exception_class)
        end

        expect(InternalId).to receive(:exists?).and_return(false)
        expect(client).to receive(:each_object).and_return([nil].each)
        expect(Issue).not_to receive(:track_namespace_iid!)

        expect(Gitlab::Import::ImportFailureService).to receive(:track)
                                                          .with(
                                                            project_id: project.id,
                                                            exception: exception_class,
                                                            error_source: described_class.name,
                                                            fail_import: true,
                                                            metrics: true
                                                          ).and_call_original

        expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
          .not_to receive(:perform_async)

        expect(worker.abort_on_failure).to eq(true)

        expect { worker.import(client, project) }
          .to raise_error(exception_class)
      end
    end
  end
end
