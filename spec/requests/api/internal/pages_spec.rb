# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Pages do
  let(:auth_headers) do
    jwt_token = JWT.encode({ 'iss' => 'gitlab-pages' }, Gitlab::Pages.secret, 'HS256')
    { Gitlab::Pages::INTERNAL_API_REQUEST_HEADER => jwt_token }
  end
  let(:pages_secret) { SecureRandom.random_bytes(Gitlab::Pages::SECRET_LENGTH) }

  before do
    allow(Gitlab::Pages).to receive(:secret).and_return(pages_secret)
  end

  describe "GET /internal/pages/status" do
    def query_enabled(headers = {})
      get api("/internal/pages/status"), headers: headers
    end

    it 'responds with 401 Unauthorized' do
      query_enabled

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'responds with 204 no content' do
      query_enabled(auth_headers)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(response.body).to be_empty
    end
  end

  describe "GET /internal/pages" do
    def query_host(host, headers = {})
      get api("/internal/pages"), headers: headers, params: { host: host }
    end

    context 'not authenticated' do
      it 'responds with 401 Unauthorized' do
        query_host('pages.gitlab.io')

        expect(response).to have_gitlab_http_status(:unauthorized)
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

          expect(response).to have_gitlab_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end

      context 'serverless domain' do
        let(:namespace) { create(:namespace, name: 'gitlab-org') }
        let(:project) { create(:project, namespace: namespace, name: 'gitlab-ce') }
        let(:environment) { create(:environment, project: project) }
        let(:pages_domain) { create(:pages_domain, domain: 'serverless.gitlab.io') }
        let(:knative_without_ingress) { create(:clusters_applications_knative) }
        let(:knative_with_ingress) { create(:clusters_applications_knative, external_ip: '10.0.0.1') }

        context 'without a knative ingress gateway IP' do
          let!(:serverless_domain_cluster) do
            create(
              :serverless_domain_cluster,
              uuid: 'abcdef12345678',
              pages_domain: pages_domain,
              knative: knative_without_ingress
            )
          end

          let(:serverless_domain) do
            create(
              :serverless_domain,
              serverless_domain_cluster: serverless_domain_cluster,
              environment: environment
            )
          end

          it 'responds with 204 no content' do
            query_host(serverless_domain.uri.host)

            expect(response).to have_gitlab_http_status(:no_content)
            expect(response.body).to be_empty
          end
        end

        context 'with a knative ingress gateway IP' do
          let!(:serverless_domain_cluster) do
            create(
              :serverless_domain_cluster,
              uuid: 'abcdef12345678',
              pages_domain: pages_domain,
              knative: knative_with_ingress
            )
          end

          let(:serverless_domain) do
            create(
              :serverless_domain,
              serverless_domain_cluster: serverless_domain_cluster,
              environment: environment
            )
          end

          it 'responds with proxy configuration' do
            query_host(serverless_domain.uri.host)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('internal/serverless/virtual_domain')

            expect(json_response['certificate']).to eq(pages_domain.certificate)
            expect(json_response['key']).to eq(pages_domain.key)

            expect(json_response['lookup_paths']).to eq(
              [
                {
                  'source' => {
                    'type' => 'serverless',
                    'service' => "test-function.#{project.name}-#{project.id}-#{environment.slug}.#{serverless_domain_cluster.knative.hostname}",
                    'cluster' => {
                      'hostname' => serverless_domain_cluster.knative.hostname,
                      'address' => serverless_domain_cluster.knative.external_ip,
                      'port' => 443,
                      'cert' => serverless_domain_cluster.certificate,
                      'key' => serverless_domain_cluster.key
                    }
                  }
                }
              ]
            )
          end
        end
      end

      context 'custom domain' do
        let(:namespace) { create(:namespace, name: 'gitlab-org') }
        let(:project) { create(:project, namespace: namespace, name: 'gitlab-ce') }
        let!(:pages_domain) { create(:pages_domain, domain: 'pages.io', project: project) }

        context 'when there are no pages deployed for the related project' do
          it 'responds with 204 No Content' do
            query_host('pages.io')

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        context 'when there are pages deployed for the related project' do
          it 'domain lookup is case insensitive' do
            deploy_pages(project)

            query_host('Pages.IO')

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'responds with the correct domain configuration' do
            deploy_pages(project)

            query_host('pages.io')

            expect(response).to have_gitlab_http_status(:ok)
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

            expect(response).to have_gitlab_http_status(:ok)
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

            expect(response).to have_gitlab_http_status(:ok)
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
