# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CreatePackageService, feature_category: :package_registry do
  let(:service) { described_class.new(project, user, params) }

  subject(:execute_service) { service.execute }

  describe '#execute' do
    include ExclusiveLeaseHelpers

    let_it_be(:namespace) { create(:namespace) }
    let_it_be_with_reload(:project) { create(:project, namespace: namespace) }
    let_it_be(:user) { project.owner }

    let(:version) { '1.0.1' }

    let(:params) do
      Gitlab::Json.parse(fixture_file('packages/npm/payload.json')
          .gsub('@root/npm-test', package_name)
          .gsub('1.0.1', version)).with_indifferent_access
    end

    let(:package_name) { "@#{namespace.path}/my-app" }
    let(:version_data) { params.dig('versions', version) }
    let(:lease_key) { "packages:npm:create_package_service:packages:#{project.id}_#{package_name}_#{version}" }

    shared_examples 'valid package' do
      let(:package) { subject[:package] }

      it 'creates a package' do
        expect(::Packages::Npm::ProcessPackageFileWorker).to receive(:perform_async).once

        expect { subject }
          .to change { Packages::Package.count }.by(1)
          .and change { Packages::Npm::Package.count }.by(1)
          .and change { Packages::Tag.count }.by(1)
          .and change { Packages::Npm::Metadatum.count }.by(1)
      end

      it_behaves_like 'assigns the package creator'

      it 'returns a valid package' do
        subject

        expect(package).to be_valid
          .and have_attributes name: package_name, version: version
        expect(package.npm_metadatum.package_json).to eq(version_data)
      end

      context 'with build info' do
        let_it_be_with_reload(:job) { create(:ci_build, user: nil) }
        let(:params) { super().merge(build: job) }

        before do
          job.update!(user: user)
        end

        it_behaves_like 'assigns build to package' do
          subject { super().payload.fetch(:package) }
        end

        it 'creates a package file build info' do
          expect { subject }.to change { Packages::PackageFileBuildInfo.count }.by(1)
        end
      end

      context 'with status param' do
        subject { super().payload.fetch(:package) }

        it { is_expected.to have_attributes status: 'processing' }
      end

      context 'when the npm metadatum creation results in a size error' do
        shared_examples 'a package json structure size too large error' do
          it 'does not create the package' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
              instance_of(ActiveRecord::RecordInvalid),
              field_sizes: expected_field_sizes
            )

            expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /structure is too large/)
              .and not_change { Packages::Package.count }
              .and not_change { Packages::Npm::Package.count }
              .and not_change { Packages::Tag.count }
              .and not_change { Packages::Npm::Metadatum.count }
          end
        end

        context 'when some of the field sizes are above the error tracking size' do
          let(:package_json) do
            params[:versions][version].except(*::Packages::Npm::CreatePackageService::PACKAGE_JSON_NOT_ALLOWED_FIELDS)
          end

          # Only the fields that exceed the field size limit should be passed to error tracking
          let(:expected_field_sizes) do
            {
              'test' => ('test' * 10000).size,
              'field2' => ('a' * (::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING + 1)).size
            }
          end

          before do
            params[:versions][version][:test] = 'test' * 10000
            params[:versions][version][:field1] =
              'a' * (::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING - 1)
            params[:versions][version][:field2] =
              'a' * (::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING + 1)
          end

          it_behaves_like 'a package json structure size too large error'
        end

        context 'when all of the field sizes are below the error tracking size' do
          let(:package_json) do
            params[:versions][version].except(*::Packages::Npm::CreatePackageService::PACKAGE_JSON_NOT_ALLOWED_FIELDS)
          end

          let(:expected_size) do
            ('a' * (::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING - 1)).size
          end

          # Only the five largest fields should be passed to error tracking
          let(:expected_field_sizes) do
            {
              'field1' => expected_size,
              'field2' => expected_size,
              'field3' => expected_size,
              'field4' => expected_size,
              'field5' => expected_size
            }
          end

          before do
            5.times do |i|
              params[:versions][version]["field#{i + 1}"] =
                'a' * (::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING - 1)
            end
          end

          it_behaves_like 'a package json structure size too large error'
        end
      end

      context 'when the npm metadatum creation results in a different error' do
        it 'does not track the error' do
          error_message = 'boom'
          invalid_npm_metadatum_error = ActiveRecord::RecordInvalid.new(
            build(:npm_metadatum).tap do |metadatum|
              metadatum.errors.add(:base, error_message)
            end
          )

          allow_next_instance_of(::Packages::Npm::Package) do |package|
            allow(package).to receive(:create_npm_metadatum!).and_raise(invalid_npm_metadatum_error)
          end

          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /#{error_message}/)
        end
      end

      described_class::PACKAGE_JSON_NOT_ALLOWED_FIELDS.each do |field|
        context "with not allowed #{field} field" do
          before do
            params[:versions][version][field] = 'test'
          end

          it 'is persisted without the field' do
            expect { subject }
              .to change { Packages::Package.count }.by(1)
              .and change { Packages::Npm::Package.count }.by(1)
              .and change { Packages::Tag.count }.by(1)
              .and change { Packages::Npm::Metadatum.count }.by(1)
            expect(package.npm_metadatum.package_json[field]).to be_blank
          end
        end
      end
    end

    context 'when scoped package' do
      it_behaves_like 'returning a success service response'
      it_behaves_like 'valid package'
    end

    context 'when user is no project member' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'returning an error service response', message: 'Unauthorized'
    end

    context 'when scoped package not following the naming convention' do
      let(:package_name) { '@any-scope/package' }

      it_behaves_like 'returning a success service response'
      it_behaves_like 'valid package'
    end

    context 'when unscoped package' do
      let(:package_name) { 'unscoped-package' }

      it_behaves_like 'returning a success service response'
      it_behaves_like 'valid package'
    end

    context 'when package already exists' do
      let(:package_name) { "@#{namespace.path}/my_package" }
      let!(:existing_package) { create(:npm_package, project: project, name: package_name, version: '1.0.1') }

      it_behaves_like 'returning an error service response', message: 'Package already exists.' do
        it { is_expected.to have_attributes reason: :package_already_exists }
      end

      context 'when marked as pending_destruction' do
        before do
          existing_package.pending_destruction!
        end

        it 'creates a new package' do
          expect { execute_service }
            .to change { Packages::Package.count }.by(1)
            .and change { Packages::Npm::Package.count }.by(1)
            .and change { Packages::Tag.count }.by(1)
            .and change { Packages::Npm::Metadatum.count }.by(1)
        end
      end
    end

    describe 'max file size validation' do
      let(:max_file_size) { 5.bytes }

      shared_examples_for 'max file size validation failure' do
        it_behaves_like 'returning an error service response', message: 'File is too large.' do
          it { is_expected.to have_attributes reason: :invalid_parameter }
        end
      end

      before do
        project.actual_limits.update!(npm_max_file_size: max_file_size)
      end

      context 'when max file size is exceeded' do
        # NOTE: The base64 encoded package data in the fixture file is the "hello\n" string, whose byte size is 6.
        it_behaves_like 'max file size validation failure'
      end

      context 'when file size is faked by setting the attachment length param to a lower size' do
        let(:params) do
          super().deep_merge!(
            _attachments: {
              "#{package_name}-#{version}.tgz" => {
                data: encoded_package_data,
                length: 1
              }
            })
        end

        # TODO (technical debt): Extract the package size calculation outside the service and add separate specs for it.
        # Right now we have several contexts here to test the calculation's different scenarios.
        context 'when encoded package data is not padded' do
          # 'Hello!' (size = 6 bytes) => 'SGVsbG8h'
          let(:encoded_package_data) { 'SGVsbG8h' }

          it_behaves_like 'max file size validation failure'
        end

        context "when encoded package data is padded with '='" do
          let(:max_file_size) { 4.bytes }
          # 'Hello' (size = 5 bytes) => 'SGVsbG8='
          let(:encoded_package_data) { 'SGVsbG8=' }

          it_behaves_like 'max file size validation failure'
        end

        context "when encoded package data is padded with '=='" do
          let(:max_file_size) { 3.bytes }
          # 'Hell' (size = 4 bytes) => 'SGVsbA=='
          let(:encoded_package_data) { 'SGVsbA==' }

          it_behaves_like 'max file size validation failure'
        end
      end
    end

    context 'with invalid name' do
      where(:package_name) do
        [
          '@inv@lid_scope/package',
          '@scope/sub/group',
          '@scope/../../package',
          '@scope%2e%2e%2fpackage'
        ]
      end

      with_them do
        it { expect { execute_service }.to raise_error(ActiveRecord::RecordInvalid) }
      end
    end

    context 'with empty versions' do
      let(:params) { super().merge!({ versions: {} }) }

      it_behaves_like 'returning an error service response', message: 'Version is empty.' do
        it { is_expected.to have_attributes reason: :invalid_parameter }
      end
    end

    context 'with invalid versions' do
      where(:version) do
        [
          '1',
          '1.2',
          '1./2.3',
          '../../../../../1.2.3',
          '%2e%2e%2f1.2.3'
        ]
      end

      with_them do
        it 'raises an error "ActiveRecord::RecordInvalid"' do
          expect { execute_service }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Version #{Gitlab::Regex.semver_regex_message}"
          )
        end
      end
    end

    context 'with empty attachment data' do
      let(:params) { super().merge({ _attachments: { "#{package_name}-#{version}.tgz" => { data: '' } } }) }

      it_behaves_like 'returning an error service response', message: 'Attachment data is empty.' do
        it { is_expected.to have_attributes reason: :invalid_parameter }
      end
    end

    described_class::INSTALL_SCRIPT_KEYS.each do |field|
      context "with script #{field}" do
        let(:package) { subject[:package] }

        before do
          params[:versions][version][:scripts] = { field => "echo 'script #{field}'" }
        end

        it "sets `hasInstallScript` attribute to `true` for package's metadata" do
          execute_service

          expect(package.npm_metadatum.package_json['hasInstallScript']).to eq(true)
        end
      end
    end

    it 'obtains a lease to create a new package' do
      expect_to_obtain_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

      execute_service
    end

    context 'when the lease is already taken' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)
      end

      it_behaves_like 'returning an error service response',
        message: 'Could not obtain package lease. Please try again.' do
        it { is_expected.to have_attributes reason: :package_lease_taken }
      end
    end

    context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :npm, project: project)
      end

      let_it_be(:project_developer) { create(:user, developer_of: project) }
      let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:project_owner) { project.owner }
      let_it_be(:instance_admin) { create(:admin) }

      let(:package_name_pattern_no_match) { "#{package_name}_no_match" }

      before do
        package_protection_rule.update!(package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push)
      end

      shared_examples 'protected package' do
        it_behaves_like 'returning an error service response', message: 'Package protected.' do
          it { is_expected.to have_attributes reason: :package_protected }
        end

        it 'does not create any npm-related package records' do
          expect { subject }
            .to not_change { Packages::Package.count }
            .and not_change { Packages::Npm::Package.count }
            .and not_change { Packages::Tag.count }
            .and not_change { Packages::Npm::Metadatum.count }
        end
      end

      where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
        ref(:package_name)                  | :maintainer | ref(:project_developer)  | 'protected package'
        ref(:package_name)                  | :maintainer | ref(:project_owner)      | 'valid package'
        ref(:package_name)                  | :maintainer | ref(:instance_admin)     | 'valid package'
        ref(:package_name)                  | :owner      | ref(:project_maintainer) | 'protected package'
        ref(:package_name)                  | :owner      | ref(:project_owner)      | 'valid package'
        ref(:package_name)                  | :owner      | ref(:instance_admin)     | 'valid package'
        ref(:package_name)                  | :admin      | ref(:project_owner)      | 'protected package'
        ref(:package_name)                  | :admin      | ref(:instance_admin)     | 'valid package'

        ref(:package_name_pattern_no_match) | :owner      | ref(:project_owner)      | 'valid package'
        ref(:package_name_pattern_no_match) | :admin      | ref(:project_owner)      | 'valid package'
      end

      with_them do
        it_behaves_like params[:shared_examples_name]
      end

      context 'with deploy token' do
        let_it_be(:deploy_token) { create(:deploy_token, :all_scopes, projects: [project]) }
        let_it_be(:user) { nil }

        let(:service) { described_class.new(project, deploy_token, params) }

        where(:package_name_pattern, :minimum_access_level_for_push, :shared_examples_name) do
          ref(:package_name)                  | :maintainer | 'protected package'
          ref(:package_name)                  | :owner      | 'protected package'
          ref(:package_name)                  | :admin      | 'protected package'

          ref(:package_name_pattern_no_match) | :owner      | 'valid package'
        end

        with_them do
          it_behaves_like params[:shared_examples_name]
        end
      end
    end

    describe '#lease_key' do
      subject { service.send(:lease_key) }

      it 'returns an unique key' do
        is_expected.to eq lease_key
      end
    end
  end

  context 'when many of the same packages are created at the same time', :delete do
    let(:namespace) { create(:namespace) }
    let(:project) { create(:project, namespace: namespace) }
    let(:user) { project.owner }

    let(:version) { '1.0.1' }

    let(:params) do
      Gitlab::Json.parse(
        fixture_file('packages/npm/payload.json')
          .gsub('@root/npm-test', package_name)
          .gsub('1.0.1', version)
      ).with_indifferent_access
    end

    let(:package_name) { "@#{namespace.path}/my-app" }
    let(:service) { described_class.new(project, user, params) }

    subject { service.execute }

    it 'only creates one package', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448644' do
      expect { create_packages(project, user, params) }.to change { Packages::Package.count }.by(1)
    end

    context 'with different versions' do
      it 'creates all packages' do
        expect { create_packages_with_versions(project, user, params) }.to change { Packages::Package.count }.by(5)
      end
    end

    def create_packages(project, user, params)
      with_threads do
        described_class.new(project, user, params).execute
      end
    end

    def create_packages_with_versions(project, user, params)
      with_threads do |i|
        # Modify the package's version
        modified_params = Gitlab::Json.parse(params.to_json
          .gsub(version, "1.0.#{i}")).with_indifferent_access

        described_class.new(project, user, modified_params).execute
      end
    end

    def with_threads(count: 5, &block)
      return unless block

      # create a race condition - structure from https://blog.arkency.com/2015/09/testing-race-conditions/
      wait_for_it = true

      threads = Array.new(count) do |i|
        Thread.new do
          # A loop to make threads busy until we `join` them
          true while wait_for_it

          yield(i)
        end
      end

      wait_for_it = false
      threads.each(&:join)
    end
  end
end
