# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::CreatePackageFileService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let(:package) do
    create(:helm_package, without_package_files: true, status: 'processing',
      project: project, creator: user, name: Packages::Helm::TEMPORARY_PACKAGE_NAME)
  end

  let(:params) do
    {
      file: fixture_file_upload('spec/fixtures/packages/helm/rook-ceph-v1.5.8.tgz'),
      file_name: 'package.tgz'
    }
  end

  subject(:result) { described_class.new(package, params).execute }

  shared_examples 'creating the package file' do
    it 'creates the package file and returns success' do
      expect(result).to be_success
      expect(result.payload[:package_file]).to be_a(Packages::PackageFile)
      expect(result.payload[:package_file]).to be_persisted
    end
  end

  shared_examples 'handling an error' do |expected_reason, expected_message|
    it 'returns an error' do
      expect(result).to be_error
      expect(result.reason).to eq(expected_reason)
      expect(result.message).to eq(expected_message)
    end

    it 'destroys the temporary package' do
      expect { result }.to change { Packages::Package.exists?(package.id) }.from(true).to(false)
    end
  end

  describe '#execute' do
    context 'without a package protection rule' do
      it_behaves_like 'creating the package file'
    end

    context 'with a package protection rule' do
      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule,
          package_name_pattern: 'rook-ceph',
          package_type: :helm,
          minimum_access_level_for_push: :maintainer,
          project: project)
      end

      context 'when user access level is below minimum' do
        let_it_be(:developer) { create(:user, developer_of: project) }
        let(:package) do
          create(:helm_package, without_package_files: true, status: 'processing',
            project: project, creator: developer, name: Packages::Helm::TEMPORARY_PACKAGE_NAME)
        end

        it_behaves_like 'handling an error', :package_protected, 'Package protected.'
      end

      context 'when user access level meets minimum' do
        it_behaves_like 'creating the package file'
      end

      context 'with a deploy token' do
        let_it_be(:deploy_token) { create(:deploy_token, projects: [project], write_package_registry: true) }
        let(:package) do
          create(:helm_package, without_package_files: true, status: 'processing',
            project: project, creator: nil, name: Packages::Helm::TEMPORARY_PACKAGE_NAME)
        end

        it_behaves_like 'handling an error', :package_protected, 'Package protected.'
      end
    end

    context 'when the protection check service returns an error' do
      let(:protection_service) do
        instance_double(::Packages::Protection::CheckRuleExistenceService,
          execute: ServiceResponse.error(message: 'something went wrong'))
      end

      before do
        allow(::Packages::Protection::CheckRuleExistenceService).to receive(:for_push).and_return(protection_service)
      end

      it 'does not block the upload' do
        expect(result).to be_success
        expect(result.payload[:package_file]).to be_persisted
      end
    end

    context 'when metadata extraction fails' do
      let(:extract_service) { instance_double(::Packages::Helm::ExtractFileMetadataService) }

      before do
        allow(::Packages::Helm::ExtractFileMetadataService).to receive(:new).and_return(extract_service)
        allow(extract_service).to receive(:execute).and_raise(
          Packages::Helm::ExtractFileMetadataService::ExtractionError, 'Chart.yaml not found within a directory'
        )
      end

      it_behaves_like 'handling an error', :extraction_error, 'Chart.yaml not found within a directory'
    end

    context 'when chart name is blank' do
      let(:extract_service) do
        instance_double(::Packages::Helm::ExtractFileMetadataService, execute: { 'version' => 'v1.0.0' })
      end

      before do
        allow(::Packages::Helm::ExtractFileMetadataService).to receive(:new).and_return(extract_service)
      end

      it_behaves_like 'handling an error', :extraction_error, 'Chart name not found.'
    end
  end
end
