# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Helm::ProcessFileService do
  let(:package) { create(:helm_package, without_package_files: true, status: 'processing')}
  let!(:package_file) { create(:helm_package_file, without_loaded_metadatum: true, package: package) }
  let(:channel) { 'stable' }
  let(:service) { described_class.new(channel, package_file) }

  let(:expected) do
    {
      'apiVersion' => 'v2',
      'description' => 'File, Block, and Object Storage Services for your Cloud-Native Environment',
      'icon' => 'https://rook.io/images/rook-logo.svg',
      'name' => 'rook-ceph',
      'sources' => ['https://github.com/rook/rook'],
      'version' => 'v1.5.8'
    }
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'without a file' do
      let(:package_file) { nil }

      it 'returns error', :aggregate_failures do
        expect { execute }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and not_change { Packages::Helm::FileMetadatum.count }
          .and raise_error(Packages::Helm::ProcessFileService::ExtractionError, 'Helm chart was not processed - package_file is not set')
      end
    end

    context 'with existing package' do
      let!(:existing_package) { create(:helm_package, project: package.project, name: 'rook-ceph', version: 'v1.5.8') }

      it 'reuses existing package', :aggregate_failures do
        expect { execute }
          .to change { Packages::Package.count }.from(2).to(1)
          .and not_change { package.name }
          .and not_change { package.version }
          .and not_change { package.status }
          .and not_change { Packages::PackageFile.count }
          .and change { package_file.file_name }.from(package_file.file_name).to("#{expected['name']}-#{expected['version']}.tgz")
          .and change { Packages::Helm::FileMetadatum.count }.from(1).to(2)
          .and change { package_file.helm_file_metadatum }.from(nil)

        expect { package.reload }
          .to raise_error(ActiveRecord::RecordNotFound)

        expect(package_file.helm_file_metadatum.channel).to eq(channel)
        expect(package_file.helm_file_metadatum.metadata).to eq(expected)
      end
    end

    context 'with a valid file' do
      it 'processes file', :aggregate_failures do
        expect { execute }
          .to not_change { Packages::Package.count }
          .and change { package.name }.from(package.name).to(expected['name'])
          .and change { package.version }.from(package.version).to(expected['version'])
          .and change { package.status }.from('processing').to('default')
          .and not_change { Packages::PackageFile.count }
          .and change { package_file.file_name }.from(package_file.file_name).to("#{expected['name']}-#{expected['version']}.tgz")
          .and change { Packages::Helm::FileMetadatum.count }.by(1)
          .and change { package_file.helm_file_metadatum }.from(nil)

        expect(package_file.helm_file_metadatum.channel).to eq(channel)
        expect(package_file.helm_file_metadatum.metadata).to eq(expected)
      end
    end

    context 'without Chart.yaml' do
      before do
        expect_next_instances_of(Gem::Package::TarReader::Entry, 14) do |entry|
          expect(entry).to receive(:full_name).exactly(:once).and_wrap_original do |m, *args|
            m.call(*args) + '_suffix'
          end
        end
      end

      it { expect { execute }.to raise_error(Packages::Helm::ExtractFileMetadataService::ExtractionError, 'Chart.yaml not found within a directory') }
    end

    context 'with Chart.yaml at root' do
      before do
        expect_next_instances_of(Gem::Package::TarReader::Entry, 14) do |entry|
          expect(entry).to receive(:full_name).exactly(:once).and_return('Chart.yaml')
        end
      end

      it { expect { execute }.to raise_error(Packages::Helm::ExtractFileMetadataService::ExtractionError, 'Chart.yaml not found within a directory') }
    end

    context 'with an invalid YAML' do
      before do
        expect_next_instance_of(Gem::Package::TarReader::Entry) do |entry|
          expect(entry).to receive(:read).and_return('{')
        end
      end

      it { expect { execute }.to raise_error(Packages::Helm::ExtractFileMetadataService::ExtractionError, 'Error while parsing Chart.yaml: (<unknown>): did not find expected node content while parsing a flow node at line 2 column 1') }
    end
  end
end
