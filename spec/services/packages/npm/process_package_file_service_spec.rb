# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::ProcessPackageFileService, feature_category: :package_registry do
  let_it_be(:package) { build(:npm_package, :processing, id: 1) }
  let_it_be(:package_file) do
    build(:package_file, :npm, file_fixture: expand_fixture_path('packages/npm/package-1.3.7.tgz'), package: package)
  end

  subject(:service) { described_class.new(package_file) }

  shared_examples 'raising an error' do |error_message|
    it { expect { service.execute }.to raise_error(described_class::ExtractionError, error_message) }
  end

  shared_examples 'processing the package file' do
    it 'processes the package file and enqueues a worker to create metadata cache' do
      expect(::Packages::Npm::CreateMetadataCacheWorker).to receive(:perform_async).with(
        package.project_id,
        package.name
      )
      expect_next_instance_of(::Packages::Npm::CheckManifestCoherenceService, package,
        instance_of(Gem::Package::TarReader::Entry)) do |service|
        expect(service).to receive(:execute)
      end
      expect(package).to receive(:default!)

      service.execute
    end
  end

  describe '#execute' do
    it_behaves_like 'processing the package file'

    context 'with an invalid package file' do
      let(:package_file) { nil }

      it_behaves_like 'raising an error', 'invalid package file'
    end

    context 'with a 0 byte package file' do
      before do
        allow(package_file.file).to receive(:size).and_return(0)
      end

      it_behaves_like 'raising an error', 'invalid package file'
    end

    context 'when the package status is not processing' do
      before do
        allow(package).to receive(:processing?).and_return(false)
      end

      it_behaves_like 'raising an error', 'invalid package file'
    end

    context 'with a missing package.json' do
      let(:package_file) { build(:package_file, :npm, package: package) }

      it_behaves_like 'raising an error', 'package.json not found'
    end

    context 'with a package.json file that is too large' do
      before do
        allow_next_instance_of(Gem::Package::TarReader::Entry) do |instance|
          allow(instance).to receive(:size).and_return(described_class::MAX_FILE_SIZE + 1)
        end
      end

      it_behaves_like 'raising an error', 'package.json file too large'
    end

    context 'with custom root folder name' do
      before do
        allow_next_instance_of(Gem::Package::TarReader::Entry) do |instance|
          allow(instance).to receive(:full_name).and_return('custom/package.json')
        end
      end

      it_behaves_like 'processing the package file'
    end

    context 'with multiple package.json entries' do
      let(:archives) do
        [
          instance_double(Gem::Package::TarReader::Entry, full_name: 'pkg1/foo/package.json'),
          instance_double(Gem::Package::TarReader::Entry, full_name: 'pkg1/foo/bar/package.json'),
          instance_double(Gem::Package::TarReader::Entry, full_name: 'pkg1/package.json'),
          instance_double(Gem::Package::TarReader::Entry, full_name: 'package/package.json'),
          instance_double(Gem::Package::TarReader::Entry, full_name: 'pkg2/package.json'),
          instance_double(Gem::Package::TarReader::Entry, full_name: 'pkg3/package.json')
        ]
      end

      before do
        allow(Gem::Package::TarReader).to receive(:new).and_return(archives)
        allow(archives).to receive(:rewind).and_return(0)
      end

      it 'yeilds last root package.json entry' do
        expect { |b| service.send(:with_package_json_entry, &b) }.to yield_with_args(
          archives.find { |e| e.full_name == 'pkg3/package.json' }
        )
      end
    end

    context 'with TarInvalidError' do
      before do
        allow_next_instance_of(Gem::Package::TarReader::Entry) do |instance|
          allow(instance).to receive(:full_name).and_raise(::Gem::Package::TarInvalidError)
        end
      end

      it_behaves_like 'processing the package file'
    end
  end
end
