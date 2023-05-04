# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Npm::CreatePackageService, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let(:namespace) { create(:namespace) }
  let(:project) { create(:project, namespace: namespace) }
  let(:user) { create(:user) }
  let(:version) { '1.0.1' }

  let(:params) do
    Gitlab::Json.parse(fixture_file('packages/npm/payload.json')
        .gsub('@root/npm-test', package_name)
        .gsub('1.0.1', version)).with_indifferent_access
  end

  let(:package_name) { "@#{namespace.path}/my-app" }
  let(:version_data) { params.dig('versions', version) }
  let(:lease_key) { "packages:npm:create_package_service:packages:#{project.id}_#{package_name}_#{version}" }
  let(:service) { described_class.new(project, user, params) }

  subject { service.execute }

  shared_examples 'valid package' do
    it 'creates a package' do
      expect { subject }
        .to change { Packages::Package.count }.by(1)
        .and change { Packages::Package.npm.count }.by(1)
        .and change { Packages::Tag.count }.by(1)
        .and change { Packages::Npm::Metadatum.count }.by(1)
    end

    it_behaves_like 'assigns the package creator' do
      let(:package) { subject }
    end

    it { is_expected.to be_valid }

    it 'creates a package with name and version' do
      package = subject

      expect(package.name).to eq(package_name)
      expect(package.version).to eq(version)
    end

    it { expect(subject.npm_metadatum.package_json).to eq(version_data) }

    it { expect(subject.name).to eq(package_name) }
    it { expect(subject.version).to eq(version) }

    context 'with build info' do
      let(:job) { create(:ci_build, user: user) }
      let(:params) { super().merge(build: job) }

      it_behaves_like 'assigns build to package'
      it_behaves_like 'assigns status to package'

      it 'creates a package file build info' do
        expect { subject }.to change { Packages::PackageFileBuildInfo.count }.by(1)
      end
    end

    context 'when the npm metadatum creation results in a size error' do
      shared_examples 'a package json structure size too large error' do
        it 'does not create the package' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(ActiveRecord::RecordInvalid),
            field_sizes: expected_field_sizes
          )

          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package json structure is too large')
            .and not_change { Packages::Package.count }
            .and not_change { Packages::Package.npm.count }
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

        let(:expected_size) { ('a' * (::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING - 1)).size }
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

        allow_next_instance_of(::Packages::Package) do |package|
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
            .and change { Packages::Package.npm.count }.by(1)
            .and change { Packages::Tag.count }.by(1)
            .and change { Packages::Npm::Metadatum.count }.by(1)
          expect(subject.npm_metadatum.package_json[field]).to be_blank
        end
      end
    end
  end

  describe '#execute' do
    context 'scoped package' do
      it_behaves_like 'valid package'
    end

    context 'scoped package not following the naming convention' do
      let(:package_name) { '@any-scope/package' }

      it_behaves_like 'valid package'
    end

    context 'unscoped package' do
      let(:package_name) { 'unscoped-package' }

      it_behaves_like 'valid package'
    end

    context 'package already exists' do
      let(:package_name) { "@#{namespace.path}/my_package" }
      let!(:existing_package) { create(:npm_package, project: project, name: package_name, version: '1.0.1') }

      it { expect(subject[:http_status]).to eq 403 }
      it { expect(subject[:message]).to be 'Package already exists.' }

      context 'marked as pending_destruction' do
        before do
          existing_package.pending_destruction!
        end

        it 'creates a new package' do
          expect { subject }
            .to change { Packages::Package.count }.by(1)
            .and change { Packages::Package.npm.count }.by(1)
            .and change { Packages::Tag.count }.by(1)
            .and change { Packages::Npm::Metadatum.count }.by(1)
        end
      end
    end

    describe 'max file size validation' do
      let(:max_file_size) { 5.bytes }

      shared_examples_for 'max file size validation failure' do
        it 'returns a 400 error', :aggregate_failures do
          expect(subject[:http_status]).to eq 400
          expect(subject[:message]).to be 'File is too large.'
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
        let(:params) { super().deep_merge!({ _attachments: { "#{package_name}-#{version}.tgz" => { data: encoded_package_data, length: 1 } } }) }

        # TODO (technical debt): Extract the package size calculation outside the service and add separate specs for it.
        # Right now we have several contexts here to test the calculation's different scenarios.
        context "when encoded package data is not padded" do
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

    [
      '@inv@lid_scope/package',
      '@scope/sub/group',
      '@scope/../../package',
      '@scope%2e%2e%2fpackage'
    ].each do |invalid_package_name|
      context "with invalid name #{invalid_package_name}" do
        let(:package_name) { invalid_package_name }

        it 'raises a RecordInvalid error' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'with empty versions' do
      let(:params) { super().merge!({ versions: {} }) }

      it { expect(subject[:http_status]).to eq 400 }
      it { expect(subject[:message]).to eq 'Version is empty.' }
    end

    context 'with invalid versions' do
      using RSpec::Parameterized::TableSyntax

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
        it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Version is invalid') }
      end
    end

    context 'with empty attachment data' do
      let(:params) { super().merge({ _attachments: { "#{package_name}-#{version}.tgz" => { data: '' } } }) }

      it { expect(subject[:http_status]).to eq 400 }
      it { expect(subject[:message]).to eq 'Attachment data is empty.' }
    end

    it 'obtains a lease to create a new package' do
      expect_to_obtain_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

      subject
    end

    context 'when the lease is already taken' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)
      end

      it { expect(subject[:http_status]).to eq 400 }
      it { expect(subject[:message]).to eq 'Could not obtain package lease.' }
    end

    context 'when many of the same packages are created at the same time', :delete do
      it 'only creates one package' do
        expect { create_packages(project, user, params) }.to change { Packages::Package.count }.by(1)
      end
    end

    context 'when many packages with different versions are created at the same time', :delete do
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

  describe '#lease_key' do
    subject { service.send(:lease_key) }

    it 'returns an unique key' do
      is_expected.to eq lease_key
    end
  end
end
