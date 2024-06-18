# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MlModel::CreatePackageFileService, feature_category: :mlops do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, user: user, project: project) }
    let_it_be(:model) { create(:ml_models, user: user, project: project) }
    let_it_be(:model_version) { create(:ml_model_versions, :with_package, model: model, version: '0.1.0') }
    let_it_be(:package) { model_version.package }

    let(:build) { instance_double(Ci::Build, pipeline: pipeline) }

    let(:file_name) { 'myfile.tar.gz.1' }
    let(:sha256) { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
    let(:temp_file) { Tempfile.new("test") }
    let(:file) { UploadedFile.new(temp_file.path, sha256: sha256) }
    let(:package_service) { double }

    subject(:execute_service) { described_class.new(project, user, params).execute }

    before do
      FileUtils.touch(temp_file)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    context 'when package is nil' do
      let(:params) do
        {
          package: nil,
          file: file,
          file_name: file_name
        }
      end

      it 'does not create package file', :aggregate_failures do
        expect(execute_service).to be(nil)
      end
    end

    context 'when file name has slashes' do
      let(:file_name) { 'my_dir/myfile.tar.gz.1' }

      let(:params) do
        {
          package: package,
          file: file,
          file_name: file_name,
          status: :hidden
        }
      end

      it 'url encodes the file name' do
        expect(execute_service.file_name).to eq('my_dir%2Fmyfile.tar.gz.1')
      end
    end

    context 'with existing package' do
      let(:params) do
        {
          package: package,
          file: file,
          file_name: file_name,
          status: :hidden,
          build: build
        }
      end

      it 'adds the package file and updates status and ci_build', :aggregate_failures do
        expect { execute_service }
          .to change { model_version.package.package_files.count }.by(1)
          .and change { Packages::PackageFileBuildInfo.count }.by(1)

        package = model_version.reload.package
        package_file = package.package_files.last

        expect(package.build_infos.first.pipeline).to eq(build.pipeline)
        expect(package.status).to eq('hidden')

        expect(package_file.package).to eq(package)
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.size).to eq(file.size)
        expect(package_file.file_sha256).to eq(sha256)
      end
    end
  end
end
