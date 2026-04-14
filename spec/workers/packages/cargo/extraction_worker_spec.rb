# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::ExtractionWorker, feature_category: :package_registry do
  describe '#perform' do
    let_it_be(:package_name) { 'test-crate' }
    let_it_be(:package_version) { '1.0.0' }
    let_it_be(:project) { create(:project) }

    let!(:package) { create(:cargo_package, name: 'package-name', version: '1.0.1', project: project) }

    let(:package_file) { package.package_files.first }
    let(:package_file_id) { package_file.id }
    let(:user) { create(:user, maintainer_of: project) }
    let(:params) { { user_id: user.id } }

    subject(:cargo_extraction_worker) { described_class.new.perform(package_file_id, params) }

    shared_examples 'handling error' do |error_message:,
      error_class: ::Packages::Cargo::UpdatePackageFromMetadataService::InvalidMetadataError|
      it 'updates package status to error', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(error_class),
          {
            package_file_id: package_file.id,
            project_id: package.project_id
          }
        )

        subject

        expect(package.reload).to be_error
        expect(package.status_message).to match(error_message)
      end
    end

    shared_examples 'updates package and package file' do
      it 'updates package and package file' do
        expect { cargo_extraction_worker }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
      end
    end

    shared_examples 'returns early without processing' do
      it 'returns early without processing' do
        expect(::Packages::Cargo::ProcessPackageFileService).not_to receive(:new)

        expect { cargo_extraction_worker }.not_to raise_error
      end
    end

    context 'with valid package file' do
      it_behaves_like 'updates package and package file'
    end

    context 'when package file does not exist' do
      let(:package_file_id) { non_existing_record_id }

      it_behaves_like 'returns early without processing'
    end

    context 'without user_or_deploy_token' do
      let(:params) { {} }

      it 'returns early without processing' do
        expect(::Packages::Cargo::ProcessPackageFileService).not_to receive(:new)

        expect { cargo_extraction_worker }.not_to raise_error
      end
    end

    context 'when package_file is nil and an exception is raised' do
      let(:package_file_id) { non_existing_record_id }
      let(:error) { StandardError.new('test error') }

      it 're-raises the exception instead of calling process_package_file_error' do
        worker = described_class.new

        allow(worker).to receive(:process_package_file_error)
        allow(::Packages::PackageFile).to receive_message_chain(:not_processing, :find_by_id) do
          raise error
        end

        expect(worker).not_to receive(:process_package_file_error)
        expect { worker.perform(package_file_id, params) }.to raise_error(error)
      end
    end

    context 'with invalid metadata' do
      let(:invalid_metadata_payload) do
        {
          index_content: {},
          crate_data: nil
        }
      end

      let(:fake_service) do
        instance_double(
          ::Packages::Cargo::ExtractMetadataContentService,
          execute: ServiceResponse.success(payload: invalid_metadata_payload)
        )
      end

      before do
        allow(::Packages::Cargo::ExtractMetadataContentService)
          .to receive(:new)
          .and_return(fake_service)
      end

      it_behaves_like 'handling error',
        error_class: ::Packages::Cargo::UpdatePackageFromMetadataService::InvalidMetadataError,
        error_message: ::Packages::Cargo::UpdatePackageFromMetadataService::INVALID_METADATA_ERROR_MESSAGE
    end

    context 'with duplicate package' do
      let_it_be(:existing_package) do
        create(
          :cargo_package,
          name: package_name,
          version: package_version,
          project: project
        )
      end

      let_it_be(:existing_package_metadata) do
        create(:cargo_metadatum,
          package: existing_package
        )
      end

      let(:duplicate_metadata_payload) do
        {
          index_content: {
            name: package_name,
            vers: package_version,
            deps: [],
            cksum: '123'
          },
          crate_data: 'fake-crate-binary-data'
        }
      end

      let(:fake_service) do
        instance_double(
          ::Packages::Cargo::ExtractMetadataContentService,
          execute: ServiceResponse.success(payload: duplicate_metadata_payload)
        )
      end

      before do
        allow(::Packages::Cargo::ExtractMetadataContentService)
          .to receive(:new)
          .and_return(fake_service)
      end

      it_behaves_like 'handling error',
        error_class: ::Packages::Cargo::UpdatePackageFromMetadataService::DuplicatePackageError,
        error_message: ::Packages::Cargo::UpdatePackageFromMetadataService::DUPLICATE_PACKAGE_ERROR_MESSAGE
    end

    context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
      using RSpec::Parameterized::TableSyntax

      let(:package_protection_rule) do
        create(:package_protection_rule, package_type: :cargo, project: package.project)
      end

      let(:package_name_pattern) { 'test-*' }

      let(:project_developer) { create(:user, developer_of: package.project) }
      let(:project_maintainer) { create(:user, maintainer_of: package.project) }
      let(:project_owner) { package.project.owner }
      let(:instance_admin) { create(:admin) }

      let(:project_deploy_token) do
        create(:deploy_token, projects: [package.project], write_package_registry: true)
      end

      subject { described_class.new.perform(package_file_id, params) }

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
        package.update!(creator: package_creator)
      end

      shared_examples 'protected package' do
        it_behaves_like 'handling error',
          error_class: ::Packages::Cargo::UpdatePackageFromMetadataService::ProtectedPackageError,
          error_message: ::Packages::Cargo::UpdatePackageFromMetadataService::PROTECTED_PACKAGE_ERROR_MESSAGE
      end

      # rubocop:disable Layout/LineLength -- Required for formatting of table
      where(:package_name_pattern, :minimum_access_level_for_push, :package_creator, :params, :shared_examples_name) do
        ref(:package_name)               | :maintainer | ref(:project_developer)  | { user_id: ref(:project_developer) }            | 'protected package'
        ref(:package_name)               | :maintainer | ref(:project_developer)  | {}                                              | 'returns early without processing'
        ref(:package_name)               | :maintainer | ref(:project_maintainer) | { user_id: ref(:project_maintainer) }           | 'updates package and package file'
        ref(:package_name)               | :maintainer | ref(:project_maintainer) | {}                                              | 'returns early without processing'
        ref(:package_name)               | :maintainer | nil                      | {}                                              | 'returns early without processing'
        ref(:package_name)               | :maintainer | nil                      | { deploy_token_id: ref(:project_deploy_token) } | 'protected package'

        ref(:package_name)               | :owner      | ref(:project_maintainer) | { user_id: ref(:project_maintainer) }           | 'protected package'
        ref(:package_name)               | :owner      | ref(:project_maintainer) | {}                                              | 'returns early without processing'
        ref(:package_name)               | :owner      | ref(:project_owner)      | { user_id: ref(:project_owner) }                | 'updates package and package file'
        ref(:package_name)               | :owner      | nil                      | {}                                              | 'returns early without processing'
        ref(:package_name)               | :owner      | nil                      | { deploy_token_id: ref(:project_deploy_token) } | 'protected package'

        ref(:package_name)               | :admin      | ref(:project_maintainer) | { user_id: ref(:project_maintainer) }           | 'protected package'
        ref(:package_name)               | :admin      | ref(:project_maintainer) | {}                                              | 'returns early without processing'
        ref(:package_name)               | :admin      | ref(:project_owner)      | { user_id: ref(:project_owner) }                | 'protected package'
        ref(:package_name)               | :admin      | ref(:instance_admin)     | { user_id: ref(:instance_admin) }               | 'updates package and package file'
        ref(:package_name)               | :admin      | ref(:instance_admin)     | {}                                              | 'returns early without processing'
        ref(:package_name)               | :admin      | nil                      | {}                                              | 'returns early without processing'
        ref(:package_name)               | :admin      | nil                      | { deploy_token_id: ref(:project_deploy_token) } | 'protected package'

        lazy { "Other.#{package_name}" } | :admin      | ref(:project_owner)      | { user_id: ref(:project_owner) }                | 'updates package and package file'
        lazy { "Other.#{package_name}" } | :admin      | nil                      | {}                                              | 'returns early without processing'
        lazy { "Other.#{package_name}" } | :admin      | nil                      | {}                                              | 'returns early without processing'
        lazy { "Other.#{package_name}" } | :admin      | nil                      | nil                                             | 'returns early without processing'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
