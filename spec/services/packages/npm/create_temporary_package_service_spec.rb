# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CreateTemporaryPackageService, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  describe '#execute', :aggregate_failures do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { project.owner }
    let_it_be(:package_name) { FFaker::Lorem.word }
    let_it_be(:uuid) { SecureRandom.uuid }
    let_it_be(:version) { "0.0.0-#{uuid}" }

    let(:fixture_file_content) { fixture_file('packages/npm/payload.json').gsub('@root/npm-test', package_name) }
    let(:sha1) { Digest::SHA1.hexdigest(fixture_file_content) } # rubocop:disable Fips/SHA1 -- npm uses SHA-1 hash
    let(:file) { temp_file('test-npm-upload', content: fixture_file_content, sha1: sha1) }
    let(:deprecate) { true }
    let(:params) { { package_name:, file:, deprecate: } }

    subject(:execute) { described_class.new(project, user, params).execute }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
    end

    shared_examples 'does not create new records' do
      it 'does not create new records' do
        expect { subject }
          .to not_change { Packages::Npm::Package.count }
          .and not_change { Packages::PackageFile.count }
      end
    end

    it 'creates temporary npm package and returns a success response with payload' do
      expect { execute }
        .to change { Packages::Npm::Package.count }.from(0).to(1)

      is_expected.to be_success.and have_attributes(
        payload: {
          package: have_attributes(
            name: package_name,
            version: version,
            status: 'processing',
            package_type: 'npm'
          )
        }
      )
    end

    it 'creates package file' do
      expect { execute }
        .to change { Packages::PackageFile.count }.from(0).to(1)

      package_file = execute.payload[:package].package_files.first

      expect(package_file).to have_attributes(
        file_name: "#{package_name}-#{version}.json",
        file_sha1: sha1,
        size: file.size,
        status: 'processing'
      )

      expect(package_file.file.content_type).to eq(described_class::CONTENT_TYPE)
    end

    it 'enqueues process temporary file worker', :sidekiq_inline do
      expect(::Packages::Npm::ProcessTemporaryPackageFileWorker).to receive(:perform_async)
        .with(user.id, an_instance_of(Integer), deprecate)
        .and_call_original

      execute
    end

    context 'with CI job' do
      let_it_be(:job) { create(:ci_build, user: user) }

      let(:params) { super().merge(build: job) }

      it 'saves CI job information' do
        expect { execute }
          .to change { Packages::BuildInfo.count }.from(0).to(1)
          .and change { Packages::PackageFileBuildInfo.count }.from(0).to(1)

        package = execute.payload[:package]

        expect(package.build_infos).to be_present
        expect(package.package_files.first.package_file_build_infos).to be_present
      end
    end

    context 'with invalid parameter' do
      let_it_be(:package_name) { '' }

      it_behaves_like 'does not create new records'

      it_behaves_like 'returning an error service response',
        message: "Validation failed: Name can't be blank, Name should be a valid NPM package name: " \
          'https://github.com/npm/validate-npm-package-name#naming-rules.',
        reason: :invalid_parameter
    end

    context 'with existing package' do
      let_it_be(:package) { create(:npm_package, project: project, name: package_name, version: version) }

      it_behaves_like 'does not create new records'

      it_behaves_like 'returning an error service response',
        message: 'Validation failed: Name has already been taken', reason: :name_taken
    end

    context 'when user does not have permissions to create a package' do
      let_it_be(:user) { create(:user, reporter_of: project) }

      it_behaves_like 'does not create new records'

      it_behaves_like 'returning an error service response',
        message: 'Unauthorized', reason: :unauthorized
    end

    context 'when package is protected' do
      let_it_be(:user) { create(:user, developer_of: project) }

      let_it_be(:package_protection_rule) do
        create(
          :package_protection_rule,
          package_type: :npm,
          project: project,
          package_name_pattern: package_name,
          minimum_access_level_for_push: :maintainer
        )
      end

      it_behaves_like 'does not create new records'

      it_behaves_like 'returning an error service response',
        message: 'Package protected.', reason: :package_protected
    end
  end
end
