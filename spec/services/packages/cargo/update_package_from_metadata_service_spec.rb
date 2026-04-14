# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::UpdatePackageFromMetadataService, :clean_gitlab_redis_shared_state, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }

  let!(:package) { create(:cargo_package, :processing, project: project, name: 'old-name', version: '0.0.1') }
  let(:package_file) { package.reload.package_files.first }
  let(:request_file) { StringIO.new }
  let(:user_or_deploy_token) { create(:user, maintainer_of: project) }
  let(:service) { described_class.new(package_file, request_file, user_or_deploy_token) }

  let(:package_name) { 'test-crate' }
  let(:package_version) { '1.0.0' }
  let(:package_filename) { "#{package_name}-#{package_version}.crate" }
  let(:index_content) do
    {
      name: package_name,
      vers: package_version,
      deps: [{ name: 'dep_1', req: '^0.6' }],
      cksum: 'checksum',
      v: 2
    }
  end

  let(:crate_data) { 'crate-binary-data' }
  let(:metadata_payload) { { index_content: index_content, crate_data: crate_data } }
  let(:extract_service_response) { ServiceResponse.success(payload: metadata_payload) }

  before do
    allow_next_instance_of(::Packages::Cargo::ExtractMetadataContentService) do |extract_service|
      allow(extract_service).to receive(:execute).and_return(extract_service_response)
    end
  end

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject(:execute_service) { service.execute }

    shared_examples 'raising an error' do |error_class, with_message:|
      it "raises #{error_class}" do
        expect { execute_service }.to raise_error(error_class, with_message)
      end
    end

    shared_examples 'taking the lease' do
      before do
        allow(service).to receive(:lease_release?).and_return(false)
      end

      it 'takes the lease' do
        expect(service).to receive(:try_obtain_lease).and_call_original

        execute_service

        expect(service.exclusive_lease.exists?).to be_truthy
      end
    end

    shared_examples 'not updating the package if the lease is taken' do
      context 'without obtaining the exclusive lease' do
        let(:lease_key) { "packages:cargo:update_package_from_metadata_service:package:#{package_file.package_id}" }

        before do
          stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
        end

        it 'does not update the package', :aggregate_failures do
          original_file_name = package_file.file_name
          original_size = package_file.size

          expect(service).to receive(:try_obtain_lease).and_call_original

          expect { execute_service }
            .to not_change { ::Packages::Package.count }
            .and not_change { Packages::Cargo::Metadatum.count }

          package_file.reload
          expect(package_file.file_name).to eq(original_file_name)
          expect(package_file.size).to eq(original_size)
          expect(package.reload.name).not_to eq(package_name)
          expect(package.version).not_to eq(package_version)
        end
      end
    end

    context 'with valid metadata' do
      it 'updates package, package file, and creates metadatum', :aggregate_failures do
        expected_sha = Digest::SHA256.hexdigest(crate_data)

        expect { execute_service }
          .to not_change { ::Packages::Package.count }
          .and change { Packages::Cargo::Metadatum.count }.by(1)

        expect(package.reload.name).to eq(package_name)
        expect(package.version).to eq(package_version)
        expect(package).to be_default

        package_file.reload

        expect(package_file.file_name).to eq(package_filename)
        expect(package_file.file_sha256).to eq(expected_sha)
        expect(package_file.size).to eq(crate_data.bytesize)
        expect(Packages::PackageFile.find(package_file.id).file.size).to eq(crate_data.bytesize)

        metadatum = package.cargo_metadatum
        expect(metadatum.index_content).to eq(index_content.deep_stringify_keys)
      end

      it_behaves_like 'taking the lease'

      it_behaves_like 'not updating the package if the lease is taken'
    end

    context 'with duplicate package' do
      let!(:existing_package) do
        create(:cargo_package, project: project, name: package_name, version: package_version, package_files: [])
      end

      let!(:existing_metadatum) do
        create(:cargo_metadatum, package: existing_package, project: project,
          index_content: index_content.deep_stringify_keys)
      end

      it_behaves_like 'raising an error',
        described_class::DuplicatePackageError,
        with_message: described_class::DUPLICATE_PACKAGE_ERROR_MESSAGE
    end

    context 'when package is protected' do
      before do
        allow(service).to receive(:package_protected?).and_return(true)
      end

      it_behaves_like 'raising an error',
        described_class::ProtectedPackageError,
        with_message: described_class::PROTECTED_PACKAGE_ERROR_MESSAGE
    end

    context 'when package protection check returns an error' do
      before do
        allow_next_instance_of(::Packages::Protection::CheckRuleExistenceService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'something went wrong'))
        end
      end

      it_behaves_like 'raising an error',
        ArgumentError,
        with_message: 'something went wrong'
    end

    context 'with missing metadata' do
      context 'when index_content is empty' do
        let(:metadata_payload) { { index_content: {}, crate_data: crate_data } }

        it_behaves_like 'raising an error',
          described_class::InvalidMetadataError,
          with_message: described_class::INVALID_METADATA_ERROR_MESSAGE
      end

      context 'when name is present but version is missing' do
        let(:metadata_payload) { { index_content: { name: 'test-crate', vers: nil }, crate_data: crate_data } }

        it_behaves_like 'raising an error',
          described_class::InvalidMetadataError,
          with_message: described_class::INVALID_METADATA_ERROR_MESSAGE
      end

      context 'when version is present but name is missing' do
        let(:metadata_payload) { { index_content: { name: nil, vers: '1.0.0' }, crate_data: crate_data } }

        it_behaves_like 'raising an error',
          described_class::InvalidMetadataError,
          with_message: described_class::INVALID_METADATA_ERROR_MESSAGE
      end

      context 'when extract metadata content service returns an error' do
        let(:extract_service_response) { ServiceResponse.error(message: 'metadata extraction failed') }

        it_behaves_like 'raising an error',
          described_class::InvalidMetadataError,
          with_message: 'metadata extraction failed'
      end

      context 'with invalid package name' do
        let(:package_name) { 'invalid/name' }

        it_behaves_like 'raising an error',
          described_class::InvalidMetadataError,
          with_message: /Name must be a valid cargo package name/
      end

      context 'with invalid package version' do
        let(:package_version) { 'not-a-version' }

        it_behaves_like 'raising an error',
          described_class::InvalidMetadataError,
          with_message: "Validation failed: Version #{Gitlab::Regex.semver_regex_message}"
      end

      context 'with package protection rule for different actors', :enable_admin_mode do
        let(:package_protection_rule) do
          create(:package_protection_rule, package_type: :cargo, project: project)
        end

        let(:project_developer) { create(:user, developer_of: project) }
        let(:project_maintainer) { create(:user, maintainer_of: project) }
        let(:project_owner) { project.owner }
        let(:instance_admin) { create(:admin) }
        let(:project_deploy_token) do
          create(:deploy_token, projects: [project], write_package_registry: true)
        end

        let(:user_or_deploy_token) { package_publishing_actor }
        let(:service) { described_class.new(package_file, request_file, user_or_deploy_token) }

        before do
          package_protection_rule.update!(
            package_name_pattern: package_name_pattern,
            minimum_access_level_for_push: minimum_access_level_for_push
          )

          package.update!(creator: package_creator)
        end

        shared_examples 'protected package' do
          it_behaves_like 'raising an error',
            described_class::ProtectedPackageError,
            with_message: described_class::PROTECTED_PACKAGE_ERROR_MESSAGE
        end

        shared_examples 'updates package and package file and creates metadatum' do
          it 'updates package and package file and creates metadatum', :aggregate_failures do
            expect { execute_service }
              .to change { Packages::Cargo::Metadatum.count }.by(1)

            expect(package.reload.name).to eq(package_name)
            expect(package.version).to eq(package_version)
          end
        end

        # rubocop:disable Layout/LineLength -- Required for formatting of table
        where(:package_name_pattern, :minimum_access_level_for_push, :package_creator, :package_publishing_actor, :shared_examples_name) do
          ref(:package_name)          | :maintainer | ref(:project_developer)  | ref(:project_developer)    | 'protected package'
          ref(:package_name)          | :maintainer | ref(:project_maintainer) | ref(:project_maintainer)   | 'updates package and package file and creates metadatum'
          ref(:package_name)          | :maintainer | ref(:project_owner)      | ref(:project_owner)        | 'updates package and package file and creates metadatum'
          ref(:package_name)          | :maintainer | nil                      | ref(:project_deploy_token) | 'protected package'
          ref(:package_name)          | :maintainer | nil                      | ref(:project_developer)    | 'protected package'

          ref(:package_name)          | :owner      | ref(:project_maintainer) | ref(:project_maintainer)   | 'protected package'
          ref(:package_name)          | :owner      | ref(:project_owner)      | ref(:project_owner)        | 'updates package and package file and creates metadatum'
          ref(:package_name)          | :owner      | nil                      | ref(:project_deploy_token) | 'protected package'
          ref(:package_name)          | :owner      | nil                      | ref(:project_maintainer)   | 'protected package'

          ref(:package_name)          | :admin      | ref(:project_owner)      | ref(:project_owner)        | 'protected package'
          ref(:package_name)          | :admin      | ref(:instance_admin)     | ref(:instance_admin)       | 'updates package and package file and creates metadatum'
          ref(:package_name)          | :admin      | nil                      | ref(:project_deploy_token) | 'protected package'

          lazy { "other-#{package_name}" } | :admin      | nil                  | ref(:project_deploy_token) | 'updates package and package file and creates metadatum'
          lazy { "other-#{package_name}" } | :maintainer | nil                  | ref(:project_deploy_token) | 'updates package and package file and creates metadatum'
        end
        # rubocop:enable Layout/LineLength

        with_them do
          it_behaves_like params[:shared_examples_name]
        end
      end
    end
  end
end
