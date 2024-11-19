# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CheckDuplicatesService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:file_name) { 'package.nupkg' }
  let_it_be_with_reload(:package_settings) { create(:namespace_package_setting, :group, namespace: project.namespace) }

  let(:params) do
    {
      file_name: file_name,
      file: File.open(expand_fixture_path('packages/nuget/package.nupkg'))
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
          package_settings.update!(nuget_duplicate_exception_regex: ".*#{existing_package.name.last(3)}.*")
        end

        it_behaves_like 'returning success'
      end
    end

    shared_examples 'when package file is in object storage' do
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

    shared_examples 'when package file is on disk' do
      before do
        allow_next_instance_of(::Packages::Nuget::MetadataExtractionService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: metadata))
        end
      end

      it_behaves_like 'handling duplicates disallowed when package exists'
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

      before do
        allow_next_instance_of(::Packages::Nuget::MetadataExtractionService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: metadata))
        end
      end

      context 'when nuget duplicates are allowed' do
        before do
          package_settings.update!(nuget_duplicates_allowed: true)
        end

        it_behaves_like 'returning success'

        context 'when the package name matches the exception regex' do
          before do
            package_settings.update!(nuget_duplicate_exception_regex: existing_package.name)
          end

          it_behaves_like 'returning error', reason: :conflict,
            message: 'A package with the same name and version already exists'
        end

        context 'when the package version matches the exception regex' do
          before do
            package_settings.update!(nuget_duplicate_exception_regex: existing_package.version)
          end

          it_behaves_like 'returning error', reason: :conflict,
            message: 'A package with the same name and version already exists'
        end
      end

      context 'when nuget duplicates are not allowed' do
        before do
          package_settings.update!(nuget_duplicates_allowed: false)
        end

        it_behaves_like 'when package file is in object storage'
        it_behaves_like 'when package file is on disk'
      end

      context 'when packages_allow_duplicate_exceptions is disabled' do
        before do
          stub_feature_flags(packages_allow_duplicate_exceptions: false)
        end

        context 'when nuget duplicates are allowed' do
          before do
            package_settings.update!(nuget_duplicates_allowed: true)
          end

          it_behaves_like 'returning success'
        end

        context 'when nuget duplicates are not allowed' do
          before do
            package_settings.update!(nuget_duplicates_allowed: false)
          end

          it_behaves_like 'when package file is in object storage'
          it_behaves_like 'when package file is on disk'
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
        before do
          package_settings.nuget_duplicates_allowed = true
        end

        it_behaves_like 'returning success'
      end

      context 'when nuget duplicates are not allowed' do
        before do
          package_settings.nuget_duplicates_allowed = false
        end

        it_behaves_like 'returning success'
      end

      context 'when packages_allow_duplicate_exceptions is disabled' do
        before do
          stub_feature_flags(packages_allow_duplicate_exceptions: false)
        end

        context 'when nuget duplicates are allowed' do
          before do
            package_settings.nuget_duplicates_allowed = true
          end

          it_behaves_like 'returning success'
        end

        context 'when nuget duplicates are not allowed' do
          before do
            package_settings.nuget_duplicates_allowed = false
          end

          it_behaves_like 'returning success'
        end
      end
    end
  end
end
