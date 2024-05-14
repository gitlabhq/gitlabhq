# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::CollaboratorsImporter, feature_category: :importers do
  subject(:importer) { described_class.new(project, client, parallel: parallel) }

  let(:parallel) { true }
  let(:project) { build(:project, id: 4, import_source: 'foo/bar', import_state: nil) }
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

    it 'raises an error while importing collaborators' do
      allow(importer)
        .to receive(:each_object_to_import)
        .and_raise(StandardError, 'An error occurred during yield')
      expect { importer.sequential_import }.to raise_error(StandardError, 'An error occurred during yield')
    end
  end

  describe '#parallel_import', :clean_gitlab_redis_shared_state do
    before do
      allow(client).to receive(:collaborators).with(project.import_source, affiliation: 'direct')
        .and_return([github_collaborator])
      allow(client).to receive(:collaborators).with(project.import_source, affiliation: 'outside')
        .and_return([])
    end

    it 'imports each collaborator in parallel' do
      expect(Gitlab::GithubImport::ImportCollaboratorWorker).to receive(:perform_in)
        .with(an_instance_of(Float), project.id, an_instance_of(Hash), an_instance_of(String))

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

  describe '#each_object_to_import', :clean_gitlab_redis_shared_state do
    let(:github_collaborator_2) { { id: 100501, login: 'alice', role_name: 'owner' } }
    let(:github_collaborator_3) { { id: 100502, login: 'tom', role_name: 'guest' } }

    before do
      allow(client).to receive(:collaborators).with(project.import_source, affiliation: 'direct')
        .and_return([github_collaborator, github_collaborator_2, github_collaborator_3])
      allow(client).to receive(:collaborators).with(project.import_source, affiliation: 'outside')
        .and_return([github_collaborator_3])
      allow(Gitlab::GithubImport::ObjectCounter).to receive(:increment)
        .with(project, :collaborator, :fetched)
    end

    it 'yields every direct collaborator who is not an outside collaborator to the supplied block' do
      expect { |b| importer.each_object_to_import(&b) }
        .to yield_successive_args(github_collaborator, github_collaborator_2)

      expect(Gitlab::GithubImport::ObjectCounter).to have_received(:increment).twice
    end

    context 'when one of the collaborator raises exception while importing' do
      before do
        allow(github_collaborator_3).to receive(:each_object_to_import)
        .and_raise(StandardError, 'Error importing collaborator')
        allow(client).to receive(:collaborators).with(project.import_source, affiliation: 'direct')
        .and_return([github_collaborator, github_collaborator_3])
        allow(Gitlab::GithubImport::ObjectCounter).to receive(:increment)
        .with(project, :collaborator, :fetched)
      end

      it 'yields only one direct collaborator' do
        expect { |b| importer.each_object_to_import(&b) }
          .to yield_successive_args(github_collaborator)

        expect(Gitlab::GithubImport::ObjectCounter).to have_received(:increment).once
      end
    end

    context 'when a collaborator has been already imported' do
      before do
        allow(importer).to receive(:already_imported?).and_return(true)
      end

      it 'does not yield anything' do
        expect(Gitlab::GithubImport::ObjectCounter)
          .not_to receive(:increment)

        expect(importer)
          .not_to receive(:mark_as_imported)

        expect { |b| importer.each_object_to_import(&b) }
          .not_to yield_control
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
