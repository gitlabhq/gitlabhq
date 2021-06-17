# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Helm::ExtractFileMetadataService do
  let_it_be(:package_file) { create(:helm_package_file) }

  let(:service) { described_class.new(package_file) }

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

  subject { service.execute }

  context 'with a valid file' do
    it { is_expected.to eq(expected) }
  end

  context 'without Chart.yaml' do
    before do
      expect_next_instances_of(Gem::Package::TarReader::Entry, 14) do |entry|
        expect(entry).to receive(:full_name).exactly(:once).and_wrap_original do |m, *args|
          m.call(*args) + '_suffix'
        end
      end
    end

    it { expect { subject }.to raise_error(described_class::ExtractionError, 'Chart.yaml not found within a directory') }
  end

  context 'with Chart.yaml at root' do
    before do
      expect_next_instances_of(Gem::Package::TarReader::Entry, 14) do |entry|
        expect(entry).to receive(:full_name).exactly(:once).and_return('Chart.yaml')
      end
    end

    it { expect { subject }.to raise_error(described_class::ExtractionError, 'Chart.yaml not found within a directory') }
  end

  context 'with an invalid YAML' do
    before do
      expect_next_instance_of(Gem::Package::TarReader::Entry) do |entry|
        expect(entry).to receive(:read).and_return('{')
      end
    end

    it { expect { subject }.to raise_error(described_class::ExtractionError, 'Error while parsing Chart.yaml: (<unknown>): did not find expected node content while parsing a flow node at line 2 column 1') }
  end
end
