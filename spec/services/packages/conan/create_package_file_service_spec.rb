# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Conan::CreatePackageFileService, feature_category: :package_registry do
  include WorkhorseHelpers

  let_it_be(:package) { create(:conan_package, without_package_files: true) }
  let_it_be(:user) { create(:user) }

  describe '#execute', :aggregate_failures do
    let(:file_name) { 'foo.tgz' }
    let(:conan_package_reference) { '1234567890abcdef1234567890abcdef12345678' }

    subject(:response) { described_class.new(package, file, params).execute }

    shared_examples 'a valid package_file' do
      let(:params) do
        {
          file_name: file_name,
          'file.md5': '12345',
          'file.sha1': '54321',
          'file.size': '128',
          'file.type': 'txt',
          recipe_revision: '0',
          package_revision: '0',
          conan_package_reference: conan_package_reference,
          conan_file_type: :package_file
        }.with_indifferent_access
      end

      it 'creates a new package file' do
        response = subject

        expect(response).to be_success
        package_file = response[:package_file]

        expect(package_file).to be_valid
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.file_md5).to eq('12345')
        expect(package_file.size).to eq(128)
        expect(package_file.conan_file_metadatum).to be_valid
        expect(package_file.conan_file_metadatum.recipe_revision_value).to eq('0')
        expect(package_file.conan_file_metadatum.package_revision_value).to eq('0')
        expect(package_file.conan_file_metadatum.recipe_revision_id).to be_nil
        expect(package_file.conan_file_metadatum.package_revision_id).to be_nil
        expect(package_file.conan_file_metadatum.conan_package_reference).to eq(conan_package_reference)
        expect(package_file.conan_file_metadatum.package_reference.reference).to eq(conan_package_reference)
        expect(package_file.conan_file_metadatum.conan_file_type).to eq('package_file')
        expect(package_file.file.read).to eq('content')
      end

      it_behaves_like 'assigns build to package file' do
        subject(:package_file) { response[:package_file] }
      end
    end

    shared_examples 'a valid recipe_file' do
      let(:params) do
        {
          file_name: file_name,
          'file.md5': '12345',
          'file.sha1': '54321',
          'file.size': '128',
          'file.type': 'txt',
          recipe_revision: '0',
          conan_file_type: :recipe_file
        }.with_indifferent_access
      end

      it 'creates a new recipe file' do
        response = subject

        expect(response).to be_success
        package_file = response[:package_file]

        expect(package_file).to be_valid
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.file_md5).to eq('12345')
        expect(package_file.size).to eq(128)
        expect(package_file.conan_file_metadatum).to be_valid
        expect(package_file.conan_file_metadatum.recipe_revision_value).to eq('0')
        expect(package_file.conan_file_metadatum.package_revision_value).to be_nil
        expect(package_file.conan_file_metadatum.recipe_revision_id).to be_nil
        expect(package_file.conan_file_metadatum.package_revision_id).to be_nil
        expect(package_file.conan_file_metadatum.conan_package_reference).to be_nil
        expect(package_file.conan_file_metadatum.package_reference).to be_nil
        expect(package_file.conan_file_metadatum.conan_file_type).to eq('recipe_file')
        expect(package_file.file.read).to eq('content')
      end

      it_behaves_like 'assigns build to package file' do
        subject(:package_file) { response[:package_file] }
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

      it_behaves_like 'a valid package_file'
      it_behaves_like 'a valid recipe_file'
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

      it_behaves_like 'a valid package_file'
      it_behaves_like 'a valid recipe_file'
    end

    context 'file is missing' do
      let(:file) { nil }

      context 'with recipe_file' do
        let(:params) do
          {
            file_name: file_name,
            recipe_revision: '0',
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
            package_revision: '0',
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
          recipe_revision: '0',
          package_revision: '0',
          conan_package_reference: 'invalid_reference',
          conan_file_type: :package_file
        }.with_indifferent_access
      end

      it 'returns an error response and does not create a package file' do
        response = subject

        expect(response).to be_error
        expect(response.message).to include('Validation failed: ' \
          'Conan file metadatum conan package reference is invalid')
        expect(response.reason).to eq(:invalid_package_file)
        expect { response }.not_to change { Packages::PackageFile.count }
        expect { response }.not_to change { Packages::Conan::FileMetadatum.count }
        expect { response }.not_to change { Packages::Conan::PackageReference.count }
      end
    end
  end
end
