require 'rails_helper'

describe API::PagesDomains do
  set(:project) { create(:project, path: 'my.project', pages_https_only: false) }
  set(:user) { create(:user) }
  set(:admin) { create(:admin) }

  set(:pages_domain) { create(:pages_domain, :without_key, :without_certificate, domain: 'www.domain.test', project: project) }
  set(:pages_domain_secure) { create(:pages_domain, domain: 'ssl.domain.test', project: project) }
  set(:pages_domain_expired) { create(:pages_domain, :with_expired_certificate, domain: 'expired.domain.test', project: project) }

  let(:pages_domain_params) { build(:pages_domain, :without_key, :without_certificate, domain: 'www.other-domain.test').slice(:domain) }
  let(:pages_domain_secure_params) { build(:pages_domain, domain: 'ssl.other-domain.test', project: project).slice(:domain, :certificate, :key) }
  let(:pages_domain_secure_key_missmatch_params) {build(:pages_domain, :with_trusted_chain, project: project).slice(:domain, :certificate, :key) }
  let(:pages_domain_secure_missing_chain_params) {build(:pages_domain, :with_missing_chain, project: project).slice(:certificate) }

  let(:route) { "/projects/#{project.id}/pages/domains" }
  let(:route_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain.domain}" }
  let(:route_domain_path) { "/projects/#{project.full_path.gsub('/', '%2F')}/pages/domains/#{pages_domain.domain}" }
  let(:route_secure_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain_secure.domain}" }
  let(:route_expired_domain) { "/projects/#{project.id}/pages/domains/#{pages_domain_expired.domain}" }
  let(:route_vacant_domain) { "/projects/#{project.id}/pages/domains/www.vacant-domain.test" }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
  end

  describe 'GET /pages/domains' do
    context 'when pages is disabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
      end

      it_behaves_like '404 response' do
        let(:request) { get api('/pages/domains', admin) }
      end
    end

    context 'when pages is enabled' do
      context 'when authenticated as an admin' do
        it 'returns paginated all pages domains' do
          get api('/pages/domains', admin)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/pages_domain_basics')
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(3)
          expect(json_response.last).to have_key('domain')
          expect(json_response.last).to have_key('project_id')
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
      it 'returns paginated pages domains' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domains')
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(3)
        expect(json_response.map { |pages_domain| pages_domain['domain'] }).to include(pages_domain.domain)
        expect(json_response.last).to have_key('domain')
      end
    end

    context 'when pages is disabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
        project.add_master(user)
      end

      it_behaves_like '404 response' do
        let(:request) { get api(route, user) }
      end
    end

    context 'when user is a master' do
      before do
        project.add_master(user)
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
      it 'returns pages domain' do
        get api(route_domain, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain.domain)
        expect(json_response['url']).to eq(pages_domain.url)
        expect(json_response['certificate']).to be_nil
      end

      it 'returns pages domain with project path' do
        get api(route_domain_path, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain.domain)
        expect(json_response['url']).to eq(pages_domain.url)
        expect(json_response['certificate']).to be_nil
      end

      it 'returns pages domain with a certificate' do
        get api(route_secure_domain, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['domain']).to eq(pages_domain_secure.domain)
        expect(json_response['url']).to eq(pages_domain_secure.url)
        expect(json_response['certificate']['subject']).to eq(pages_domain_secure.subject)
        expect(json_response['certificate']['expired']).to be false
      end

      it 'returns pages domain with an expired certificate' do
        get api(route_expired_domain, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(json_response['certificate']['expired']).to be true
      end
    end

    context 'when domain is vacant' do
      before do
        project.add_master(user)
      end

      it_behaves_like '404 response' do
        let(:request) { get api(route_vacant_domain, user) }
      end
    end

    context 'when user is a master' do
      before do
        project.add_master(user)
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
      it 'creates a new pages domain' do
        post api(route, user), params
        pages_domain = PagesDomain.find_by(domain: json_response['domain'])

        expect(response).to have_gitlab_http_status(201)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.domain).to eq(params[:domain])
        expect(pages_domain.certificate).to be_nil
        expect(pages_domain.key).to be_nil
      end

      it 'creates a new secure pages domain' do
        post api(route, user), params_secure
        pages_domain = PagesDomain.find_by(domain: json_response['domain'])

        expect(response).to have_gitlab_http_status(201)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.domain).to eq(params_secure[:domain])
        expect(pages_domain.certificate).to eq(params_secure[:certificate])
        expect(pages_domain.key).to eq(params_secure[:key])
      end

      it 'fails to create pages domain without key' do
        post api(route, user), pages_domain_secure_params.slice(:domain, :certificate)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'fails to create pages domain with key missmatch' do
        post api(route, user), pages_domain_secure_key_missmatch_params.slice(:domain, :certificate, :key)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when user is a master' do
      before do
        project.add_master(user)
      end

      it_behaves_like 'post pages domains'
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response' do
        let(:request) { post api(route, user), params }
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response' do
        let(:request) { post api(route, user), params }
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { post api(route, user), params }
      end
    end

    context 'when user is not a member' do
      it_behaves_like '404 response' do
        let(:request) { post api(route, user), params }
      end
    end
  end

  describe 'PUT /projects/:project_id/pages/domains/:domain' do
    let(:params_secure) { pages_domain_secure_params.slice(:certificate, :key) }
    let(:params_secure_nokey) { pages_domain_secure_params.slice(:certificate) }

    shared_examples_for 'put pages domain' do
      it 'updates pages domain removing certificate' do
        put api(route_secure_domain, user)
        pages_domain_secure.reload

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_secure.certificate).to be_nil
        expect(pages_domain_secure.key).to be_nil
      end

      it 'updates pages domain adding certificate' do
        put api(route_domain, user), params_secure
        pages_domain.reload

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain.certificate).to eq(params_secure[:certificate])
        expect(pages_domain.key).to eq(params_secure[:key])
      end

      it 'updates pages domain with expired certificate' do
        put api(route_expired_domain, user), params_secure
        pages_domain_expired.reload

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_expired.certificate).to eq(params_secure[:certificate])
        expect(pages_domain_expired.key).to eq(params_secure[:key])
      end

      it 'updates pages domain with expired certificate not updating key' do
        put api(route_secure_domain, user), params_secure_nokey
        pages_domain_secure.reload

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pages_domain/detail')
        expect(pages_domain_secure.certificate).to eq(params_secure_nokey[:certificate])
      end

      it 'fails to update pages domain adding certificate without key' do
        put api(route_domain, user), params_secure_nokey

        expect(response).to have_gitlab_http_status(400)
      end

      it 'fails to update pages domain adding certificate with missing chain' do
        put api(route_domain, user), pages_domain_secure_missing_chain_params.slice(:certificate)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'fails to update pages domain with key missmatch' do
        put api(route_secure_domain, user), pages_domain_secure_key_missmatch_params.slice(:certificate, :key)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when domain is vacant' do
      before do
        project.add_master(user)
      end

      it_behaves_like '404 response' do
        let(:request) { put api(route_vacant_domain, user) }
      end
    end

    context 'when user is a master' do
      before do
        project.add_master(user)
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

  describe 'DELETE /projects/:project_id/pages/domains/:domain' do
    shared_examples_for 'delete pages domain' do
      it 'deletes a pages domain' do
        delete api(route_domain, user)

        expect(response).to have_gitlab_http_status(204)
      end
    end

    context 'when domain is vacant' do
      before do
        project.add_master(user)
      end

      it_behaves_like '404 response' do
        let(:request) { delete api(route_vacant_domain, user) }
      end
    end

    context 'when user is a master' do
      before do
        project.add_master(user)
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
