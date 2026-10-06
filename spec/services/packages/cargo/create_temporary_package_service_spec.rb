# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::CreateTemporaryPackageService, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers
  include HttpIOHelpers
  include WorkhorseHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:deploy_token) { create(:deploy_token, projects: [project], write_package_registry: true) }

  let(:file) { temp_file('cargo-publish-body', content: 'publish body') }
  let(:current_user) { user }
  let(:params) { { file: file } }

  subject(:execute) { described_class.new(project, current_user, params).execute }

  def publish_body(name:, vers: '1.0.0', crate: 'crate bytes')
    json = Gitlab::Json.dump({ name: name, vers: vers })

    [json.bytesize].pack('L<') + json + [crate.bytesize].pack('L<') + crate
  end

  shared_examples 'refusing before creating anything' do |reason:|
    it 'refuses before creating anything', :aggregate_failures do
      expect { execute }
        .to not_change { ::Packages::Cargo::Package.for_projects(project).count }
        .and not_change { ::Packages::PackageFile.count }
        .and not_change { ::Packages::Cargo::ExtractionWorker.jobs.size }

      expect(execute).to be_error
      expect(execute.reason).to eq(reason)
    end
  end

  describe '#execute' do
    it 'creates a processing package with the raw body attached', :aggregate_failures do
      expect { execute }
        .to change { ::Packages::Cargo::Package.for_projects(project).count }.by(1)
        .and change { ::Packages::PackageFile.count }.by(1)

      expect(execute).to be_success

      package = execute.payload[:package]

      expect(package).to have_attributes(
        name: ::Packages::Cargo::TEMPORARY_PACKAGE_NAME,
        status: 'processing'
      )
      expect(package.version).to match(/\A0\.0\.0-/)
      expect(package).to be_valid
      expect(package.package_files.last).to have_attributes(
        file_name: described_class::PACKAGE_FILE_NAME,
        status: 'default'
      )
    end

    it 'enqueues the extraction worker with the user as the actor', :aggregate_failures do
      execute

      package_file = ::Packages::PackageFile.last
      args = ::Packages::Cargo::ExtractionWorker.jobs.last['args']

      expect(args).to eq([package_file.id, { 'user_id' => user.id }])
      expect([args.last]).to param_containing_valid_native_json_types
    end

    context 'with a deploy token' do
      let(:current_user) { deploy_token }

      it 'enqueues the extraction worker with the deploy token as the actor', :aggregate_failures do
        expect(execute).to be_success
        expect(execute.payload[:package].creator).to be_nil
        expect(::Packages::Cargo::ExtractionWorker.jobs.last['args'].last)
          .to eq({ 'deploy_token_id' => deploy_token.id })
      end
    end

    context 'with a build' do
      let_it_be(:build) { create(:ci_build, :running, project: project, user: user) }

      let(:params) { { file: file, build: build } }

      it 'links the package and the package file to the pipeline', :aggregate_failures do
        package = execute.payload[:package]

        expect(package.build_infos.last.pipeline).to eq(build.pipeline)
        expect(package.package_files.last.package_file_build_infos.last.pipeline).to eq(build.pipeline)
      end
    end

    context 'when the crate name is protected' do
      let_it_be(:protection_rule) do
        create(:package_protection_rule, project: project, package_type: :cargo,
          package_name_pattern: 'protected-crate', minimum_access_level_for_push: :owner)
      end

      let(:file) { temp_file('cargo-publish-body', content: publish_body(name: 'protected-crate')) }

      it_behaves_like 'refusing before creating anything', reason: :package_protected
    end

    context 'when the crate version already exists' do
      let_it_be(:existing_package) do
        create(:cargo_package, project: project, name: 'existing-crate', version: '1.0.0')
      end

      let_it_be(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

      let(:file) { temp_file('cargo-publish-body', content: publish_body(name: 'existing-crate')) }

      it_behaves_like 'refusing before creating anything', reason: :package_already_exists

      context 'with a different version' do
        let(:file) { temp_file('cargo-publish-body', content: publish_body(name: 'existing-crate', vers: '1.0.1')) }

        it 'creates the package' do
          expect { execute }.to change { ::Packages::Cargo::Package.for_projects(project).count }.by(1)
        end
      end
    end

    context 'when the body was uploaded directly to object storage' do
      let_it_be(:protection_rule) do
        create(:package_protection_rule, project: project, package_type: :cargo,
          package_name_pattern: 'protected-crate', minimum_access_level_for_push: :owner)
      end

      # Several HttpIO chunks long, so reading past the first chunk would show up.
      let(:body) { publish_body(name: 'protected-crate', crate: 'x' * (3 * Gitlab::HttpIO::BUFFER_SIZE)) }
      let(:local_copy) { temp_file('cargo-publish-body-local', content: body) }

      let!(:fog_connection) { stub_package_file_object_storage(direct_upload: true) }

      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang -- Fog's create, not ActiveRecord's
          key: 'tmp/uploads/cargo-publish-body',
          body: body
        )
      end

      let(:file) { fog_to_uploaded_file(tmp_object) }

      before do
        stub_remote_url_206(%r{tmp/uploads/cargo-publish-body}, local_copy.path)
      end

      it_behaves_like 'refusing before creating anything', reason: :package_protected

      it 'reads only the first chunk of the body' do
        execute

        expect(WebMock).to have_requested(:get, %r{tmp/uploads/cargo-publish-body})
          .with(headers: { 'Range' => "bytes=0-#{Gitlab::HttpIO::BUFFER_SIZE - 1}" }).once
        expect(WebMock).to have_requested(:get, %r{tmp/uploads/cargo-publish-body}).once
      end

      context 'when the object storage read fails' do
        before do
          stub_remote_url_500(%r{tmp/uploads/cargo-publish-body})
        end

        it 'leaves the checks to the worker and creates the package' do
          expect { execute }.to change { ::Packages::Cargo::Package.for_projects(project).count }.by(1)
        end
      end
    end

    context 'when the metadata has no crate name' do
      let(:file) do
        json = Gitlab::Json.dump({ vers: '1.0.0' })
        temp_file('cargo-publish-body', content: [json.bytesize].pack('L<') + json)
      end

      it 'leaves the name check to the worker and creates the package' do
        expect { execute }.to change { ::Packages::Cargo::Package.for_projects(project).count }.by(1)
      end
    end

    context 'when the metadata has a non-string name or version' do
      where(:name, :vers) do
        1             | '1.0.0'
        'test-crate'  | 1
        ['a']         | '1.0.0'
        'test-crate'  | { 'a' => 1 }
      end

      with_them do
        let(:file) { temp_file('cargo-publish-body', content: publish_body(name: name, vers: vers)) }

        it 'leaves the metadata checks to the worker and creates the package', :aggregate_failures do
          expect { execute }
            .to change { ::Packages::Cargo::Package.for_projects(project).count }.by(1)
            .and change { ::Packages::Cargo::ExtractionWorker.jobs.size }.by(1)

          expect(execute).to be_success
        end
      end
    end

    context 'when the user cannot create a package' do
      let(:current_user) { create(:user, reporter_of: project) }

      it 'returns an unauthorized error and creates nothing', :aggregate_failures do
        expect { execute }
          .to not_change { ::Packages::Cargo::Package.for_projects(project).count }
          .and not_change { ::Packages::PackageFile.count }
          .and not_change { ::Packages::Cargo::ExtractionWorker.jobs.size }

        expect(execute).to be_error
        expect(execute.reason).to eq(:unauthorized)
        expect(execute.message).to eq('Unauthorized')
      end
    end

    context 'when the deploy token cannot write to the package registry' do
      let(:current_user) { create(:deploy_token, projects: [project], write_package_registry: false) }

      it 'returns an unauthorized error and creates nothing', :aggregate_failures do
        expect { execute }
          .to not_change { ::Packages::Cargo::Package.for_projects(project).count }
          .and not_change { ::Packages::Cargo::ExtractionWorker.jobs.size }

        expect(execute).to be_error
        expect(execute.reason).to eq(:unauthorized)
      end
    end

    context 'when the package is invalid' do
      before do
        allow(::Packages::Cargo).to receive(:const_get).and_call_original
        stub_const('Packages::Cargo::TEMPORARY_PACKAGE_NAME', '1-invalid-cargo-name')
      end

      it 'returns an error response and creates nothing', :aggregate_failures do
        expect { execute }
          .to not_change { ::Packages::Cargo::Package.for_projects(project).count }
          .and not_change { ::Packages::PackageFile.count }

        expect(execute).to be_error
        expect(execute.reason).to eq(:invalid_parameter)
        expect(execute.message).to include('must be a valid cargo package name')
      end

      it 'does not enqueue the extraction worker' do
        expect { execute }.not_to change { ::Packages::Cargo::ExtractionWorker.jobs.size }
      end
    end
  end
end
