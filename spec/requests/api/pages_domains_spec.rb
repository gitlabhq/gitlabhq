# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PagesDomains, feature_category: :pages do
  let_it_be(:project) { create(:project, path: 'my.project', pages_https_only: false) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let_it_be(:pages_domain) { create(:pages_domain, :without_key, :without_certificate, domain: 'www.domain.test', project: project) }
  let_it_be(:pages_domain_secure) { create(:pages_domain, domain: 'ssl.domain.test', project: project) }
  let_it_be(:pages_domain_with_letsencrypt) { create(:pages_domain, :letsencrypt, domain: 'letsencrypt.domain.test', project: project) }
  let_it_be(:pages_domain_expired) { create(:pages_domain, :with_expired_certificate, domain: 'expired.domain.test', project: project) }

  let(:pages_domain_params) { build(:pages_domain, :without_key, :without_certificate, domain: 'www.other-domain.test').slice(:domain) }
  let(:pages_domain_with_letsencrypt_params) do
    build(:pages_domain, :without_key, :without_certificate, domain: 'www.other-domain.test', auto_ssl_enabled: true)
      .slice(:domain, :auto_ssl_enabled)
  end

  let(:pages_domain_secure_params) { build(:pages_domain, domain: 'ssl.other-domain.test', project: project).slice(:domain, :certificate, :key) }
  let(:pages_domain_secure_key_missmatch_params) { build(:pages_domain, :with_trusted_chain, project: project).slice(:domain, :certificate, :key) }
  let(:pages_domain_secure_missing_chain_params) { build(:pages_domain, :with_missing_chain, project: project).slice(:certificate) }

  let(:route) { "/projects/#{project.id}/pages/domains" }
  let(:route_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain.domain}" }
  let(:route_domain_path) { "/projects/#{project.full_path.gsub('/', '%2F')}/pages/domains/#{pages_domain.domain}" }
  let(:route_secure_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain_secure.domain}" }
  let(:route_expired_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain_expired.domain}" }
  let(:route_vacant_domain) { "/projects/#{project.id}/pages/domains/www.vacant-domain.test" }
  let(:route_letsencrypt_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain_with_letsencrypt.domain}" }

  before do
    stub_pages_setting(enabled: true)
  end

  describe 'GET /pages/domains' do
    it_behaves_like 'GET request permissions for admin mode' do
      let(:path) { '/pages/domains' }
    end

    context 'when pages is disabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
      end

      it_behaves_like '404 response' do
        let(:request) { get api('/pages/domains', admin, admin_mode: true) }
      end
    end

    context 'when pages is enabled' do
      context 'when authenticated as an admin' do
        it 'returns paginated all pages domains', :aggregate_failures do
          get api('/pages/domains', admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/pages_domain_basics')
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(4)
          expect(json_response.last).to have_key('domain')
          expect(json_response.last).to have_key('project_id')
          expect(json_response.last).to have_key('auto_ssl_enabled')
          expect(json_response.last).to have_key('certificate_expiration')
          expect(json_response.last['certificate_expiration']['expired']).to be true
          expect(json_response.first).not_to have_key('certificate_expiration')
        end
      end

      context 'when authenticated as a non-member' do
        it_behaves_like '403 response' do
          let(:request) { get api('/pages/domains', user) }
        end
      end
    end
  end

  describe 'GET /projects/:project_id/pages/domains' do
    shared_examples_for 'get pages domains' do
      it 'returns paginated pages domains', :aggregate_failures do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domains')
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(4)
        expect(json_response.map { |pages_domain| pages_domain['domain'] }).to include(pages_domain.domain)
        expect(json_response.last).to have_key('domain')
      end
    end

    context 'when pages is disabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
        project.add_maintainer(user)
      end

      it_behaves_like '404 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'get pages domains'
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is not a member' do
      it_behaves_like '404 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe 'GET /projects/:project_id/pages/domains/:domain' do
    shared_examples_for 'get pages domain' do
      it 'returns pages domain', :aggregate_failures do
        get api(route_domain, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain.domain)
        expect(json_response['url']).to eq(pages_domain.url)
        expect(json_response['certificate']).to be_nil
      end

      it 'returns pages domain with project path', :aggregate_failures do
        get api(route_domain_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain.domain)
        expect(json_response['url']).to eq(pages_domain.url)
        expect(json_response['certificate']).to be_nil
      end

      it 'returns pages domain with a certificate', :aggregate_failures do
        get api(route_secure_domain, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain_secure.domain)
        expect(json_response['url']).to eq(pages_domain_secure.url)
        expect(json_response['certificate']['subject']).to eq(pages_domain_secure.subject)
        expect(json_response['certificate']['expired']).to be false
        expect(json_response['auto_ssl_enabled']).to be false
      end

      it 'returns pages domain with an expired certificate', :aggregate_failures do
        get api(route_expired_domain, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['certificate']['expired']).to be true
      end

      it 'returns pages domain with letsencrypt', :aggregate_failures do
        get api(route_letsencrypt_domain, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain_with_letsencrypt.domain)
        expect(json_response['url']).to eq(pages_domain_with_letsencrypt.url)
        expect(json_response['certificate']['subject']).to eq(pages_domain_with_letsencrypt.subject)
        expect(json_response['certificate']['expired']).to be false
        expect(json_response['auto_ssl_enabled']).to be true
      end
    end

    context 'when domain is vacant' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like '404 response' do
        let(:request) { get api(route_vacant_domain, user) }
      end
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'get pages domain'
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is not a member' do
      it_behaves_like '404 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe 'POST /projects/:project_id/pages/domains' do
    let(:params) { pages_domain_params.slice(:domain) }
    let(:params_secure) { pages_domain_secure_params.slice(:domain, :certificate, :key) }

    shared_examples_for 'post pages domains' do
      it 'creates a new pages domain', :aggregate_failures do
        expect { post api(route, user), params: params }
          .to publish_event(::Pages::Domains::PagesDomainCreatedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: kind_of(Numeric),
            domain: params[:domain]
          )

        pages_domain = PagesDomain.find_by(domain: json_response['domain'])

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.domain).to eq(params[:domain])
        expect(pages_domain.certificate).to be_nil
        expect(pages_domain.key).to be_nil
        expect(pages_domain.auto_ssl_enabled).to be false
      end

      it 'creates a new secure pages domain', :aggregate_failures do
        post api(route, user), params: params_secure
        pages_domain = PagesDomain.find_by(domain: json_response['domain'])

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.domain).to eq(params_secure[:domain])
        expect(pages_domain.certificate).to eq(params_secure[:certificate])
        expect(pages_domain.key).to eq(params_secure[:key])
        expect(pages_domain.auto_ssl_enabled).to be false
      end

      it 'creates domain with letsencrypt enabled', :aggregate_failures do
        post api(route, user), params: pages_domain_with_letsencrypt_params
        pages_domain = PagesDomain.find_by(domain: json_response['domain'])

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.domain).to eq(pages_domain_with_letsencrypt_params[:domain])
        expect(pages_domain.auto_ssl_enabled).to be true
      end

      it 'creates domain with letsencrypt enabled and provided certificate', :aggregate_failures do
        post api(route, user), params: params_secure.merge(auto_ssl_enabled: true)
        pages_domain = PagesDomain.find_by(domain: json_response['domain'])

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.domain).to eq(params_secure[:domain])
        expect(pages_domain.certificate).to eq(params_secure[:certificate])
        expect(pages_domain.key).to eq(params_secure[:key])
        expect(pages_domain.auto_ssl_enabled).to be true
      end

      it 'fails to create pages domain without key' do
        post api(route, user), params: pages_domain_secure_params.slice(:domain, :certificate)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'fails to create pages domain with key missmatch' do
        post api(route, user), params: pages_domain_secure_key_missmatch_params.slice(:domain, :certificate, :key)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'post pages domains'
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response' do
        let(:request) { post api(route, user), params: params }
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response' do
        let(:request) { post api(route, user), params: params }
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { post api(route, user), params: params }
      end
    end

    context 'when user is not a member' do
      it_behaves_like '404 response' do
        let(:request) { post api(route, user), params: params }
      end
    end
  end

  describe 'PUT /projects/:project_id/pages/domains/:domain' do
    let(:params_secure) { pages_domain_secure_params.slice(:certificate, :key) }
    let(:params_secure_nokey) { pages_domain_secure_params.slice(:certificate) }

    shared_examples_for 'put pages domain' do
      it 'updates pages domain removing certificate', :aggregate_failures do
        put api(route_secure_domain, user), params: { certificate: nil, key: nil }
        pages_domain_secure.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_secure.certificate).to be_nil
        expect(pages_domain_secure.key).to be_nil
        expect(pages_domain_secure.auto_ssl_enabled).to be false
      end

      it 'publishes PagesDomainUpdatedEvent event' do
        expect { put api(route_secure_domain, user), params: { certificate: nil, key: nil } }
          .to publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: pages_domain_secure.id,
            domain: pages_domain_secure.domain
          )
      end

      it 'updates pages domain adding certificate', :aggregate_failures do
        put api(route_domain, user), params: params_secure
        pages_domain.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.certificate).to eq(params_secure[:certificate])
        expect(pages_domain.key).to eq(params_secure[:key])
      end

      it 'updates pages domain adding certificate with letsencrypt', :aggregate_failures do
        put api(route_domain, user), params: params_secure.merge(auto_ssl_enabled: true)
        pages_domain.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.certificate).to eq(params_secure[:certificate])
        expect(pages_domain.key).to eq(params_secure[:key])
        expect(pages_domain.auto_ssl_enabled).to be true
      end

      it 'updates pages domain enabling letsencrypt', :aggregate_failures do
        put api(route_domain, user), params: { auto_ssl_enabled: true }
        pages_domain.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.auto_ssl_enabled).to be true
      end

      it 'updates pages domain disabling letsencrypt while preserving the certificate', :aggregate_failures do
        put api(route_letsencrypt_domain, user), params: { auto_ssl_enabled: false }
        pages_domain_with_letsencrypt.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_with_letsencrypt.auto_ssl_enabled).to be false
        expect(pages_domain_with_letsencrypt.key).to be_present
        expect(pages_domain_with_letsencrypt.certificate).to be_present
      end

      it 'updates pages domain with expired certificate', :aggregate_failures do
        put api(route_expired_domain, user), params: params_secure
        pages_domain_expired.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_expired.certificate).to eq(params_secure[:certificate])
        expect(pages_domain_expired.key).to eq(params_secure[:key])
      end

      it 'updates pages domain with expired certificate not updating key', :aggregate_failures do
        put api(route_secure_domain, user), params: params_secure_nokey
        pages_domain_secure.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_secure.certificate).to eq(params_secure_nokey[:certificate])
      end

      it 'updates certificate source to user_provided if is changed' do
        pages_domain.update!(certificate_source: 'gitlab_provided')

        expect do
          put api(route_domain, user), params: params_secure
        end.to change { pages_domain.reload.certificate_source }.from('gitlab_provided').to('user_provided')
      end

      context 'with invalid params' do
        it 'fails to update pages domain adding certificate without key' do
          put api(route_domain, user), params: params_secure_nokey

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'does not publish PagesDomainUpdatedEvent event' do
          expect { put api(route_domain, user), params: params_secure_nokey }
            .not_to publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
        end

        it 'fails to update pages domain adding certificate with missing chain' do
          put api(route_domain, user), params: pages_domain_secure_missing_chain_params.slice(:certificate)

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'fails to update pages domain with key missmatch' do
          put api(route_secure_domain, user), params: pages_domain_secure_key_missmatch_params.slice(:certificate, :key)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context 'when domain is vacant' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like '404 response' do
        let(:request) { put api(route_vacant_domain, user) }
      end
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'put pages domain'
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response' do
        let(:request) { put api(route_domain, user) }
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response' do
        let(:request) { put api(route_domain, user) }
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { put api(route_domain, user) }
      end
    end

    context 'when user is not a member' do
      it_behaves_like '404 response' do
        let(:request) { put api(route_domain, user) }
      end
    end
  end

  describe 'PUT /projects/:project_id/pages/domains/:domain/verify' do
    let(:verify_domain_path) { "/projects/#{project.id}/pages/domains/#{pages_domain.domain}/verify" }

    context 'when user is not authorized' do
      it 'returns 401' do
        put api(verify_domain_path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when user does not have sufficient permissions' do
        before do
          project.add_reporter(user)
        end

        it 'returns 403' do
          put api(verify_domain_path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when domain does not exist' do
        it 'returns 404' do
          put api("/projects/#{project.id}/pages/domains/non-existent-domain.com/verify", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when verification succeeds' do
        before do
          allow_next_instance_of(VerifyPagesDomainService) do |service|
            allow(service).to receive(:execute).and_return({ status: :success })
          end
        end

        it 'returns the verified domain' do
          put api(verify_domain_path, user)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['domain']).to eq(pages_domain.domain)
        end
      end

      context 'when verification fails' do
        before do
          allow_next_instance_of(VerifyPagesDomainService) do |service|
            allow(service).to receive(:execute).and_return({
              status: :error,
              message: 'Verification failed',
              http_status: :unprocessable_entity
            })
          end
        end

        it 'returns error message' do
          put api(verify_domain_path, user)

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Verification failed')
        end
      end
    end
  end

  describe 'DELETE /projects/:project_id/pages/domains/:domain' do
    shared_examples_for 'delete pages domain' do
      it 'deletes a pages domain' do
        expect { delete api(route_domain, user) }
          .to change(PagesDomain, :count).by(-1)
          .and publish_event(::Pages::Domains::PagesDomainDeletedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: pages_domain.id,
            domain: pages_domain.domain
          )

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when domain is vacant' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like '404 response' do
        let(:request) { delete api(route_vacant_domain, user) }
      end
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'delete pages domain'
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response' do
        let(:request) { delete api(route_domain, user) }
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response' do
        let(:request) { delete api(route_domain, user) }
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { delete api(route_domain, user) }
      end
    end

    context 'when user is not a member' do
      it_behaves_like '404 response' do
        let(:request) { delete api(route_domain, user) }
      end
    end
  end
end
