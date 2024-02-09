# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Packages::PackageFilesController, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:package) { create(:package, project: project) }

  let(:filename) { 'file.zip' }
  let(:package_file) { create(:package_file, package: package, file_name: filename) }

  describe 'GET download' do
    subject do
      get download_namespace_project_package_file_url(
        id: package_file.id,
        namespace_id: project.namespace,
        project_id: project
      )
    end

    it 'sends the package file' do
      subject

      expect(response.headers['Content-Disposition'])
        .to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
    end

    context 'when file name has directory structure' do
      let(:filename) { 'dir%2Ffile.zip' }

      it 'sends the package file only with the last component of the name' do
        subject

        expect(response.headers['Content-Disposition'])
          .to eq(%(attachment; filename="file.zip"; filename*=UTF-8''file.zip))
      end
    end

    it_behaves_like 'bumping the package last downloaded at field'
  end
end
