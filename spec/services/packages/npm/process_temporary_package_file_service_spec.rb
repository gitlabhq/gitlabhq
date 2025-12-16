# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::ProcessTemporaryPackageFileService, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:package_name) { FFaker::Lorem.word }

  let_it_be(:package) do
    create(:npm_package, name: package_name, version: '1.0.1', project: project).tap do |package|
      create(:npm_metadatum, package: package)
    end
  end

  let_it_be_with_reload(:temp_package) do
    create(:npm_package, :processing, name: package_name, version: "0.0.0-#{SecureRandom.uuid}",
      package_files: [], project: project)
  end

  let(:json_doc) do
    Gitlab::Json.parse(fixture_file('packages/npm/deprecate_payload.json')
      .gsub('@root/npm-test', package_name))
  end

  let(:content) { json_doc.to_json }
  let!(:file) { temp_file('payload', content:) }
  let!(:package_file) { create(:package_file, :processing, file: file, package: temp_package, file_fixture: nil) }

  let(:json_doc_filtered) do
    json_doc.deep_dup.tap { |p| p['versions'].slice!('1.0.1') }
  end

  let(:deprecate) { true }
  let(:params) { { deprecate: } }

  describe '#execute', :aggregate_failures do
    subject(:execute) { described_class.new(package_file:, user:, params:).execute }

    context 'when deprecating packages' do
      it 'deprecates package' do
        expect { execute }
          .to change {
            package.reload.npm_metadatum.package_json['deprecated']
          }.to('This version is deprecated')
          .and change { package.status }.from('default').to('deprecated')
      end

      it 'marks temporary package for destruction' do
        expect { execute }
          .to change { temp_package.status }.from('processing').to('pending_destruction')
      end

      context 'when missing versions' do
        let(:json_doc) { super().slice('package_name') }

        it 'returns error' do
          expect(execute).to be_error.and have_attributes(
            message: 'Missing versions',
            reason: :missing_versions
          )
        end
      end

      context 'when user does not have permissions to create a package' do
        let_it_be(:user) { create(:user, reporter_of: project) }

        it 'returns error' do
          expect(execute).to be_error.and have_attributes(
            message: 'Unauthorized',
            reason: :unauthorized
          )
        end
      end

      context 'when missing deprecated versions' do
        let(:json_doc) { super().tap { |h| h['versions'].slice!('1.0.2') } }

        it 'returns error' do
          expect(execute).to be_error.and have_attributes(
            message: 'Missing deprecated versions',
            reason: :missing_deprecated_versions
          )
        end
      end

      context 'when the deprecate package service returns the error' do
        let(:message) { 'Error' }
        let(:reason) { :error }

        before do
          allow_next_instance_of(
            ::Packages::Npm::DeprecatePackageService, project, a_kind_of(Hash)
          ) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message:, reason:)
            )
          end
        end

        it 'returns error' do
          expect(execute).to be_error.and have_attributes(message:, reason:)
        end
      end

      context 'when mark package for destruction service raises error' do
        it 'returns error' do
          expect(temp_package).to receive(:pending_destruction!).and_raise(StandardError)
          expect(execute).to be_error.and have_attributes(
            message: 'Failed to mark the package as pending destruction'
          )
        end
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

      it 'creates a new npm package from temporary package' do
        expect(::Packages::Npm::ProcessPackageFileWorker).to receive(:perform_async).once

        expect { execute }
          .to change { Packages::Tag.count }.by(1)
          .and change { Packages::Npm::Metadatum.count }.by(1)
          .and change { Packages::Dependency.count }.by(1)
          .and change { Packages::DependencyLink.count }.by(1)

        expect(temp_package.version).to eq(version)

        expect(package_file.reload).to have_attributes(
          size: data.size,
          file_sha1: json_doc['versions'][version]['dist']['shasum'],
          file_name: "#{package_name}-#{version}.tgz",
          status: 'default'
        )

        expect(package_file.file.read).to eq(data)
      end
    end

    context 'when JSON parser error' do
      let(:content) { '{ name": "package-name"}' }

      it 'returns error' do
        expect(execute).to be_error.and have_attributes(
          message: "not a number or other value (after ) at line 1, " \
            "column 2 [parse.c:480] in '{ name\": \"package-name\"}",
          reason: :json_parser_error
        )
      end
    end
  end
end
