# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MlModel::CreatePackageFileService, feature_category: :mlops do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, user: user, project: project) }
    let_it_be(:file_name) { 'myfile.tar.gz.1' }

    let(:build) { instance_double(Ci::Build, pipeline: pipeline) }

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

    context 'without existing package' do
      let(:params) do
        {
          package_name: 'new_model',
          package_version: '1.0.0',
          file: file,
          file_name: file_name
        }
      end

      it 'creates package file', :aggregate_failures do
        expect { execute_service }
          .to change { Packages::MlModel::Package.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
          .and change { Packages::PackageFileBuildInfo.count }.by(0)
          .and change { Ml::ModelVersion.count }.by(1)

        new_model = Packages::MlModel::Package.last
        package_file = new_model.package_files.last
        new_model_version = Ml::ModelVersion.last

        expect(new_model.name).to eq('new_model')
        expect(new_model.version).to eq('1.0.0')
        expect(new_model.status).to eq('default')
        expect(package_file.package).to eq(new_model)
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.size).to eq(file.size)
        expect(package_file.file_sha256).to eq(sha256)
        expect(new_model_version.name).to eq('new_model')
        expect(new_model_version.version).to eq('1.0.0')
        expect(new_model_version.package).to eq(new_model)
      end
    end

    context 'with existing package' do
      let_it_be(:model) { create(:ml_model_package, creator: user, project: project, version: '0.1.0') }

      let(:params) do
        {
          package_name: model.name,
          package_version: model.version,
          file: file,
          file_name: file_name,
          status: :hidden,
          build: build
        }
      end

      it 'adds the package file and updates status and ci_build', :aggregate_failures do
        expect { execute_service }
          .to change { project.packages.ml_model.count }.by(0)
          .and change { model.package_files.count }.by(1)
          .and change { Packages::PackageFileBuildInfo.count }.by(1)

        model.reload

        package_file = model.package_files.last

        expect(model.build_infos.first.pipeline).to eq(build.pipeline)
        expect(model.status).to eq('hidden')

        expect(package_file.package).to eq(model)
        expect(package_file.file_name).to eq(file_name)
        expect(package_file.size).to eq(file.size)
        expect(package_file.file_sha256).to eq(sha256)
      end
    end
  end
end
