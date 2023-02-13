# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects::ReleasesController', feature_category: :release_orchestration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_developer(user)
  end

  # Added as a request spec because of https://gitlab.com/gitlab-org/gitlab/-/issues/232386
  describe 'GET #downloads' do
    let_it_be(:release) { create(:release, project: project, tag: 'v11.9.0-rc2' ) }
    let!(:link) { create(:release_link, release: release, name: 'linux-amd64 binaries', filepath: filepath, url: 'https://aws.example.com/s3/project/bin/hello-darwin-amd64') }
    let_it_be(:url) { "#{project_releases_path(project)}/#{release.tag}/downloads/bin/darwin-amd64" }

    let(:subject) { get url }

    context 'filepath redirection' do
      before do
        login_as(user)
      end

      context 'valid filepath' do
        let(:filepath) { '/bin/darwin-amd64' }

        it 'redirects to the asset direct link' do
          subject

          expect(response).to redirect_to('https://aws.example.com/s3/project/bin/hello-darwin-amd64')
        end

        it 'redirects with a status of 302' do
          subject

          expect(response).to have_gitlab_http_status(:redirect)
        end
      end

      context 'invalid filepath' do
        let(:filepath) { '/binaries/win32' }

        it 'is not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'sessionless download authentication' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }
      let(:filepath) { '/bin/darwin-amd64' }

      subject { get url, params: { private_token: personal_access_token.token } }

      it 'will allow sessionless users to download the file' do
        subject

        expect(controller.current_user).to eq(user)
        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to(link.url)
      end
    end
  end

  context 'invalid filepath' do
    let(:invalid_filepath) { 'bin/darwin-amd64' }

    let(:subject) { create(:release_link, name: 'linux-amd64 binaries', filepath: invalid_filepath, url: 'https://aws.example.com/s3/project/bin/hello-darwin-amd64') }

    it 'cannot create an invalid filepath' do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
