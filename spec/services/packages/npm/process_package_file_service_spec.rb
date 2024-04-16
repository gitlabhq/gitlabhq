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

  describe '#execute' do
    it 'processes the package file' do
      expect(package).to receive(:default!)

      service.execute
    end

    context 'with an invalid package file' do
      let(:package_file) { nil }

      it_behaves_like 'raising an error', 'invalid package file'
    end

    context 'when linked to a non npm package' do
      before do
        allow(package).to receive(:npm?).and_return(false)
      end

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
  end
end
