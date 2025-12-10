# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::CreatePackageFileService, feature_category: :package_registry do
  include WorkhorseHelpers

  let_it_be(:package) { create(:debian_incoming, without_package_files: true) }
  let_it_be(:current_user) { create(:user) }

  describe '#execute' do
    let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }
    let(:fixture_path) { "spec/fixtures/packages/debian/#{file_name}" }
    let(:params) { default_params }

    let(:default_params) do
      {
        file: file,
        file_name: file_name,
        file_sha1: '54321',
        file_md5: '12345'
      }.with_indifferent_access
    end

    let(:service) { described_class.new(package: package, current_user: current_user, params: params) }

    subject(:package_file) { service.execute }

    shared_examples 'a valid deb' do |process_package_file_worker|
      it 'creates a new package file', :aggregate_failures do
        if process_package_file_worker
          expect(::Packages::Debian::ProcessPackageFileWorker)
            .to receive(:perform_async).with(an_instance_of(Integer), params[:distribution], params[:component])
        else
          expect(::Packages::Debian::ProcessPackageFileWorker).not_to receive(:perform_async)
        end

        is_expected.to be_valid.and have_attributes(
          file: satisfy { |f| f.read.starts_with?('!<arch>') },
          size: 1124,
          file_name: file_name,
          file_sha1: '54321',
          file_sha256: '543212345',
          file_md5: '12345',
          project_id: package.project_id,
          debian_file_metadatum: be_valid.and(have_attributes(
            file_type: 'unknown',
            architecture: nil,
            fields: nil
          ))
        )
      end
    end

    shared_examples 'a valid changes' do
      it 'creates a new package file', :aggregate_failures do
        expect(::Packages::Debian::ProcessPackageFileWorker)
        .to receive(:perform_async).with(an_instance_of(Integer), nil, nil)

        is_expected.to be_valid.and have_attributes(
          file: satisfy { |f| f.read.starts_with?('Format: 1.8') },
          size: 2422,
          file_name: file_name,
          file_sha1: '54321',
          file_sha256: '543212345',
          file_md5: '12345',
          project_id: package.project_id,
          debian_file_metadatum: be_valid.and(have_attributes(
            file_type: 'unknown',
            architecture: nil,
            fields: nil
          ))
        )
      end
    end

    context 'with temp file' do
      let!(:file) do
        upload_path = ::Packages::PackageFileUploader.workhorse_local_upload_path
        file_path = upload_path + '/' + file_name

        FileUtils.mkdir_p(upload_path)
        File.write(file_path, File.read(fixture_path))

        UploadedFile.new(file_path, filename: File.basename(file_path), sha256: '543212345')
      end

      it_behaves_like 'a valid deb'

      context 'with a .changes file' do
        let(:file_name) { 'sample_1.2.3~alpha2_amd64.changes' }
        let(:fixture_path) { "spec/fixtures/packages/debian/#{file_name}" }

        it_behaves_like 'a valid changes'
      end

      context 'with distribution' do
        let(:params) { default_params.merge(distribution: 'unstable', component: 'main') }

        it_behaves_like 'a valid deb', true
      end

      context 'when current_user is missing' do
        let(:current_user) { nil }

        it 'raises an error' do
          expect { package_file }.to raise_error(ArgumentError, 'Invalid user')
        end
      end
    end

    context 'with remote file' do
      before do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:sha256).and_return('543212345')
        end
      end

      let!(:fog_connection) do
        stub_package_file_object_storage(direct_upload: true)
      end

      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang
          key: "tmp/uploads/#{file_name}",
          body: File.read(fixture_path)
        )
      end

      let!(:file) { fog_to_uploaded_file(tmp_object) }

      it_behaves_like 'a valid deb'
    end

    context 'when package is missing' do
      let(:package) { nil }
      let(:params) { {} }

      it 'raises an error' do
        expect { package_file }.to raise_error(ArgumentError, 'Invalid package')
      end
    end

    context 'when params is empty' do
      let(:params) { {} }

      it 'raises an error' do
        expect { package_file }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when file is missing' do
      let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }
      let(:file) { nil }

      it 'raises an error' do
        expect { package_file }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
