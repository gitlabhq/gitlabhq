# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects::ReleasesController', feature_category: :release_orchestration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }

  # Added as a request spec because of https://gitlab.com/gitlab-org/gitlab/-/issues/232386
  describe 'GET #downloads' do
    let_it_be(:release) { create(:release, project: project, tag: 'v11.9.0-rc2') }
    let(:internal_redirect_url) { "https://#{Gitlab.config.gitlab.host}:#{Gitlab.config.gitlab.port}/abcd" }
    let!(:link) do
      create(:release_link, release: release, name: 'internal gitlab url', filepath: filepath,
        url: internal_redirect_url)
    end

    let_it_be(:url) { "#{project_releases_path(project)}/#{release.tag}/downloads/bin/darwin-amd64" }

    subject(:download_request) { get url }

    context 'filepath redirection' do
      before do
        login_as(user)
      end

      context 'valid filepath' do
        let(:filepath) { '/bin/darwin-amd64' }

        it 'redirects to the asset direct link' do
          download_request

          expect(response).to redirect_to(internal_redirect_url)
        end

        it 'redirects with a status of 302' do
          download_request

          expect(response).to have_gitlab_http_status(:redirect)
        end

        context 'when redirect_url is external' do
          let(:external_redirect_url) { "https://aws.example.com/s3/project/bin/hello-darwin-amd64" }
          let!(:link) do
            create(:release_link, release: release, name: 'linux-amd64 binaries', filepath: filepath,
              url: external_redirect_url)
          end

          let(:redirect_text) { "Click here to redirect to #{external_redirect_url}" }

          it "shows the warning page with redirect link" do
            download_request

            expect(response).to render_template(:redirect)
            expect(response.body).to have_text(_("You are being redirected away from GitLab"))
            expect(response.body).to have_link(_(redirect_text), href: external_redirect_url)
          end
        end
      end

      context 'invalid filepath' do
        let(:filepath) { '/binaries/win32' }

        it 'is not found' do
          download_request

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

  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :repository, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: true do
        let(:url) { project_releases_url(public_project, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :repository, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_releases_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end

    context 'when user has permissions to read code' do
      let_it_be(:release) { create(:release, project: project, tag: 'v11.9.0-rc2') }

      before do
        login_as(user)
      end

      it 'shows commit details in the atom feed' do
        get(project_releases_url(project, format: :atom))

        expect(response.body).to include(release.commit.message)
      end
    end

    context 'when user doesn\'t have permissions to read code' do
      let_it_be(:release) { create(:release, project: project, tag: 'v11.9.0-rc2') }
      let_it_be(:new_user) { create(:user, guest_of: project) }

      before do
        login_as(new_user)
      end

      it 'dosn\'t show commit details in the atom feed' do
        get(project_releases_url(project, format: :atom))

        doc = Hash.from_xml(response.body)

        expect(response.body).not_to include(release.commit.message)
        expect(doc["feed"]["entry"]["summary"]).to be_nil
      end
    end

    context 'when the project is public with private repository and user is unauthenticated' do
      let_it_be(:public_project) do
        create(:project, :repository, :public, repository_access_level: ProjectFeature::PRIVATE)
      end

      let_it_be(:release) { create(:release, project: public_project, tag: 'v11.9.0-rc2') }

      it 'dosn\'t show commit details in the atom feed' do
        get(project_releases_url(public_project, format: :atom))

        doc = Hash.from_xml(response.body)

        expect(response.body).not_to include(release.commit.message)
        expect(doc["feed"]["entry"]["summary"]).to be_nil
      end
    end
  end
end
