# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::ProcessGemService, feature_category: :package_registry do
  include ExclusiveLeaseHelpers
  include RubygemsHelpers

  let_it_be_with_reload(:package) { create(:rubygems_package, :processing, name: 'temp_name', version: '0.0.0') }

  let(:package_file) { create(:package_file, :unprocessed_gem, package: package) }
  let(:gem) { gem_from_file(package_file.file) }
  let(:gemspec) { gem.spec }
  let(:service) { described_class.new(package_file) }

  describe '#execute' do
    subject { service.execute }

    context 'no gem file' do
      let(:package_file) { nil }

      it 'returns an error' do
        expect { subject }.to raise_error(::Packages::Rubygems::ProcessGemService::ExtractionError, 'Gem was not processed - package_file is not set')
      end
    end

    context 'success' do
      let(:sub_service) { double }

      before do
        expect(Packages::Rubygems::MetadataExtractionService).to receive(:new).with(package, gemspec).and_return(sub_service)
        expect(Packages::Rubygems::CreateGemspecService).to receive(:new).with(package, gemspec).and_return(sub_service)
        expect(Packages::Rubygems::CreateDependenciesService).to receive(:new).with(package, gemspec).and_return(sub_service)

        expect(sub_service).to receive(:execute).exactly(3).times.and_return(true)
      end

      it 'returns successfully', :aggregate_failures do
        result = subject

        expect(result.success?).to be true
        expect(result.payload[:package]).to eq(package)
      end

      it 'updates the package name and version', :aggregate_failures do
        expect(package.name).to eq('temp_name')
        expect(package.version).to eq('0.0.0')
        expect(package).to be_processing

        subject

        expect(package.reload.name).to eq('package')
        expect(package.version).to eq('0.0.1')
        expect(package).to be_default
      end

      it 'updates the package file name', :aggregate_failures do
        expect(package_file.file_name).to eq('package.gem')

        subject

        expect(package_file.reload.file_name).to eq('package-0.0.1.gem')
      end
    end

    context 'when the package already exists' do
      let_it_be(:existing_package) { create(:rubygems_package, name: 'package', version: '0.0.1', project: package.project) }

      let(:sub_service) { double }

      before do
        expect(Packages::Rubygems::MetadataExtractionService).to receive(:new).with(existing_package, gemspec).and_return(sub_service)
        expect(Packages::Rubygems::CreateGemspecService).to receive(:new).with(existing_package, gemspec).and_return(sub_service)
        expect(Packages::Rubygems::CreateDependenciesService).to receive(:new).with(existing_package, gemspec).and_return(sub_service)

        expect(sub_service).to receive(:execute).exactly(3).times.and_return(true)
      end

      it 'assigns the package_file to the existing package and deletes the temporary package', :aggregate_failures do
        expect(package).to receive(:destroy)

        expect { subject }.to change { existing_package.package_files.count }.by(1)

        expect(package_file.reload.package).to eq(existing_package)
      end
    end

    context 'when the package already exists marked as pending_destruction' do
      let_it_be_with_reload(:existing_package) { create(:rubygems_package, name: 'package', version: '0.0.1', project: package.project) }

      let(:sub_service) { double }

      before do
        expect(Packages::Rubygems::MetadataExtractionService).to receive(:new).with(package, gemspec).and_return(sub_service)
        expect(Packages::Rubygems::CreateGemspecService).to receive(:new).with(package, gemspec).and_return(sub_service)
        expect(Packages::Rubygems::CreateDependenciesService).to receive(:new).with(package, gemspec).and_return(sub_service)

        expect(sub_service).to receive(:execute).exactly(3).times.and_return(true)

        existing_package.pending_destruction!
      end

      it 'reuses the processing package' do
        expect { subject }
          .to not_change { package.project.packages.count }
          .and not_change { existing_package.package_files.count }
      end
    end

    context 'sub-service failure' do
      before do
        expect(Packages::Rubygems::MetadataExtractionService).to receive(:new).with(package, gemspec).and_raise(::Packages::Rubygems::ProcessGemService::ExtractionError.new('failure'))
      end

      it 'returns an error' do
        expect { subject }.to raise_error(::Packages::Rubygems::ProcessGemService::ExtractionError, 'failure')
      end
    end

    context 'bad gem file' do
      before do
        expect(Gem::Package).to receive(:new).and_raise(ArgumentError)
      end

      it 'returns an error' do
        expect { subject }.to raise_error(::Packages::Rubygems::ProcessGemService::ExtractionError, 'Unable to read gem file')
      end
    end

    context 'without obtaining an exclusive lease' do
      let(:lease_key) { "packages:rubygems:process_gem_service:package:#{package.id}" }

      before do
        stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
      end

      it 'does not perform the services', :aggregate_failures do
        # The #use_file call triggers a separate lease on the package file being opened
        # for use with the gem. We don't want to test that here, so we allow the call to proceed
        expect(Gitlab::ExclusiveLease).to receive(:new).with("object_storage_migrate:Packages::PackageFile:#{package_file.id}", anything).and_call_original

        expect(Packages::Rubygems::MetadataExtractionService).not_to receive(:new)
        expect(Packages::Rubygems::CreateGemspecService).not_to receive(:new)
        expect(Packages::Rubygems::CreateDependenciesService).not_to receive(:new)

        subject

        expect(package.reload.name).to eq('temp_name')
        expect(package.version).to eq('0.0.0')
        expect(package).to be_processing
        expect(package_file.reload.file_name).to eq('package.gem')
      end
    end

    context 'with invalid metadata' do
      include_context 'with invalid Rubygems metadata'

      it 'raises the correct error' do
        expect { subject }
          .to raise_error(::Packages::Rubygems::ProcessGemService::InvalidMetadataError, 'Invalid metadata')
      end
    end
  end
end
