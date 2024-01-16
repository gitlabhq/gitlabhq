# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
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
  end
end
