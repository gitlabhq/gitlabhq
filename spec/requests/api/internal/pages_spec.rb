# frozen_string_literal: true

require 'spec_helper'

describe API::Internal::Pages do
  describe "GET /internal/pages" do
    let(:pages_secret) { SecureRandom.random_bytes(Gitlab::Pages::SECRET_LENGTH) }

    before do
      allow(Gitlab::Pages).to receive(:secret).and_return(pages_secret)
    end

    def query_host(host, headers = {})
      get api("/internal/pages"), headers: headers, params: { host: host }
    end

    context 'feature flag disabled' do
      before do
        stub_feature_flags(pages_internal_api: false)
      end

      it 'responds with 404 Not Found' do
        query_host('pages.gitlab.io')

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'feature flag enabled' do
      context 'not authenticated' do
        it 'responds with 401 Unauthorized' do
          query_host('pages.gitlab.io')

          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'authenticated' do
        def query_host(host)
          jwt_token = JWT.encode({ 'iss' => 'gitlab-pages' }, Gitlab::Pages.secret, 'HS256')
          headers = { Gitlab::Pages::INTERNAL_API_REQUEST_HEADER => jwt_token }

          super(host, headers)
        end

        def deploy_pages(project)
          project.mark_pages_as_deployed
        end

        context 'domain does not exist' do
          it 'responds with 204 no content' do
            query_host('pages.gitlab.io')

            expect(response).to have_gitlab_http_status(204)
            expect(response.body).to be_empty
          end
        end

        context 'custom domain' do
          let(:namespace) { create(:namespace, name: 'gitlab-org') }
          let(:project) { create(:project, namespace: namespace, name: 'gitlab-ce') }
          let!(:pages_domain) { create(:pages_domain, domain: 'pages.gitlab.io', project: project) }

          context 'when there are no pages deployed for the related project' do
            it 'responds with 204 No Content' do
              query_host('pages.gitlab.io')

              expect(response).to have_gitlab_http_status(204)
            end
          end

          context 'when there are pages deployed for the related project' do
            it 'responds with the correct domain configuration' do
              deploy_pages(project)

              query_host('pages.gitlab.io')

              expect(response).to have_gitlab_http_status(200)
              expect(response).to match_response_schema('internal/pages/virtual_domain')

              expect(json_response['certificate']).to eq(pages_domain.certificate)
              expect(json_response['key']).to eq(pages_domain.key)

              expect(json_response['lookup_paths']).to eq(
                [
                  {
                    'project_id' => project.id,
                    'access_control' => false,
                    'https_only' => false,
                    'prefix' => '/',
                    'source' => {
                      'type' => 'file',
                      'path' => 'gitlab-org/gitlab-ce/public/'
                    }
                  }
                ]
              )
            end
          end
        end

        context 'namespaced domain' do
          let(:group) { create(:group, name: 'mygroup') }

          before do
            allow(Settings.pages).to receive(:host).and_return('gitlab-pages.io')
            allow(Gitlab.config.pages).to receive(:url).and_return("http://gitlab-pages.io")
          end

          context 'regular project' do
            it 'responds with the correct domain configuration' do
              project = create(:project, group: group, name: 'myproject')
              deploy_pages(project)

              query_host('mygroup.gitlab-pages.io')

              expect(response).to have_gitlab_http_status(200)
              expect(response).to match_response_schema('internal/pages/virtual_domain')

              expect(json_response['lookup_paths']).to eq(
                [
                  {
                    'project_id' => project.id,
                    'access_control' => false,
                    'https_only' => false,
                    'prefix' => '/myproject/',
                    'source' => {
                      'type' => 'file',
                      'path' => 'mygroup/myproject/public/'
                    }
                  }
                ]
              )
            end
          end

          context 'group root project' do
            it 'responds with the correct domain configuration' do
              project = create(:project, group: group, name: 'mygroup.gitlab-pages.io')
              deploy_pages(project)

              query_host('mygroup.gitlab-pages.io')

              expect(response).to have_gitlab_http_status(200)
              expect(response).to match_response_schema('internal/pages/virtual_domain')

              expect(json_response['lookup_paths']).to eq(
                [
                  {
                    'project_id' => project.id,
                    'access_control' => false,
                    'https_only' => false,
                    'prefix' => '/',
                    'source' => {
                      'type' => 'file',
                      'path' => 'mygroup/mygroup.gitlab-pages.io/public/'
                    }
                  }
                ]
              )
            end
          end
        end
      end
    end
  end
end
