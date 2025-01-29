# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Packages::PackageFilesController, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:package) { create(:generic_package, project: project) }

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

    context 'when the fog provider is Google and on .com', :saas do
      let(:package_file) { create(:package_file, :object_storage, package: package, file_name: filename) }

      before do
        stub_package_file_object_storage(
          config: Gitlab.config.packages.object_store.merge(connection: {
            provider: 'Google',
            google_storage_access_key_id: 'test-access-id',
            google_storage_secret_access_key: 'secret'
          }),
          proxy_download: true
        )
      end

      it 'send the correct headers' do
        subject

        command, encoded_params = response.headers[::Gitlab::Workhorse::SEND_DATA_HEADER].split(':')
        params = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_params))

        expect(command).to eq('send-url')
        expect(params['URL']).to include(
          %(response-content-disposition=attachment%3B%20filename%3D%22#{filename}),
          'x-goog-custom-audit-gitlab-project',
          'x-goog-custom-audit-gitlab-namespace',
          'x-goog-custom-audit-gitlab-size-bytes'
        )
      end
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
