# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::ExtractionWorker, type: :worker do
  describe '#perform' do
    let_it_be(:package) { create(:helm_package, without_package_files: true, status: 'processing')}

    let!(:package_file) { create(:helm_package_file, without_loaded_metadatum: true, package: package) }
    let(:package_file_id) { package_file.id }
    let(:channel) { 'stable' }

    let(:expected_metadata) do
      {
        'apiVersion' => 'v2',
        'description' => 'File, Block, and Object Storage Services for your Cloud-Native Environment',
        'icon' => 'https://rook.io/images/rook-logo.svg',
        'name' => 'rook-ceph',
        'sources' => ['https://github.com/rook/rook'],
        'version' => 'v1.5.8'
      }
    end

    subject { described_class.new.perform(channel, package_file_id) }

    shared_examples 'handling error' do
      it 'mark the package as errored', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(Packages::Helm::ExtractFileMetadataService::ExtractionError),
          project_id: package_file.package.project_id
        )
        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and change { package.reload.status }.from('processing').to('error')
      end
    end

    context 'with valid package file' do
      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [channel, package_file_id] }

        it 'updates package and package file', :aggregate_failures do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

          expect { subject }
            .to not_change { Packages::Package.count }
            .and not_change { Packages::PackageFile.count }
            .and change { Packages::Helm::FileMetadatum.count }.from(0).to(1)
            .and change { package.reload.status }.from('processing').to('default')

          helm_file_metadatum = package_file.helm_file_metadatum

          expect(helm_file_metadatum.channel).to eq(channel)
          expect(helm_file_metadatum.metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with invalid package file id' do
      let(:package_file_id) { 5555 }

      it "doesn't update helm_file_metadatum", :aggregate_failures do
        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and not_change { Packages::Helm::FileMetadatum.count }
          .and not_change { package.reload.status }
      end
    end

    context 'with an empty package file' do
      before do
        expect_next_instance_of(Gem::Package::TarReader) do |tar_reader|
          expect(tar_reader).to receive(:each).and_return([])
        end
      end

      it_behaves_like 'handling error'
    end

    context 'with an invalid YAML' do
      before do
        expect_next_instance_of(Gem::Package::TarReader::Entry) do |entry|
          expect(entry).to receive(:read).and_return('{')
        end
      end

      it_behaves_like 'handling error'
    end
  end
end
