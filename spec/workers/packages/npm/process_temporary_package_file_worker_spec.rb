# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::ProcessTemporaryPackageFileWorker, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:package_name) { FFaker::Lorem.word }

  let_it_be(:package) do
    create(:npm_package, name: package_name, version: '1.0.1', project: project).tap do |package|
      create(:npm_metadatum, package: package)
    end
  end

  let_it_be(:temp_package) do
    create(:npm_package, :processing, name: package_name, version: "0.0.0-#{SecureRandom.uuid}",
      package_files: [], project: project)
  end

  let(:deprecate) { true }
  let(:params) { { deprecate: } }

  let(:json_doc) do
    Gitlab::Json.parse(fixture_file('packages/npm/deprecate_payload.json')
      .gsub('@root/npm-test', package_name))
  end

  let!(:file) { temp_file('payload', content: json_doc.to_json) }
  let!(:package_file) { create(:package_file, :processing, file: file, package: temp_package, file_fixture: nil) }

  describe '#peform' do
    subject(:worker) { described_class.new }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [user.id, package_file.id, deprecate] }
    end

    context 'when deprecating packages' do
      it 'deprecates package' do
        expect { worker.perform(user.id, package_file.id, deprecate) }
          .to change {
            package.reload.npm_metadatum.package_json['deprecated']
          }.to('This version is deprecated')
          .and change { package.status }.from('default').to('deprecated')
      end
    end

    context 'when creating a new package' do
      let(:version) { '1.0.0' }

      let(:json_doc) do
        Gitlab::Json.parse(fixture_file('packages/npm/payload.json')
          .gsub('@root/npm-test', package_name).gsub('1.0.1', version))
      end

      let(:data) { Base64.decode64(json_doc['_attachments']["#{package_name}-#{version}.tgz"]['data']) }
      let(:deprecate) { false }

      it 'creates a new npm package from temporary package', :aggregate_failures do
        expect(::Packages::Npm::ProcessPackageFileWorker).to receive(:perform_async).once

        expect { worker.perform(user.id, package_file.id, deprecate) }
          .to change { Packages::Tag.count }.by(1)
          .and change { Packages::Npm::Metadatum.count }.by(1)
          .and change { Packages::Dependency.count }.by(1)
          .and change { Packages::DependencyLink.count }.by(1)

        expect(temp_package.reload.version).to eq(version)

        expect(package_file.reload).to have_attributes(
          size: data.size,
          file_sha1: json_doc['versions'][version]['dist']['shasum'],
          file_name: "#{package_name}-#{version}.tgz",
          status: 'default'
        )

        expect(package_file.file.read).to eq(data)
      end
    end

    context 'with a non-existing package file' do
      it 'does not call the service' do
        expect(::Packages::Npm::ProcessTemporaryPackageFileService).not_to receive(:new)

        worker.perform(user.id, non_existing_record_id, deprecate)
      end
    end

    context 'when a package file is not in the processing status' do
      before do
        package_file.update_column(:status, :default)
      end

      it 'does not call the service' do
        expect(::Packages::Npm::ProcessTemporaryPackageFileService).not_to receive(:new)

        worker.perform(user.id, package_file.id, deprecate)
      end
    end

    context 'with a non-existing user' do
      it 'does not call the service' do
        expect(::Packages::Npm::ProcessTemporaryPackageFileService).not_to receive(:new)

        worker.perform(non_existing_record_id, package_file.id, deprecate)
      end
    end

    context 'when the process temporary package file service errored' do
      let(:deprecate) { false }
      let(:message) { 'Attachment data is empty.' }

      before do
        allow_next_instance_of(
          ::Packages::Npm::CreatePackageService, project, user, a_kind_of(Hash)
        ) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: message, reason: :invalid_parameter)
          )
        end
      end

      it 'logs the error and updates package status to error' do
        worker.perform(user.id, package_file.id, deprecate)

        expect(temp_package.reload).to have_attributes(
          status: 'error',
          status_message: message
        )
      end
    end

    context 'with an exception' do
      let(:exception) { StandardError.new('error') }

      before do
        allow_next_instance_of(
          ::Packages::Npm::ProcessTemporaryPackageFileService, package_file:, user:, params:
        ) do |service|
          allow(service).to receive(:execute).and_raise(exception)
        end
      end

      it 'processes the error' do
        expect(worker).to receive(:process_package_file_error).with(
          package_file: package_file,
          exception: exception
        )

        worker.perform(user.id, package_file.id, deprecate)
      end
    end

    context 'with the error when fetching a package file' do
      let(:exception) { ActiveRecord::QueryCanceled.new('ERROR: canceling statement due to statement timeout') }

      before do
        allow(::Packages::PackageFile).to receive(:find_by_id).with(package_file.id).and_raise(exception)
      end

      it 'raises the error' do
        expect { worker.perform(user.id, package_file.id, deprecate) }.to raise_error(exception.class)
      end
    end
  end
end
