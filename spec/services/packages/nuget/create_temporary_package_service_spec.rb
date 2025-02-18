# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CreateTemporaryPackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:build) { create(:ci_build) }

  describe '#execute' do
    let(:package_params) do
      {
        build: build,
        name: 'nuget-test-package'
      }
    end

    let(:package_file_params) do
      {
        file: Tempfile.new,
        file_name: 'test.txt'
      }
    end

    let(:params) do
      {
        package_params: package_params,
        package_file_params: package_file_params
      }
    end

    let(:service) { described_class.new(project: project, user: user, params: params) }

    subject(:response) { service.execute }

    context 'when successful' do
      it 'creates a temporary package and enqueues extraction', :aggregate_failures do
        expect(Packages::CreatePackageFileService).to receive(:new).and_call_original
        expect(Packages::Nuget::ExtractionWorker).to receive(:perform_async)
        expect { response }.to change { Packages::Package.count }.by(1).and change { Packages::PackageFile.count }.by(1)
        expect(response).to be_success
      end
    end

    context 'when creating temporary package fails' do
      before do
        allow_next_instance_of(Packages::CreateTemporaryPackageService) do |service|
          allow(service).to receive(:execute).and_return(nil)
        end
      end

      it 'returns an error response' do
        expect(response).to be_error
        expect(response.message).to eq('Failed to create temporary package')
      end
    end

    context 'when creating package file fails' do
      let(:package) { create(:nuget_package) }

      before do
        allow_next_instance_of(Packages::CreatePackageFileService) do |service|
          allow(service).to receive(:execute).and_return(nil)
        end
      end

      it 'returns an error response' do
        expect(response).to be_error
        expect(response.message).to eq('Failed to create package file')
      end
    end
  end
end
