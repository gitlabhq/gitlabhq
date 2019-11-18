# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Importer::LfsObjectsImporter do
  let(:project) { double(:project, id: 4, import_source: 'foo/bar') }
  let(:client) { double(:client) }
  let(:download_link) { "http://www.gitlab.com/lfs_objects/oid" }

  let(:lfs_attributes) do
    {
      oid: 'oid',
      size: 1,
      link: 'http://www.gitlab.com/lfs_objects/oid'
    }
  end

  let(:lfs_download_object) { LfsDownloadObject.new(lfs_attributes) }

  describe '#parallel?' do
    it 'returns true when running in parallel mode' do
      importer = described_class.new(project, client)
      expect(importer).to be_parallel
    end

    it 'returns false when running in sequential mode' do
      importer = described_class.new(project, client, parallel: false)
      expect(importer).not_to be_parallel
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports lfs objects in parallel' do
        importer = described_class.new(project, client)

        expect(importer).to receive(:parallel_import)

        importer.execute
      end
    end

    context 'when running in sequential mode' do
      it 'imports lfs objects in sequence' do
        importer = described_class.new(project, client, parallel: false)

        expect(importer).to receive(:sequential_import)

        importer.execute
      end
    end
  end

  describe '#sequential_import' do
    it 'imports each lfs object in sequence' do
      importer = described_class.new(project, client, parallel: false)
      lfs_object_importer = double(:lfs_object_importer)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(lfs_download_object)

      expect(Gitlab::GithubImport::Importer::LfsObjectImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::LfsObject),
          project,
          client
        )
        .and_return(lfs_object_importer)

      expect(lfs_object_importer).to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import' do
    it 'imports each lfs object in parallel' do
      importer = described_class.new(project, client)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(lfs_download_object)

      expect(Gitlab::GithubImport::ImportLfsObjectWorker)
        .to receive(:perform_async)
        .with(project.id, an_instance_of(Hash), an_instance_of(String))

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end
  end

  describe '#collection_options' do
    it 'returns an empty Hash' do
      importer = described_class.new(project, client)

      expect(importer.collection_options).to eq({})
    end
  end
end
