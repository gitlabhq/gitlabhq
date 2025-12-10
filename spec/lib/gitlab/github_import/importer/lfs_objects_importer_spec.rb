# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::LfsObjectsImporter, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  let(:client) { double(:client) }
  let(:download_link) { "http://www.gitlab.com/lfs_objects/oid" }

  let(:lfs_attributes) do
    {
      oid: 'a' * 64,
      size: 1,
      link: 'http://www.gitlab.com/lfs_objects/oid'
    }
  end

  let(:lfs_download_object) { LfsDownloadObject.new(**lfs_attributes) }

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

    context 'when LFS list download fails' do
      it 'rescues and logs the known exceptions' do
        exception = StandardError.new('Invalid Project URL')
        importer = described_class.new(project, client, parallel: false)

        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
          expect(service)
            .to receive(:each_list_item)
            .and_raise(exception)
        end

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track)
          .with(
            project_id: project.id,
            exception: exception,
            error_source: 'Gitlab::GithubImport::Importer::LfsObjectImporter'
          ).and_call_original

        importer.execute
      end

      it 'raises RateLimitError when rate limit is exceeded' do
        exception = Projects::LfsPointers::LfsObjectDownloadListService::LfsObjectDownloadListError.new(
          'Unable to download due to TooManyRequests error'
        )
        importer = described_class.new(project, client, parallel: false)

        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
          expect(service)
            .to receive(:each_list_item)
            .and_raise(exception)
        end

        expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError) do |error|
          expect(error.message).to eq('Rate Limit exceeded')
          expect(error.reset_in).to eq(120)
        end
      end

      it 're-raises LfsObjectDownloadListError when not a rate limit error' do
        exception = Projects::LfsPointers::LfsObjectDownloadListService::LfsObjectDownloadListError.new(
          'Some other download error'
        )
        importer = described_class.new(project, client, parallel: false)

        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
          expect(service)
            .to receive(:each_list_item)
            .and_raise(exception)
        end

        expect { importer.execute }.to raise_error(exception)
      end

      it 'raises and logs the unknown exceptions' do
        exception = Exception.new('Really bad news')
        importer = described_class.new(project, client, parallel: false)

        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
          expect(service)
            .to receive(:each_list_item)
            .and_raise(exception)
        end

        expect { importer.execute }.to raise_error(exception)
      end
    end
  end

  describe '#sequential_import' do
    it 'imports each lfs object in sequence' do
      importer = described_class.new(project, client, parallel: false)
      lfs_object_importer = double(:lfs_object_importer)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(importer).to receive(:already_imported?).with(lfs_download_object).and_return(false)
      expect(importer).to receive(:mark_as_imported).with(lfs_download_object)

      expect(Gitlab::GithubImport::Importer::LfsObjectImporter)
        .to receive(:new).with(
          an_instance_of(Gitlab::GithubImport::Representation::LfsObject),
          project,
          client
        ).and_return(lfs_object_importer)

      expect(lfs_object_importer).to receive(:execute)

      importer.sequential_import
    end

    it 'skips already imported lfs objects' do
      importer = described_class.new(project, client, parallel: false)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(importer).to receive(:already_imported?).with(lfs_download_object).and_return(true)
      expect(importer).not_to receive(:mark_as_imported)
      expect(Gitlab::GithubImport::Importer::LfsObjectImporter).not_to receive(:new)

      importer.sequential_import
    end
  end

  describe '#sequential_import', :clean_gitlab_redis_shared_state do
    it 'marks objects as imported in cache' do
      importer = described_class.new(project, client, parallel: false)
      lfs_object_importer = double(:lfs_object_importer, execute: true)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      allow(Gitlab::GithubImport::Importer::LfsObjectImporter).to receive(:new).and_return(lfs_object_importer)

      expect { importer.sequential_import }
        .to change { importer.already_imported?(lfs_download_object) }
        .from(false).to(true)
    end

    it 'does not import already imported objects' do
      importer = described_class.new(project, client, parallel: false)
      importer.mark_as_imported(lfs_download_object)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(Gitlab::GithubImport::Importer::LfsObjectImporter).not_to receive(:new)
      expect(Gitlab::GithubImport::ObjectCounter).not_to receive(:increment)

      importer.sequential_import
    end
  end

  describe '#parallel_import', :clean_gitlab_redis_shared_state do
    it 'imports each lfs object in parallel' do
      importer = described_class.new(project, client)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(importer).to receive(:already_imported?).with(lfs_download_object).and_return(false)
      expect(importer).to receive(:mark_as_imported).with(lfs_download_object)

      expect(Gitlab::GithubImport::ImportLfsObjectWorker).to receive(:perform_in)
        .with(an_instance_of(Float), project.id, an_instance_of(Hash), an_instance_of(String))

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end

    it 'skips already imported lfs objects' do
      importer = described_class.new(project, client)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(importer).to receive(:already_imported?).with(lfs_download_object).and_return(true)
      expect(importer).not_to receive(:mark_as_imported)
      expect(Gitlab::GithubImport::ImportLfsObjectWorker).not_to receive(:perform_in)

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(0)
    end

    it 'marks objects as imported in cache' do
      importer = described_class.new(project, client)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(Gitlab::GithubImport::ImportLfsObjectWorker).to receive(:perform_in)

      expect { importer.parallel_import }
        .to change { importer.already_imported?(lfs_download_object) }
        .from(false).to(true)
    end

    it 'does not schedule duplicate jobs for already imported objects' do
      importer = described_class.new(project, client)
      importer.mark_as_imported(lfs_download_object)

      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
        expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
      end

      expect(Gitlab::GithubImport::ImportLfsObjectWorker).not_to receive(:perform_in)
      expect(Gitlab::GithubImport::ObjectCounter).not_to receive(:increment)

      waiter = importer.parallel_import

      expect(waiter.jobs_remaining).to eq(0)
    end
  end

  describe '#collection_options' do
    it 'returns an empty Hash' do
      importer = described_class.new(project, client)

      expect(importer.collection_options).to eq({})
    end
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the OID of the LFS object' do
      importer = described_class.new(project, client)

      expect(importer.id_for_already_imported_cache(lfs_download_object)).to eq(lfs_download_object.oid)
    end
  end
end
