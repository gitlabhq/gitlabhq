# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Generic::CreatePackageFileService, feature_category: :package_registry do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, group: namespace) }
  let_it_be(:package_settings) { create(:namespace_package_setting, namespace: namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let_it_be(:file_name) { 'myfile.tar.gz.1' }

  let(:build) { double('build', pipeline: pipeline) }

  describe '#execute' do
    let_it_be(:package) { create(:generic_package, project: project) }

    let(:sha256) { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
    let(:temp_file) { Tempfile.new("test") }
    let(:file) { UploadedFile.new(temp_file.path, sha256: sha256) }
    let(:package_service) { double }

    let(:params) do
      {
        package_name: 'mypackage',
        package_version: '0.0.1',
        file: file,
        file_name: file_name,
        build: build
      }
    end

    let(:package_params) do
      {
        name: params[:package_name],
        version: params[:package_version],
        build: params[:build],
        status: nil
      }
    end

    subject(:execute_service) { described_class.new(project, user, params).execute }

    before do
      FileUtils.touch(temp_file)
      expect(::Packages::Generic::FindOrCreatePackageService).to receive(:new).with(project, user, package_params).and_return(package_service)
      expect(package_service).to receive(:execute).and_return(package)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    shared_examples 'allows creating the file' do
      it { expect { execute_service }.to change { project.package_files.count }.by(1) }
    end

    shared_examples 'does not allow duplicates' do
      it 'raises a duplicate package error' do
        expect { execute_service }.to raise_error(::Packages::DuplicatePackageError)
          .and change { project.package_files.count }.by(0)
      end
    end

    it 'creates package file', :aggregate_failures do
      expect { execute_service }.to change { package.package_files.count }.by(1)
        .and change { Packages::PackageFileBuildInfo.count }.by(1)

      package_file = package.package_files.last
      aggregate_failures do
        expect(package_file.package.status).to eq('default')
        expect(package_file.package).to eq(package)
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.size).to eq(file.size)
        expect(package_file.file_sha256).to eq(sha256)
      end
    end

    context 'with a status' do
      let(:params) { super().merge(status: 'hidden') }
      let(:package_params) { super().merge(status: 'hidden') }

      it 'updates an existing packages status' do
        expect { execute_service }.to change { package.package_files.count }.by(1)
          .and change { Packages::PackageFileBuildInfo.count }.by(1)

        package_file = package.package_files.last
        aggregate_failures do
          expect(package_file.package.status).to eq('hidden')
        end
      end
    end

    it_behaves_like 'assigns build to package file'

    context 'with existing package' do
      let_it_be(:duplicate_file) { create(:package_file, package: package, file_name: file_name) }

      it { expect { execute_service }.to change { project.package_files.count }.by(1) }

      context 'when duplicates are not allowed' do
        before do
          package_settings.update!(generic_duplicates_allowed: false, generic_duplicate_exception_regex: '')
        end

        it_behaves_like 'does not allow duplicates'

        context 'when the file is pending destruction' do
          before do
            duplicate_file.update_column(:status, :pending_destruction)
          end

          it_behaves_like 'allows creating the file'
        end

        context 'when the package name matches the exception regex' do
          before do
            package_settings.update!(generic_duplicate_exception_regex: package.name)
          end

          it_behaves_like 'allows creating the file'
        end
      end

      context 'when duplicates are allowed' do
        before do
          package_settings.update!(generic_duplicates_allowed: true, generic_duplicate_exception_regex: '')
        end

        it_behaves_like 'allows creating the file'

        context 'when the package name matches the exception regex' do
          before do
            package_settings.update!(generic_duplicate_exception_regex: package.name)
          end

          it_behaves_like 'does not allow duplicates'
        end

        context 'with multiple files for the same package and the same pipeline' do
          let(:file_2_params) { params.merge(file_name:  'myfile.tar.gz.2', file: file2) }
          let(:file_3_params) { params.merge(file_name:  'myfile.tar.gz.3', file: file3) }

          let(:temp_file2) { Tempfile.new("test2") }
          let(:temp_file3) { Tempfile.new("test3") }

          let(:file2) { UploadedFile.new(temp_file2.path, sha256: sha256) }
          let(:file3) { UploadedFile.new(temp_file3.path, sha256: sha256) }

          before do
            FileUtils.touch(temp_file2)
            FileUtils.touch(temp_file3)
            expect(::Packages::Generic::FindOrCreatePackageService).to receive(:new).with(project, user, package_params).and_return(package_service).twice
            expect(package_service).to receive(:execute).and_return(package).twice
          end

          after do
            FileUtils.rm_f(temp_file2)
            FileUtils.rm_f(temp_file3)
          end

          it 'creates the build info only once' do
            expect do
              described_class.new(project, user, params).execute
              described_class.new(project, user, file_2_params).execute
              described_class.new(project, user, file_3_params).execute
            end.to change { package.build_infos.count }.by(1)
          end
        end
      end
    end
  end
end
