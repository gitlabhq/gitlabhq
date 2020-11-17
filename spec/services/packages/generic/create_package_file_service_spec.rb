# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Generic::CreatePackageFileService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let(:build) { double('build', pipeline: pipeline) }

  describe '#execute' do
    let(:sha256) { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
    let(:temp_file) { Tempfile.new("test") }
    let(:file) { UploadedFile.new(temp_file.path, sha256: sha256) }
    let(:package) { create(:generic_package, project: project) }
    let(:params) do
      {
        package_name: 'mypackage',
        package_version: '0.0.1',
        file: file,
        file_name: 'myfile.tar.gz.1',
        build: build
      }
    end

    before do
      FileUtils.touch(temp_file)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    it 'creates package file' do
      package_service = double
      package_params = {
        name: params[:package_name],
        version: params[:package_version],
        build: params[:build]
      }
      expect(::Packages::Generic::FindOrCreatePackageService).to receive(:new).with(project, user, package_params).and_return(package_service)
      expect(package_service).to receive(:execute).and_return(package)

      service = described_class.new(project, user, params)

      expect { service.execute }.to change { package.package_files.count }.by(1)
        .and change { Packages::PackageFileBuildInfo.count }.by(1)

      package_file = package.package_files.last
      aggregate_failures do
        expect(package_file.package).to eq(package)
        expect(package_file.file_name).to eq('myfile.tar.gz.1')
        expect(package_file.size).to eq(file.size)
        expect(package_file.file_sha256).to eq(sha256)
      end
    end
  end
end
