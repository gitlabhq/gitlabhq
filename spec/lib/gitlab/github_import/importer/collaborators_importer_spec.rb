# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::CollaboratorsImporter, feature_category: :importers do
  subject(:importer) { described_class.new(project, client, parallel: parallel) }

  let(:parallel) { true }
  let(:project) { instance_double(Project, id: 4, import_source: 'foo/bar', import_state: nil) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  let(:github_collaborator) do
    {
      id: 100500,
      login: 'bob',
      role_name: 'maintainer'
    }
  end

  describe '#parallel?' do
    context 'when parallel option is true' do
      it { expect(importer).to be_parallel }
    end

    context 'when parallel option is false' do
      let(:parallel) { false }

      it { expect(importer).not_to be_parallel }
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports collaborators in parallel' do
        expect(importer).to receive(:parallel_import)
        importer.execute
      end
    end

    context 'when running in sequential mode' do
      let(:parallel) { false }

      it 'imports collaborators in sequence' do
        expect(importer).to receive(:sequential_import)
        importer.execute
      end
    end
  end

  describe '#sequential_import' do
    let(:parallel) { false }

    it 'imports each collaborator in sequence' do
      collaborator_importer = instance_double(Gitlab::GithubImport::Importer::CollaboratorImporter)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(github_collaborator)

      expect(Gitlab::GithubImport::Importer::CollaboratorImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::Collaborator),
          project,
          client
        )
        .and_return(collaborator_importer)

      expect(collaborator_importer).to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import', :clean_gitlab_redis_cache do
    let(:page_struct) { Struct.new(:objects, :number, keyword_init: true) }

    before do
      allow(client).to receive(:each_page)
        .with(:collaborators, project.import_source, { page: 1 })
        .and_yield(page_struct.new(number: 1, objects: [github_collaborator]))
    end

    it 'imports each collaborator in parallel' do
      expect(Gitlab::GithubImport::ImportCollaboratorWorker).to receive(:perform_in)
        .with(1.second, project.id, an_instance_of(Hash), an_instance_of(String))

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end

    context 'when collaborator is already imported' do
      before do
        Gitlab::Cache::Import::Caching.set_add(
          "github-importer/already-imported/#{project.id}/collaborators",
          github_collaborator[:id]
        )
      end

      it "doesn't run importer on it" do
        expect(Gitlab::GithubImport::ImportCollaboratorWorker).not_to receive(:perform_in)

        waiter = importer.parallel_import

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(0)
      end
    end
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the ID of the given note' do
      expect(importer.id_for_already_imported_cache(github_collaborator))
        .to eq(100500)
    end
  end
end
