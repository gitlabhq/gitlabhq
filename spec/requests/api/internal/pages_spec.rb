# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Pages, feature_category: :pages do
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  let(:auth_header) do
    {
      Gitlab::Pages::INTERNAL_API_REQUEST_HEADER => JWT.encode(
        { 'iss' => 'gitlab-pages' },
        Gitlab::Pages.secret, 'HS256')
    }
  end

  before do
    allow(Gitlab::Pages)
      .to receive(:secret)
      .and_return(SecureRandom.random_bytes(Gitlab::Pages::SECRET_LENGTH))

    stub_pages_object_storage(::Pages::DeploymentUploader)
  end

  describe 'GET /internal/pages/status' do
    it 'responds with 401 Unauthorized' do
      get api('/internal/pages/status')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'responds with 204 no content' do
      get api('/internal/pages/status'), headers: auth_header

      expect(response).to have_gitlab_http_status(:no_content)
      expect(response.body).to be_empty
    end
  end

  describe 'GET /internal/pages' do
    context 'when not authenticated' do
      it 'responds with 401 Unauthorized' do
        get api('/internal/pages')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated', :freeze_time do
      context 'when domain does not exist' do
        it 'responds with 204 no content' do
          get api('/internal/pages'), headers: auth_header, params: { host: 'any-domain.gitlab.io' }

          expect(response).to have_gitlab_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end

      context 'when querying a custom domain' do
        let_it_be(:pages_domain) { create(:pages_domain, domain: 'pages.io', project: project) }

        # We need to ensure not to return the unique domain when requesting a custom domain
        # https://gitlab.com/gitlab-org/gitlab/-/issues/426435
        before_all do
          project.project_setting.update!(
            pages_unique_domain: 'unique-domain',
            pages_unique_domain_enabled: true
          )
        end

        context 'when there are no pages deployed for the related project' do
          it 'responds with 204 No Content' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'pages.io' }

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        context 'when there are pages deployed for the related project' do
          let!(:deployment) { create(:pages_deployment, project: project) }

          it 'domain lookup is case insensitive' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'Pages.IO' }

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'responds with the correct domain configuration' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'pages.io' }

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
                    'type' => 'zip',
                    'path' => deployment.file.url(expire_at: 1.day.from_now),
                    'global_id' => "gid://gitlab/PagesDeployment/#{deployment.id}",
                    'sha256' => deployment.file_sha256,
                    'file_size' => deployment.size,
                    'file_count' => deployment.file_count
                  },
                  'unique_host' => nil,
                  'root_directory' => deployment.root_directory,
                  'primary_domain' => nil
                }
              ]
            )
          end
        end
      end

      context 'when querying a unique domain' do
        before_all do
          project.project_setting.update!(
            pages_unique_domain: 'unique-domain',
            pages_unique_domain_enabled: true
          )
        end

        context 'when there are no pages deployed for the related project' do
          it 'responds with 204 No Content' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'unique-domain.example.com' }

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        context 'when there are pages deployed for the related project' do
          let!(:deployment) { create(:pages_deployment, project: project) }

          context 'when the unique domain is disabled' do
            before do
              project.project_setting.update!(pages_unique_domain_enabled: false)
            end

            context 'when there are no pages deployed for the related project' do
              it 'responds with 204 No Content' do
                get api('/internal/pages'), headers: auth_header, params: { host: 'unique-domain.example.com' }

                expect(response).to have_gitlab_http_status(:no_content)
              end
            end
          end

          it 'domain lookup is case insensitive' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'Unique-Domain.example.com' }

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'responds with the correct domain configuration' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'unique-domain.example.com' }

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
                    'type' => 'zip',
                    'path' => deployment.file.url(expire_at: 1.day.from_now),
                    'global_id' => "gid://gitlab/PagesDeployment/#{deployment.id}",
                    'sha256' => deployment.file_sha256,
                    'file_size' => deployment.size,
                    'file_count' => deployment.file_count
                  },
                  'unique_host' => 'unique-domain.example.com',
                  'root_directory' => 'public',
                  'primary_domain' => nil
                }
              ]
            )
          end
        end
      end

      context 'when querying a primary domain' do
        let_it_be(:pages_domain) { create(:pages_domain, domain: 'pages.io', project: project) }

        context 'when there are pages deployed for the related project' do
          let!(:deployment) { create(:pages_deployment, project: project) }

          before do
            project.project_setting.update!(
              pages_primary_domain: 'https://pages.io',
              pages_unique_domain: 'unique-domain',
              pages_unique_domain_enabled: true
            )
          end

          it 'responds with the correct domain configuration' do
            get api('/internal/pages'), headers: auth_header, params: { host: 'unique-domain.example.com' }

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
                    'type' => 'zip',
                    'path' => deployment.file.url(expire_at: 1.day.from_now),
                    'global_id' => "gid://gitlab/PagesDeployment/#{deployment.id}",
                    'sha256' => deployment.file_sha256,
                    'file_size' => deployment.size,
                    'file_count' => deployment.file_count
                  },
                  'unique_host' => 'unique-domain.example.com',
                  'root_directory' => 'public',
                  'primary_domain' => 'https://pages.io'
                }
              ]
            )
          end
        end
      end

      context 'when querying a namespaced domain' do
        before do
          allow(Settings.pages).to receive(:host).and_return('gitlab-pages.io')
          allow(Gitlab.config.pages).to receive(:url).and_return("http://gitlab-pages.io")
        end

        context 'when there are no pages deployed for the related project' do
          it 'responds with 204 No Content' do
            get api('/internal/pages'), headers: auth_header, params: { host: "#{group.path}.gitlab-pages.io" }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('internal/pages/virtual_domain')
            expect(json_response['lookup_paths']).to eq([])
          end
        end

        context 'when there are pages deployed for the related project' do
          let!(:deployment) { create(:pages_deployment, project: project) }

          context 'with a regular project' do
            it 'responds with the correct domain configuration' do
              get api('/internal/pages'), headers: auth_header, params: { host: "#{group.path}.gitlab-pages.io" }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('internal/pages/virtual_domain')

              expect(json_response['lookup_paths']).to eq(
                [
                  {
                    'project_id' => project.id,
                    'access_control' => false,
                    'https_only' => false,
                    'prefix' => "/#{project.path}/",
                    'source' => {
                      'type' => 'zip',
                      'path' => deployment.file.url(expire_at: 1.day.from_now),
                      'global_id' => "gid://gitlab/PagesDeployment/#{deployment.id}",
                      'sha256' => deployment.file_sha256,
                      'file_size' => deployment.size,
                      'file_count' => deployment.file_count
                    },
                    'unique_host' => nil,
                    'root_directory' => 'public',
                    'primary_domain' => nil
                  }
                ]
              )
            end
          end

          it 'avoids N+1 queries' do
            control = ActiveRecord::QueryRecorder.new do
              get api('/internal/pages'), headers: auth_header, params: { host: "#{group.path}.gitlab-pages.io" }
            end

            3.times do
              project = create(:project, group: group)
              create(:pages_deployment, project: project)
            end

            expect { get api('/internal/pages'), headers: auth_header, params: { host: "#{group.path}.gitlab-pages.io" } }
              .not_to exceed_query_limit(control)
          end

          context 'with a group root project' do
            before do
              project.update!(path: "#{group.path}.gitlab-pages.io")
            end

            it 'responds with the correct domain configuration' do
              get api('/internal/pages'), headers: auth_header, params: { host: "#{group.path}.gitlab-pages.io" }

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
                      'type' => 'zip',
                      'path' => deployment.file.url(expire_at: 1.day.from_now),
                      'global_id' => "gid://gitlab/PagesDeployment/#{deployment.id}",
                      'sha256' => deployment.file_sha256,
                      'file_size' => deployment.size,
                      'file_count' => deployment.file_count
                    },
                    'unique_host' => nil,
                    'root_directory' => 'public',
                    'primary_domain' => nil
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
