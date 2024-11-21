# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::CreatePackageFileService, feature_category: :package_registry do
  let_it_be(:package) { create(:rubygems_package, without_package_files: true) }

  describe '#execute' do
    let(:file_name) { 'example-1.2.3.gem' }
    let(:file) do
      UploadedFile.new(Tempfile.new(file_name).path, filename: file_name, sha256: '543212345', md5: '12345', size: 1234)
    end

    let(:params) do
      {
        file: file,
        file_name: file_name
      }
    end

    let(:service) { described_class.new(package: package, params: params) }

    subject(:response) { service.execute }

    it 'creates a new package file', :aggregate_failures do
      expect(::Packages::Rubygems::ExtractionWorker).to receive(:perform_async).with(an_instance_of(Integer))

      expect { response }.to change { package.package_files.count }.by(1)
      expect(response).to be_success
      expect(response.payload[:package_file].file_name).to eq(file_name)
    end

    context 'when package is missing' do
      let(:package) { nil }

      it 'returns an error response' do
        expect(response).to be_error
        expect(response.message).to eq('Package is required')
        expect(response.reason).to eq(:package_is_required)
      end
    end
  end
end
