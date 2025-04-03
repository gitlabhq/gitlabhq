# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Conan::CreatePackageFileService, feature_category: :package_registry do
  include WorkhorseHelpers

  let_it_be(:package) { create(:conan_package, without_package_files: true) }
  let_it_be(:user) { create(:user) }

  describe '#execute', :aggregate_failures do
    let(:file_name) { 'foo.tgz' }
    let(:conan_package_reference) { '1234567890abcdef1234567890abcdef12345678' }
    let(:recipe_revision) { OpenSSL::Digest.hexdigest('MD5', 'recipe_revision') }
    let(:package_revision) { OpenSSL::Digest.hexdigest('MD5', 'package_revision') }

    subject(:response) { described_class.new(package, file, params).execute }

    shared_examples 'creating package file' do
      it 'creates a new package file with expected attributes' do
        expect(response).to be_success
        package_file = response[:package_file]

        expect(package_file).to be_valid
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.file_md5).to eq('12345')
        expect(package_file.size).to eq(128)
        expect(package_file.conan_file_metadatum).to be_valid
        expect(package_file.conan_file_metadatum.conan_file_type).to eq(conan_file_type)
        expect(package_file.file.read).to eq('content')

        expect(package_file.conan_file_metadatum.recipe_revision_value).to eq(params[:recipe_revision])
        expect(package_file.conan_file_metadatum.package_revision_value).to eq(params[:package_revision])
        expect(package_file.conan_file_metadatum.package_reference_value).to eq(params[:conan_package_reference])
      end

      context 'with default revision' do
        let(:recipe_revision) { ::Packages::Conan::FileMetadatum::DEFAULT_REVISION }
        let(:package_revision) { ::Packages::Conan::FileMetadatum::DEFAULT_REVISION }

        it 'does not create recipe and package revision' do
          package_file = response[:package_file]

          expect(package_file.conan_file_metadatum.recipe_revision).to be_nil
          expect(package_file.conan_file_metadatum.package_revision).to be_nil
        end
      end

      it_behaves_like 'assigns build to package file' do
        subject(:package_file) { response[:package_file] }
      end
    end

    shared_context 'with recipe file parameters' do
      let(:conan_file_type) { 'recipe_file' }
      let(:params) do
        {
          file_name: file_name,
          'file.md5': '12345',
          'file.sha1': '54321',
          'file.size': '128',
          'file.type': 'txt',
          recipe_revision: recipe_revision,
          conan_file_type: :recipe_file
        }.with_indifferent_access
      end
    end

    shared_context 'with package file parameters' do
      let(:conan_file_type) { 'package_file' }
      let(:params) do
        {
          file_name: file_name,
          'file.md5': '12345',
          'file.sha1': '54321',
          'file.size': '128',
          'file.type': 'txt',
          recipe_revision: recipe_revision,
          package_revision: package_revision,
          conan_package_reference: conan_package_reference,
          conan_file_type: :package_file
        }.with_indifferent_access
      end
    end

    shared_context 'with temp file setup' do
      let!(:file) do
        upload_path = ::Packages::PackageFileUploader.workhorse_local_upload_path
        file_path = upload_path + '/' + file_name

        FileUtils.mkdir_p(upload_path)
        File.write(file_path, 'content')

        UploadedFile.new(file_path, filename: File.basename(file_path))
      end

      before do
        allow_any_instance_of(Packages::PackageFileUploader).to receive(:size).and_return(128)
      end
    end

    context 'with temp file' do
      include_context 'with temp file setup'

      context 'with recipe file' do
        include_context 'with recipe file parameters'
        it_behaves_like 'creating package file'
      end

      context 'with package file' do
        include_context 'with package file parameters'
        it_behaves_like 'creating package file'
      end
    end

    context 'with remote file' do
      let!(:fog_connection) do
        stub_package_file_object_storage(direct_upload: true)
      end

      before do
        allow_any_instance_of(Packages::PackageFileUploader).to receive(:size).and_return(128)
      end

      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang
          key: "tmp/uploads/#{file_name}",
          body: 'content'
        )
      end

      let(:file) { fog_to_uploaded_file(tmp_object) }

      context 'with recipe file' do
        include_context 'with recipe file parameters'
        it_behaves_like 'creating package file'
      end

      context 'with package file' do
        include_context 'with package file parameters'
        it_behaves_like 'creating package file'
      end
    end

    context 'file is missing' do
      let(:file) { nil }

      context 'with recipe_file' do
        let(:params) do
          {
            file_name: file_name,
            recipe_revision: recipe_revision,
            conan_file_type: :recipe_file
          }
        end

        it 'returns an error response' do
          response = subject

          expect(response).to be_error
          expect(response.message).to eq('Validation failed: File can\'t be blank')
          expect(response.reason).to eq(:invalid_package_file)
          expect { response }.not_to change { Packages::PackageFile.count }
          expect { response }.not_to change { Packages::Conan::FileMetadatum.count }
        end
      end

      context 'with package_file' do
        let(:params) do
          {
            file_name: file_name,
            package_revision: package_revision,
            recipe_revision: recipe_revision,
            conan_file_type: :package_file,
            conan_package_reference: conan_package_reference
          }
        end

        it 'returns an error response' do
          response = subject

          expect(response).to be_error
          expect(response.message).to eq('Validation failed: File can\'t be blank')
          expect(response.reason).to eq(:invalid_package_file)
          expect { response }.not_to change { Packages::PackageFile.count }
          expect { response }.not_to change { Packages::Conan::FileMetadatum.count }
          expect { response }.not_to change { Packages::Conan::PackageReference.count }
          expect { response }.not_to change { Packages::Conan::PackageRevision.count }
        end
      end
    end

    context 'when an invalid conan package reference is provided' do
      include_context 'with temp file setup'

      let(:params) do
        {
          file_name: file_name,
          'file.md5': '12345',
          'file.sha1': '54321',
          'file.size': '128',
          'file.type': 'txt',
          recipe_revision: recipe_revision,
          package_revision: package_revision,
          conan_package_reference: 'invalid_reference',
          conan_file_type: :package_file
        }.with_indifferent_access
      end

      it 'returns an error response and does not create a package file' do
        response = subject

        expect(response).to be_error
        expect(response.message).to include('Validation failed: Reference is invalid')
        expect(response.reason).to eq(:invalid_package_file)
        expect { response }.not_to change { Packages::PackageFile.count }
        expect { response }.not_to change { Packages::Conan::FileMetadatum.count }
        expect { response }.not_to change { Packages::Conan::PackageReference.count }
        expect { response }.not_to change { Packages::Conan::PackageRevision.count }
      end
    end

    context 'queueing the conan package file processing worker' do
      before do
        allow(::Packages::Conan::ProcessPackageFileWorker).to receive(:perform_async)
      end

      let(:params) do
        {
          file_name: file_name,
          'file.md5': '12345',
          'file.sha1': '54321',
          'file.size': '128',
          'file.type': 'txt',
          recipe_revision: '0',
          package_revision: '0',
          conan_package_reference: '123456789',
          conan_file_type: :package_file
        }.with_indifferent_access
      end

      context 'when the filename is conaninfo.txt' do
        let(:file_name) { 'conaninfo.txt' }

        let(:file) do
          fixture_file_upload('spec/fixtures/packages/conan/package_files/conaninfo.txt', 'text/plain')
        end

        it 'queues the Conan package file processing worker' do
          expect(response).to be_success
          expect(::Packages::Conan::ProcessPackageFileWorker).to have_received(:perform_async)
            .with(response[:package_file].id)
        end
      end

      context 'when the filename is not conaninfo.txt' do
        include_context 'with temp file setup'

        let(:file_name) { 'not_conaninfo.txt' }

        it 'does not queue the Conan package file processing worker' do
          expect(::Packages::Conan::ProcessPackageFileWorker).not_to receive(:perform_async)

          response
        end
      end
    end
  end
end
