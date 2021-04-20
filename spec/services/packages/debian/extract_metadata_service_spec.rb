# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ExtractMetadataService do
  let(:service) { described_class.new(package_file) }

  subject { service.execute }

  RSpec.shared_context 'Debian ExtractMetadata Service' do |trait|
    let(:package_file) { create(:debian_package_file, trait) }
  end

  RSpec.shared_examples 'Test Debian ExtractMetadata Service' do |expected_file_type, expected_architecture, expected_fields|
    it "returns file_type #{expected_file_type.inspect}" do
      expect(subject[:file_type]).to eq(expected_file_type)
    end

    it "returns architecture #{expected_architecture.inspect}" do
      expect(subject[:architecture]).to eq(expected_architecture)
    end

    it "returns fields #{expected_fields.nil? ? '' : 'including '}#{expected_fields.inspect}" do
      if expected_fields.nil?
        expect(subject[:fields]).to be_nil
      else
        expect(subject[:fields]).to include(**expected_fields)
      end
    end
  end

  using RSpec::Parameterized::TableSyntax

  where(:case_name, :trait, :expected_file_type, :expected_architecture, :expected_fields) do
    'with invalid'    | :invalid   | :unknown   | nil     | nil
    'with source'     | :source    | :source    | nil     | nil
    'with dsc'        | :dsc       | :dsc       | nil     | { 'Binary' => 'sample-dev, libsample0, sample-udeb' }
    'with deb'        | :deb       | :deb       | 'amd64' | { 'Multi-Arch' => 'same' }
    'with udeb'       | :udeb      | :udeb      | 'amd64' | { 'Package' => 'sample-udeb' }
    'with buildinfo'  | :buildinfo | :buildinfo | nil     | { 'Architecture' => 'amd64 source', 'Build-Architecture' => 'amd64' }
    'with changes'    | :changes   | :changes   | nil     | { 'Architecture' => 'source amd64', 'Binary' => 'libsample0 sample-dev sample-udeb' }
  end

  with_them do
    include_context 'Debian ExtractMetadata Service', params[:trait] do
      it_behaves_like 'Test Debian ExtractMetadata Service',
        params[:expected_file_type],
        params[:expected_architecture],
        params[:expected_fields]
    end
  end

  context 'with invalid package file' do
    let(:package_file) { create(:conan_package_file) }

    it 'raise error' do
      expect { subject }.to raise_error(described_class::ExtractionError, 'invalid package file')
    end
  end
end
