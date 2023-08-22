# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CheckDuplicatesService, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:file_name) { 'package.nupkg' }

  let(:params) do
    {
      file_name: file_name,
      file: temp_file(file_name)
    }
  end

  let(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'returning error' do |reason:, message:|
      it 'returns an error' do
        response = execute

        expect(response.status).to eq(:error)
        expect(response.reason).to eq(reason)
        expect(response.message).to eq(message)
      end
    end

    shared_examples 'returning success' do
      it 'returns success' do
        response = execute

        expect(response.status).to eq(:success)
      end
    end

    shared_examples 'handling duplicates disallowed when package exists' do
      it_behaves_like 'returning error', reason: :conflict,
        message: 'A package with the same name and version already exists'

      context 'with nuget_duplicate_exception_regex' do
        before do
          package_settings.update_column(:nuget_duplicate_exception_regex, ".*#{existing_package.name.last(3)}.*")
        end

        it_behaves_like 'returning success'
      end
    end

    context 'with existing package' do
      let_it_be(:existing_package) { create(:nuget_package, :with_metadatum, project: project, version: '1.7.15.0') }
      let_it_be(:metadata) do
        {
          package_name: existing_package.name,
          package_version: existing_package.version,
          authors: 'authors',
          description: 'description'
        }
      end

      context 'when nuget duplicates are allowed' do
        before do
          allow_next_instance_of(Namespace::PackageSetting) do |instance|
            allow(instance).to receive(:nuget_duplicates_allowed?).and_return(true)
          end
        end

        it_behaves_like 'returning success'
      end

      context 'when nuget duplicates are not allowed' do
        let!(:package_settings) do
          create(:namespace_package_setting, :group, namespace: project.namespace, nuget_duplicates_allowed: false)
        end

        context 'when package file is in object storage' do
          let(:params) { super().merge(remote_url: 'https://example.com') }

          before do
            allow_next_instance_of(::Packages::Nuget::ExtractRemoteMetadataFileService) do |instance|
              allow(instance).to receive(:execute)
              .and_return(ServiceResponse.success(payload: Nokogiri::XML::Document.new))
            end
            allow_next_instance_of(::Packages::Nuget::ExtractMetadataContentService) do |instance|
              allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: metadata))
            end
          end

          it_behaves_like 'handling duplicates disallowed when package exists'

          context 'when ExtractRemoteMetadataFileService raises ExtractionError' do
            before do
              allow_next_instance_of(::Packages::Nuget::ExtractRemoteMetadataFileService) do |instance|
                allow(instance).to receive(:execute).and_raise(
                  ::Packages::Nuget::ExtractRemoteMetadataFileService::ExtractionError, 'nuspec file not found'
                )
              end
            end

            it_behaves_like 'returning error', reason: :bad_request, message: 'nuspec file not found'
          end

          context 'when version is normalized' do
            let(:metadata) { super().merge(package_version: '1.7.15') }

            it_behaves_like 'handling duplicates disallowed when package exists'
          end
        end

        context 'when package file is on disk' do
          before do
            allow_next_instance_of(::Packages::Nuget::MetadataExtractionService) do |instance|
              allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: metadata))
            end
          end

          it_behaves_like 'handling duplicates disallowed when package exists'
        end
      end
    end

    context 'with non existing package' do
      let_it_be(:metadata) do
        { package_name: 'foo', package_version: '1.0.0', authors: 'author', description: 'description' }
      end

      before do
        allow_next_instance_of(::Packages::Nuget::MetadataExtractionService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: metadata))
        end
      end

      context 'when nuget duplicates are allowed' do
        let_it_be(:package_settings) do
          create(:namespace_package_setting, :group, namespace: project.namespace, nuget_duplicates_allowed: true)
        end

        it_behaves_like 'returning success'
      end

      context 'when nuget duplicates are not allowed' do
        let_it_be(:package_settings) do
          create(:namespace_package_setting, :group, namespace: project.namespace, nuget_duplicates_allowed: false)
        end

        it_behaves_like 'returning success'
      end
    end
  end
end
