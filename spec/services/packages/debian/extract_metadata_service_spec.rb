# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ExtractMetadataService, feature_category: :package_registry do
  let(:service) { described_class.new(package_file) }

  subject { service.execute }

  RSpec.shared_context 'with Debian package file' do |trait|
    let(:package_file) { create(:debian_package_file, trait) }
  end

  RSpec.shared_examples 'Test Debian ExtractMetadata Service' do |expected_file_type, expected_architecture, expected_fields|
    it "returns file_type #{expected_file_type.inspect}, architecture #{expected_architecture.inspect} and fields #{expected_fields.nil? ? '' : 'including '}#{expected_fields.inspect}",
      :aggregate_failures do
      expect(subject[:file_type]).to eq(expected_file_type)
      expect(subject[:architecture]).to eq(expected_architecture)

      if expected_fields.nil?
        expect(subject[:fields]).to be_nil
      else
        expect(subject[:fields]).to include(**expected_fields)
      end
    end
  end

  using RSpec::Parameterized::TableSyntax

  context 'with valid file types' do
    where(:case_name, :trait, :expected_file_type, :expected_architecture, :expected_fields) do
      'with source'     | :source    | :source    | nil     | nil
      'with dsc'        | :dsc       | :dsc       | nil     | { 'Binary' => 'sample-dev, libsample0, sample-udeb, sample-ddeb' }
      'with deb'        | :deb       | :deb       | 'amd64' | { 'Multi-Arch' => 'same' }
      'with udeb'       | :udeb      | :udeb      | 'amd64' | { 'Package' => 'sample-udeb' }
      'with ddeb'       | :ddeb      | :ddeb      | 'amd64' | { 'Package' => 'sample-ddeb' }
      'with buildinfo'  | :buildinfo | :buildinfo | nil     | { 'Architecture' => 'amd64 source',
                                                                'Build-Architecture' => 'amd64' }
      'with changes'    | :changes   | :changes   | nil     | { 'Architecture' => 'source amd64',
                                                                'Binary' => 'libsample0 sample-dev sample-udeb' }
    end

    with_them do
      include_context 'with Debian package file', params[:trait] do
        it_behaves_like 'Test Debian ExtractMetadata Service',
          params[:expected_file_type],
          params[:expected_architecture],
          params[:expected_fields]
      end
    end
  end

  context 'with valid source extensions' do
    where(:ext) do
      %i[gz bz2 lzma xz]
    end

    with_them do
      let(:package_file) do
        create(:debian_package_file, :source, file_name: "myfile.tar.#{ext}",
          file_fixture: 'spec/fixtures/packages/debian/sample_1.2.3~alpha2.tar.xz')
      end

      it_behaves_like 'Test Debian ExtractMetadata Service', :source
    end
  end

  context 'with invalid source extensions' do
    where(:ext) do
      %i[gzip bzip2]
    end

    with_them do
      let(:package_file) do
        create(:debian_package_file, :source, file_name: "myfile.tar.#{ext}",
          file_fixture: 'spec/fixtures/packages/debian/sample_1.2.3~alpha2.tar.xz')
      end

      it 'raises an error' do
        expect do
          subject
        end.to raise_error(described_class::ExtractionError,
          "unsupported file extension for file #{package_file.file_name}")
      end
    end
  end

  context 'with invalid file name' do
    let(:package_file) { create(:debian_package_file, :invalid) }

    it 'raises an error' do
      expect do
        subject
      end.to raise_error(described_class::ExtractionError,
        "unsupported file extension for file #{package_file.file_name}")
    end
  end

  context 'with invalid package file' do
    let(:package_file) { create(:conan_package_file) }

    it 'raises an error' do
      expect { subject }.to raise_error(described_class::ExtractionError, 'invalid package file')
    end
  end
end
