# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::AuthFinders, feature_category: :system_access do
  include described_class
  include HttpBasicAuthHelpers

  let_it_be(:organization) { create(:organization) }

  # Create the feed_token and static_object_token for the user
  let_it_be(:user, freeze: true) { create(:user).tap(&:feed_token).tap(&:static_object_token) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

  let_it_be(:project, freeze: true) { create(:project, :private, developers: user) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }
  let_it_be(:job, freeze: true) { create(:ci_build, :running, pipeline: pipeline, user: user) }
  let_it_be(:failed_job, freeze: true) { create(:ci_build, :failed, pipeline: pipeline, user: user) }

  let_it_be(:project2, freeze: true) { create(:project, :private, developers: user) }
  let_it_be(:pipeline2, freeze: true) { create(:ci_pipeline, project: project2) }
  let_it_be(:job2, freeze: true) { create(:ci_build, :running, pipeline: pipeline2, user: user) }

  let(:env) do
    {
      'rack.input' => ''
    }
  end

  let(:request) { ActionDispatch::Request.new(env) }
  let(:params) { {} }

  def set_param(key, value)
    request.update_param(key, value)
  end

  def set_header(key, value)
    env[key] = value
  end

  def set_basic_auth_header(username, password)
    env.merge!(basic_auth_header(username, password))
  end

  def set_bearer_token(token)
    env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
  end

  shared_examples 'find user from job token' do |without_job_token_allowed|
    context 'when route is allowed to be authenticated', :request_store do
      let(:route_authentication_setting) { { job_token_allowed: true } }

      context 'for an invalid token' do
        let(:token) { 'invalid token' }

        it "returns an Unauthorized exception" do
          expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
          expect(@current_authenticated_job).to be_nil
        end
      end

      context 'with a running job' do
        let(:token) { job.token }

        it 'return user' do
          expect(subject).to eq(user)
          expect(@current_authenticated_job).to eq job
          expect(subject).to be_from_ci_job_token
          expect(subject.ci_job_token_scope.current_project).to eq(job.project)
        end
      end

      context 'with a job that is not running' do
        let(:token) { failed_job.token }

        it 'returns an Unauthorized exception' do
          expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
          expect(@current_authenticated_job).to be_nil
        end
      end

      context 'for an array of tokens' do
        let(:token) { [job.token, 'invalid token'] }

        it "returns an Unauthorized exception" do
          expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
          expect(@current_authenticated_job).to be_nil
        end
      end
    end

    context 'when route is not allowed to be authenticated', :request_store do
      let(:route_authentication_setting) { { job_token_allowed: false } }

      context 'with a running job' do
        let(:token) { job.token }

        case without_job_token_allowed
        when :error
          it 'returns an Unauthorized exception' do
            expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
            expect(@current_authenticated_job).to be_nil
          end
        when :user
          it 'returns the user' do
            expect(subject).to eq(user)
            expect(@current_authenticated_job).to eq job
            expect(subject).to be_from_ci_job_token
            expect(subject.ci_job_token_scope.current_project).to eq(job.project)
          end
        else
          it 'returns nil' do
            is_expected.to be_nil
            expect(@current_authenticated_job).to be_nil
          end
        end
      end
    end
  end

  describe '#find_user_from_bearer_token' do
    subject { find_user_from_bearer_token }

    context 'when the token is passed as an oauth token' do
      before do
        set_bearer_token(token)
      end

      it_behaves_like 'find user from job token', :error
    end

    context 'with oauth token' do
      let_it_be(:oauth_application) { create(:oauth_application, owner: user) }
      let(:oauth_access_token) do
        create(:oauth_access_token,
          application_id: oauth_application.id,
          resource_owner_id: user.id,
          scopes: 'api',
          organization_id: organization.id)
      end

      before do
        set_bearer_token(oauth_access_token.plaintext_token)
      end

      it { is_expected.to eq user }
    end

    context 'with a personal access token' do
      before do
        env[described_class::PRIVATE_TOKEN_HEADER] = personal_access_token.token
      end

      it { is_expected.to eq user }
    end
  end

  describe '#find_user_from_warden' do
    context 'with CSRF token' do
      before do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'with invalid credentials' do
        it 'returns nil' do
          expect(find_user_from_warden).to be_nil
        end
      end

      context 'with valid credentials' do
        it 'returns the user' do
          set_header('warden', double("warden", authenticate: user))

          expect(find_user_from_warden).to eq user
        end
      end
    end

    context 'without CSRF token' do
      it 'returns nil' do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)
        set_header('warden', double("warden", authenticate: user))

        expect(find_user_from_warden).to be_nil
      end
    end
  end

  describe '#find_user_from_feed_token' do
    context 'when the request format is atom' do
      before do
        set_header('SCRIPT_NAME', 'url.atom')
        set_header('HTTP_ACCEPT', 'application/atom+xml')
      end

      context 'when old format feed_token param is provided' do
        it 'returns user if valid feed_token' do
          set_param(:feed_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to eq user
        end

        it 'returns nil if valid feed_token and disabled' do
          allow(Gitlab::CurrentSettings).to receive_messages(disable_feed_token: true)
          set_param(:feed_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns nil if feed_token is blank' do
          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if invalid feed_token' do
          set_param(:feed_token, 'invalid_token')

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end

      context 'when path-dependent format feed_token param is provided' do
        let_it_be(:feed_user, freeze: true) { create(:user, feed_token: 'KNOWN VALUE').tap(&:feed_token) }
        # The middle part is the output of OpenSSL::HMAC.hexdigest("SHA256", 'KNOWN VALUE', 'url.atom')
        let(:feed_token) { "glft-a8cc74ccb0de004d09a968705ba49099229b288b3de43f26c473a9d8d7fb7693-#{feed_user.id}" }

        it 'returns user if valid feed_token' do
          set_param(:feed_token, feed_token)

          expect(find_user_from_feed_token(:rss)).to eq feed_user
        end

        it 'returns nil if valid feed_token and disabled' do
          allow(Gitlab::CurrentSettings).to receive_messages(disable_feed_token: true)
          set_param(:feed_token, feed_token)

          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if token has same HMAC but different user ID' do
          set_param(:feed_token, "glft-a8cc74ccb0de004d09a968705ba49099229b288b3de43f26c473a9d8d7fb7693-#{user.id}")

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end

        it 'returns exception if token has wrong HMAC but same user ID' do
          set_param(:feed_token, "glft-aaaaaaaaaade004d09a968705ba49099229b288b3de43f26c473a9d8d7fb7693-#{feed_user.id}")

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end

        it 'returns exception if user does not exist' do
          set_param(:feed_token, "glft-a8cc74ccb0de004d09a968705ba49099229b288b3de43f26c473a9d8d7fb7693-#{non_existing_record_id}")

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end

        it 'returns exception if an array is passed' do
          set_param(:feed_token, [feed_token, 'fake'])

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end

      context 'when old format rss_token param is provided' do
        it 'returns user if valid rss_token' do
          set_param(:rss_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to eq user
        end

        it 'returns nil if rss_token is blank' do
          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if invalid rss_token' do
          set_param(:rss_token, 'invalid_token')

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end

    context 'when the request format is not atom' do
      it 'returns nil' do
        set_header('SCRIPT_NAME', 'json')

        set_param(:feed_token, user.feed_token)

        expect(find_user_from_feed_token(:rss)).to be_nil
      end
    end

    context 'when the request format is empty' do
      it 'the method call does not modify the original value' do
        set_header('SCRIPT_NAME', 'url.atom')

        env.delete('action_dispatch.request.formats')

        find_user_from_feed_token(:rss)

        expect(env['action_dispatch.request.formats']).to be_nil
      end
    end
  end

  describe '#find_user_from_static_object_token' do
    shared_examples 'static object request' do
      before do
        set_header('SCRIPT_NAME', path)
      end

      context 'when token header param is present' do
        context 'when token is correct' do
          it 'returns the user' do
            request.headers['X-Gitlab-Static-Object-Token'] = user.static_object_token

            expect(find_user_from_static_object_token(format)).to eq(user)
          end
        end

        context 'when token is incorrect' do
          it 'returns an error' do
            request.headers['X-Gitlab-Static-Object-Token'] = 'foobar'

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end

        context 'when token is an array' do
          it 'returns an error' do
            request.headers['X-Gitlab-Static-Object-Token'] = [user.static_object_token, 'foobar']

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end
      end

      context 'when token query param is present' do
        context 'when token is correct' do
          it 'returns the user' do
            set_param(:token, user.static_object_token)

            expect(find_user_from_static_object_token(format)).to eq(user)
          end
        end

        context 'when token is incorrect' do
          it 'raises an error' do
            set_param(:token, 'foobar')

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end

        context 'when token is an array' do
          it 'raises an error' do
            set_param(:token, [user.static_object_token, 'foobar'])

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end
      end
    end

    context 'when request format is archive' do
      it_behaves_like 'static object request' do
        let_it_be(:path) { 'project/-/archive/master.zip' }
        let_it_be(:format) { :archive }
      end
    end

    context 'when request format is blob' do
      it_behaves_like 'static object request' do
        let_it_be(:path) { 'project/raw/master/README.md' }
        let_it_be(:format) { :blob }
      end
    end

    context 'when request format is not archive nor blob' do
      before do
        set_header('script_name', 'url')
      end

      it 'returns nil' do
        expect(find_user_from_static_object_token(:foo)).to be_nil
      end
    end
  end

  describe '#deploy_token_from_request' do
    let_it_be(:deploy_token, freeze: true) { create(:deploy_token) }
    let_it_be(:route_authentication_setting) { { deploy_token_allowed: true } }

    subject { deploy_token_from_request }

    it { is_expected.to be_nil }

    shared_examples 'an unauthenticated route' do
      context 'when route is not allowed to use deploy_tokens' do
        let(:route_authentication_setting) { { deploy_token_allowed: false } }

        it { is_expected.to be_nil }
      end
    end

    context 'with deploy token headers' do
      context 'with valid deploy token' do
        before do
          set_header(described_class::DEPLOY_TOKEN_HEADER, deploy_token.token)
        end

        it { is_expected.to eq deploy_token }
      end

      it_behaves_like 'an unauthenticated route'

      context 'with incorrect token' do
        before do
          set_header(described_class::DEPLOY_TOKEN_HEADER, 'invalid_token')
        end

        it { is_expected.to be_nil }
      end
    end

    context 'with oauth headers' do
      context 'with valid token' do
        before do
          set_bearer_token(deploy_token.token)
        end

        it { is_expected.to eq deploy_token }

        it_behaves_like 'an unauthenticated route'
      end

      context 'with invalid token' do
        before do
          set_bearer_token('invalid_token')
        end

        it { is_expected.to be_nil }
      end
    end

    context 'with basic auth headers' do
      before do
        set_basic_auth_header(deploy_token.username, deploy_token.token)
      end

      it { is_expected.to eq deploy_token }

      it_behaves_like 'an unauthenticated route'

      context 'with incorrect token' do
        before do
          set_basic_auth_header(deploy_token.username, 'invalid')
        end

        it { is_expected.to be_nil }
      end
    end

    context 'when the the deploy token is restricted with external_authorization' do
      before do
        allow(Gitlab::ExternalAuthorization).to receive(:allow_deploy_tokens_and_deploy_keys?).and_return(false)
        set_header(described_class::DEPLOY_TOKEN_HEADER, deploy_token.token)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#find_user_from_access_token' do
    before do
      set_header('SCRIPT_NAME', 'url.atom')
    end

    it 'returns nil if no access_token present' do
      expect(find_user_from_access_token).to be_nil
    end

    context 'when run for kubernetes internal API endpoint' do
      before do
        set_bearer_token('AgentToken')
        set_header('SCRIPT_NAME', '/api/v4/internal/kubernetes/modules/starboard_vulnerability/policies_configuration')
      end

      it 'returns nil' do
        expect(find_user_from_access_token).to be_nil
      end
    end

    context 'when validate_access_token! returns valid' do
      it 'returns user' do
        set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)

        expect(find_user_from_access_token).to eq user
      end

      it 'returns exception if token has no user' do
        set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)
        allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

        expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'with OAuth headers' do
      context 'with valid personal access token' do
        before do
          set_bearer_token(personal_access_token.token)
        end

        it 'returns user' do
          expect(find_user_from_access_token).to eq user
        end
      end

      context 'with invalid personal_access_token' do
        before do
          set_bearer_token('invalid_20byte_token')
        end

        it 'returns exception' do
          expect { find_personal_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end

      context 'when using a non-prefixed access token' do
        let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, :no_prefix, user: user) }

        before do
          set_bearer_token(personal_access_token.token)
        end

        it 'returns user' do
          expect(find_user_from_access_token).to eq user
        end
      end
    end

    context 'automatic reuse detection' do
      let(:token_3) { create(:personal_access_token, :revoked) }
      let(:token_2) { create(:personal_access_token, :revoked, previous_personal_access_token_id: token_3.id) }
      let(:token_1) { create(:personal_access_token, previous_personal_access_token_id: token_2.id) }

      context 'when a revoked token is used' do
        before do
          set_bearer_token(token_3.token)
        end

        context 'with url related to access tokens' do
          before do
            set_header('SCRIPT_NAME', "/personal_access_tokens/#{token_3.id}/rotate")
          end

          it 'revokes the latest rotated token' do
            expect(token_1).not_to be_revoked

            expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::RevokedError)

            expect(token_1.reload).to be_revoked
          end
        end

        context 'with url not related to access tokens' do
          before do
            set_header('SCRIPT_NAME', '/epics/1')
          end

          it 'does not revoke the latest rotated token' do
            expect(token_1).not_to be_revoked

            expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::RevokedError)

            expect(token_1.reload).not_to be_revoked
          end
        end
      end
    end
  end

  describe '#find_user_from_web_access_token' do
    before do
      set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)
    end

    it 'returns exception if token has no user' do
      allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

      expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end

    context 'no feed, API, archive or download requests' do
      it 'returns nil if the request is not RSS' do
        expect(find_user_from_web_access_token(:rss)).to be_nil
      end

      it 'returns nil if the request is not ICS' do
        expect(find_user_from_web_access_token(:ics)).to be_nil
      end

      it 'returns nil if the request is not API' do
        expect(find_user_from_web_access_token(:api)).to be_nil
      end

      it 'returns nil if the request is not ARCHIVE' do
        expect(find_user_from_web_access_token(:archive)).to be_nil
      end

      it 'returns nil if the request is not DOWNLOAD' do
        expect(find_user_from_web_access_token(:download)).to be_nil
      end
    end

    it 'returns the user for RSS requests' do
      set_header('SCRIPT_NAME', 'url.atom')

      expect(find_user_from_web_access_token(:rss)).to eq(user)
    end

    it 'returns the user for ICS requests' do
      set_header('SCRIPT_NAME', 'url.ics')

      expect(find_user_from_web_access_token(:ics)).to eq(user)
    end

    it 'returns the user for ARCHIVE requests' do
      set_header('SCRIPT_NAME', '/-/archive/main.zip')

      expect(find_user_from_web_access_token(:archive)).to eq(user)
    end

    it 'returns the user for DOWNLOAD requests' do
      set_header('SCRIPT_NAME', '/-/1.0.0/downloads/main.zip')

      expect(find_user_from_web_access_token(:download)).to eq(user)
    end

    context 'for API requests' do
      it 'returns the user' do
        set_header('SCRIPT_NAME', '/api/endpoint')

        expect(find_user_from_web_access_token(:api)).to eq(user)
      end

      it 'returns nil if URL does not start with /api/' do
        set_header('SCRIPT_NAME', '/relative_root/api/endpoint')

        expect(find_user_from_web_access_token(:api)).to be_nil
      end

      context 'when the token has read_api scope' do
        let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user, scopes: ['read_api']) }

        before do
          set_header('SCRIPT_NAME', '/api/endpoint')
        end

        it 'raises InsufficientScopeError by default' do
          expect { find_user_from_web_access_token(:api) }.to raise_error(Gitlab::Auth::InsufficientScopeError)
        end

        it 'finds the user when the read_api scope is passed' do
          expect(find_user_from_web_access_token(:api, scopes: [:api, :read_api])).to eq(user)
        end
      end

      context 'when relative_url_root is set' do
        before do
          stub_config_setting(relative_url_root: '/relative_root')
        end

        it 'returns the user' do
          set_header('SCRIPT_NAME', '/relative_root/api/endpoint')

          expect(find_user_from_web_access_token(:api)).to eq(user)
        end
      end
    end
  end

  describe '#find_personal_access_token' do
    before do
      set_header('SCRIPT_NAME', 'url.atom')
    end

    context 'passed as header' do
      it 'returns token if valid personal_access_token' do
        set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)

        expect(find_personal_access_token).to eq personal_access_token
      end
    end

    context 'passed as param' do
      it 'returns token if valid personal_access_token' do
        set_param(described_class::PRIVATE_TOKEN_PARAM, personal_access_token.token)

        expect(find_personal_access_token).to eq personal_access_token
      end
    end

    it 'returns nil if no personal_access_token' do
      expect(find_personal_access_token).to be_nil
    end

    it 'returns exception if invalid personal_access_token' do
      set_header(described_class::PRIVATE_TOKEN_HEADER, 'invalid_token')

      expect { find_personal_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#find_oauth_access_token' do
    let_it_be(:oauth_application) { create(:oauth_application, owner: user) }
    let(:scopes) { 'api' }
    let(:oauth_access_token) do
      create(:oauth_access_token,
        application_id: oauth_application.id,
        resource_owner_id: user.id,
        scopes: scopes,
        organization_id: organization.id)
    end

    context 'passed as header' do
      before do
        set_bearer_token(oauth_access_token.plaintext_token)
      end

      it 'returns token if valid oauth_access_token' do
        expect(find_oauth_access_token.token).to eq oauth_access_token.token
      end
    end

    context 'passed as param' do
      it 'returns user if valid oauth_access_token' do
        set_param(:access_token, oauth_access_token.plaintext_token)

        expect(find_oauth_access_token.token).to eq oauth_access_token.token
      end
    end

    it 'returns nil if no oauth_access_token' do
      expect(find_oauth_access_token).to be_nil
    end

    context 'with invalid token' do
      before do
        set_bearer_token('invalid_token')
      end

      it 'returns exception if invalid oauth_access_token' do
        expect { find_oauth_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'with composite identity', :request_store do
      let_it_be(:user) { create(:user, username: 'user-with-composite-identity') }

      before do
        allow_any_instance_of(::User).to receive(:composite_identity_enforced) do |user|
          user.username == 'user-with-composite-identity'
        end

        set_bearer_token(oauth_access_token.plaintext_token)
      end

      context 'when scoped user is specified' do
        let(:scopes) { "user:#{user.id}" }

        context 'when linking composite identitiy succeeds' do
          it 'returns the oauth token' do
            expect(find_oauth_access_token.token).to eq(oauth_access_token.token)
          end
        end

        context 'when linking composite identity raises an error' do
          before do
            allow(Gitlab::Auth::Identity).to(
              receive(:link_from_oauth_token).and_raise(::Gitlab::Auth::Identity::IdentityLinkMismatchError)
            )
          end

          it 'raises an error' do
            expect { find_oauth_access_token }.to raise_error(::Gitlab::Auth::Identity::IdentityLinkMismatchError)
          end
        end
      end

      context 'when composite identity link can not be created' do
        let(:scopes) { 'api' }

        it 'raises an exception' do
          expect { find_oauth_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end
  end

  describe '#find_personal_access_token_from_http_basic_auth' do
    def auth_header_with(token)
      set_basic_auth_header('username', token)
    end

    context 'access token is valid' do
      let(:route_authentication_setting) { { basic_auth_personal_access_token: true } }

      it 'finds the token from basic auth' do
        auth_header_with(personal_access_token.token)

        expect(find_personal_access_token_from_http_basic_auth).to eq personal_access_token
      end
    end

    context 'access token is not valid' do
      let(:route_authentication_setting) { { basic_auth_personal_access_token: true } }

      it 'returns nil' do
        auth_header_with('failing_token')

        expect(find_personal_access_token_from_http_basic_auth).to be_nil
      end
    end

    context 'route_setting is not set' do
      it 'returns nil' do
        auth_header_with(personal_access_token.token)

        expect(find_personal_access_token_from_http_basic_auth).to be_nil
      end
    end

    context 'route_setting is not correct' do
      let(:route_authentication_setting) { { basic_auth_personal_access_token: false } }

      it 'returns nil' do
        auth_header_with(personal_access_token.token)

        expect(find_personal_access_token_from_http_basic_auth).to be_nil
      end
    end
  end

  describe '#find_user_from_job_token_basic_auth' do
    subject { find_user_from_job_token_basic_auth }

    context 'when the request does not have AUTHORIZATION header' do
      it { is_expected.to be_nil }
    end

    context 'with wrong credentials' do
      it 'returns nil without user and password' do
        set_basic_auth_header(nil, nil)

        is_expected.to be_nil
      end

      it 'returns nil without password' do
        set_basic_auth_header('some-user', nil)

        is_expected.to be_nil
      end

      it 'returns nil without user' do
        set_basic_auth_header(nil, 'password')

        is_expected.to be_nil
      end

      it 'returns nil without CI username' do
        set_basic_auth_header('user', 'password')

        is_expected.to be_nil
      end
    end

    context 'with CI username' do
      let(:username) { ::Gitlab::Auth::CI_JOB_USER }

      before do
        set_basic_auth_header(username, token)
      end

      it_behaves_like 'find user from job token', :user
    end
  end

  describe '#find_user_from_basic_auth_password' do
    subject { find_user_from_basic_auth_password }

    context 'when the request does not have AUTHORIZATION header' do
      it { is_expected.to be_nil }
    end

    it 'returns nil without user and password' do
      set_basic_auth_header(nil, nil)

      is_expected.to be_nil
    end

    it 'returns nil without password' do
      set_basic_auth_header('some-user', nil)

      is_expected.to be_nil
    end

    it 'returns nil without user' do
      set_basic_auth_header(nil, 'password')

      is_expected.to be_nil
    end

    it 'returns nil with CI username' do
      set_basic_auth_header(::Gitlab::Auth::CI_JOB_USER, 'password')

      is_expected.to be_nil
    end

    it 'returns nil with wrong password' do
      set_basic_auth_header(user.username, 'wrong-password')

      is_expected.to be_nil
    end

    it 'returns user with correct credentials' do
      set_basic_auth_header(user.username, user.password)

      is_expected.to eq(user)
    end
  end

  describe '#find_user_from_lfs_token' do
    subject { find_user_from_lfs_token }

    context 'when the request does not have AUTHORIZATION header' do
      it { is_expected.to be_nil }
    end

    it 'returns nil without user and token' do
      set_basic_auth_header(nil, nil)

      is_expected.to be_nil
    end

    it 'returns nil without token' do
      set_basic_auth_header('some-user', nil)

      is_expected.to be_nil
    end

    it 'returns nil without user' do
      set_basic_auth_header(nil, 'token')

      is_expected.to be_nil
    end

    it 'returns nil with wrong token' do
      set_basic_auth_header(user.username, 'wrong-token')

      is_expected.to be_nil
    end

    it 'returns user with correct user and correct token' do
      lfs_token = Gitlab::LfsToken.new(user, nil).token
      set_basic_auth_header(user.username, lfs_token)

      is_expected.to eq(user)
    end

    it 'returns user even if the project does not belong to the user' do
      another_project = create(:project)

      lfs_token = Gitlab::LfsToken.new(user, another_project).token
      set_basic_auth_header(user.username, lfs_token)

      is_expected.to eq(user)
    end

    it 'returns nil with wrong user and correct token' do
      lfs_token = Gitlab::LfsToken.new(user, nil).token
      other_user = create(:user)
      set_basic_auth_header(other_user.username, lfs_token)

      is_expected.to be_nil
    end
  end

  describe '#find_user_from_personal_access_token' do
    subject { find_user_from_personal_access_token }

    it 'returns nil without access token' do
      allow_any_instance_of(described_class).to receive(:access_token).and_return(nil)

      is_expected.to be_nil
    end

    it 'returns user with correct access token' do
      personal_access_token = create(:personal_access_token, user: user)
      allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)

      is_expected.to eq(user)
    end

    it 'returns exception if access token has no user' do
      personal_access_token = create(:personal_access_token, user: user)
      allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
      allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

      expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#validate_access_token!' do
    subject { validate_and_save_access_token! }

    context 'with a job token' do
      let(:route_authentication_setting) { { job_token_allowed: true } }

      before do
        env['HTTP_AUTHORIZATION'] = "Bearer #{job.token}"
        find_user_from_bearer_token
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    it 'returns nil if no access_token present' do
      expect(validate_and_save_access_token!).to be_nil
    end

    context 'with a personal access token' do
      let_it_be_with_reload(:personal_access_token) { create(:personal_access_token, user: user) }

      before do
        allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
      end

      it 'saves the token info in the environment' do
        subject

        expect(::Current.token_info).not_to be_nil
      end

      context 'when the token is not valid' do
        it 'returns Gitlab::Auth::ExpiredError if token expired', :aggregate_failures do
          personal_access_token.update!(expires_at: 1.day.ago)

          expect { validate_and_save_access_token!(scopes: %w[api read_api]) }.to raise_error(Gitlab::Auth::ExpiredError)
          expect(::Current.token_info).to be_nil
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_reason']).to eq('token_expired')
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{personal_access_token.id}")
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_requested_scopes']).to eq("api read_api")
        end

        it 'returns Gitlab::Auth::RevokedError if token revoked', :aggregate_failures do
          personal_access_token.revoke!

          expect { validate_and_save_access_token! }.to raise_error(Gitlab::Auth::RevokedError)
          expect(::Current.token_info).to be_nil
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_reason']).to eq('token_revoked')
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{personal_access_token.id}")
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_requested_scopes']).to be_nil
        end

        it 'returns Gitlab::Auth::InsufficientScopeError if invalid token scope', :aggregate_failures do
          expect { validate_and_save_access_token!(scopes: [:sudo]) }.to raise_error(Gitlab::Auth::InsufficientScopeError)
          expect(::Current.token_info).to be_nil
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_reason']).to eq('insufficient_scope')
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{personal_access_token.id}")
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_requested_scopes']).to eq('sudo')
        end
      end
    end

    context 'with impersonation token' do
      let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, :impersonation, user: user) }

      context 'when impersonation is disabled' do
        before do
          stub_config_setting(impersonation_enabled: false)
          allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
        end

        it 'returns Gitlab::Auth::ImpersonationDisabled' do
          expect { validate_and_save_access_token! }.to raise_error(Gitlab::Auth::ImpersonationDisabled)
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_reason']).to eq('impersonation_disabled')
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{personal_access_token.id}")
          expect(Gitlab::ApplicationContext.current['meta.auth_fail_requested_scopes']).to be_nil
        end
      end
    end
  end

  describe '#find_user_from_job_token' do
    let(:token) { job.token }

    subject { find_user_from_job_token }

    shared_examples 'finds user when job token allowed' do
      context 'when the token is in the headers' do
        before do
          set_header(described_class::JOB_TOKEN_HEADER, token)
        end

        it_behaves_like 'find user from job token'
      end

      context 'when the token is in the job_token param' do
        before do
          set_param(described_class::JOB_TOKEN_PARAM, token)
        end

        it_behaves_like 'find user from job token'
      end

      context 'when the token is in the token param' do
        before do
          set_param(described_class::RUNNER_JOB_TOKEN_PARAM, token)
        end

        it_behaves_like 'find user from job token'
      end
    end

    context 'for route_authentication_setting[job_token_allowed]' do
      using RSpec::Parameterized::TableSyntax

      where(:route_setting, :expect_user_via_request, :expect_user_via_basic_auth) do
        true                    | true  | false
        :request                | true  | false
        [:request]              | true  | false
        :basic_auth             | false | true
        [:basic_auth]           | false | true
        [:request, :basic_auth] | true  | true

        # unexpected values
        :foo                    | false | false
        [:foo]                  | false | false
        [:foo, :bar]            | false | false
      end

      with_them do
        let(:route_authentication_setting) { { job_token_allowed: route_setting } }

        context 'when the token is in the headers' do
          before do
            set_header(described_class::JOB_TOKEN_HEADER, token)
          end

          it { is_expected.to eq(expect_user_via_request ? user : nil) }
        end

        context 'when the token is in the job_token param' do
          before do
            set_param(described_class::JOB_TOKEN_PARAM, token)
          end

          it { is_expected.to eq(expect_user_via_request ? user : nil) }
        end

        context 'when the token is in the token param' do
          before do
            set_param(described_class::RUNNER_JOB_TOKEN_PARAM, token)
          end

          it { is_expected.to eq(expect_user_via_request ? user : nil) }
        end

        context 'when the token is in basic auth header' do
          before do
            set_basic_auth_header(::Gitlab::Auth::CI_JOB_USER, token)
          end

          it { is_expected.to eq(expect_user_via_basic_auth ? user : nil) }
        end
      end
    end

    context 'when route setting allows job_token' do
      let(:route_authentication_setting) { { job_token_allowed: true } }

      include_examples 'finds user when job token allowed'
    end

    context 'when route setting is basic auth' do
      let(:route_authentication_setting) { { job_token_allowed: :basic_auth } }

      context 'when the token is provided via basic auth' do
        let(:username) { ::Gitlab::Auth::CI_JOB_USER }

        before do
          set_basic_auth_header(username, token)
        end

        it { is_expected.to eq(user) }
      end

      include_examples 'finds user when job token allowed'
    end

    context 'when route setting job_token_allowed is invalid' do
      let(:route_authentication_setting) { { job_token_allowed: false } }

      context 'when the token is provided' do
        before do
          set_header(described_class::JOB_TOKEN_HEADER, token)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#cluster_agent_token_from_authorization_token' do
    let_it_be_with_reload(:agent_token) { create(:cluster_agent_token) }

    subject { cluster_agent_token_from_authorization_token }

    context 'when route_setting is empty' do
      it { is_expected.to be_nil }
    end

    context 'when route_setting allows cluster agent token' do
      let(:route_authentication_setting) { { cluster_agent_token_allowed: true } }

      context 'Authorization header is empty' do
        it { is_expected.to be_nil }
      end

      context 'Authorization header is incorrect' do
        before do
          request.headers['Authorization'] = 'Bearer ABCD'
        end

        it { is_expected.to be_nil }
      end

      context 'Authorization header is malformed' do
        before do
          request.headers['Authorization'] = 'Bearer'
        end

        it { is_expected.to be_nil }
      end

      context 'Authorization header matches agent token' do
        before do
          request.headers['Authorization'] = "Bearer #{agent_token.token}"
        end

        it { is_expected.to eq(agent_token) }

        context 'agent token has been revoked' do
          before do
            agent_token.revoked!
          end

          it { is_expected.to be_nil }
        end
      end

      context 'when using Gitlab-Agentk-Api-Request header' do
        context 'when the token is incorrect' do
          before do
            request.headers['Gitlab-Agentk-Api-Request'] = 'ABCD'
          end

          it { is_expected.to be_nil }
        end

        context 'when the token is correct' do
          before do
            request.headers['Gitlab-Agentk-Api-Request'] = agent_token.token
          end

          it { is_expected.to eq(agent_token) }

          context 'when the token has been revoked' do
            before do
              agent_token.revoked!
            end

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end

  describe '#find_runner_from_token' do
    let_it_be(:runner, freeze: true) { create(:ci_runner) }

    context 'with API requests' do
      before do
        set_header('SCRIPT_NAME', '/api/endpoint')
      end

      it 'returns the runner if token is valid' do
        set_param(:token, runner.token)

        expect(find_runner_from_token).to eq(runner)
      end

      it 'returns nil if token is not present' do
        expect(find_runner_from_token).to be_nil
      end

      it 'returns nil if token is blank' do
        set_param(:token, '')

        expect(find_runner_from_token).to be_nil
      end

      it 'returns exception if invalid token' do
        set_param(:token, 'invalid_token')

        expect { find_runner_from_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'without API requests' do
      before do
        set_header('SCRIPT_NAME', 'url.ics')
      end

      it 'returns nil if token is valid' do
        set_param(:token, runner.token)

        expect(find_runner_from_token).to be_nil
      end

      it 'returns nil if token is blank' do
        expect(find_runner_from_token).to be_nil
      end

      it 'returns nil if invalid token' do
        set_param(:token, 'invalid_token')

        expect(find_runner_from_token).to be_nil
      end
    end
  end

  describe '#authentication_token_present?' do
    subject { authentication_token_present? }

    context 'no auth header/param/oauth' do
      before do
        request.headers['Random'] = 'Something'
        set_param(:random, 'something')
      end

      it { is_expected.to be(false) }
    end

    context 'with auth header' do
      before do
        request.headers[header] = 'invalid'
      end

      context 'with private-token' do
        let(:header) { 'Private-Token' }

        it { is_expected.to be(true) }
      end

      context 'with job-token' do
        let(:header) { 'Job-Token' }

        it { is_expected.to be(true) }
      end

      context 'with deploy-token' do
        let(:header) { 'Deploy-Token' }

        it { is_expected.to be(true) }
      end
    end

    context 'with authorization bearer (oauth token)' do
      before do
        request.headers['Authorization'] = 'Bearer invalid'
      end

      it { is_expected.to be(true) }
    end

    context 'with auth param' do
      context 'with private_token' do
        it 'returns true' do
          set_param(:private_token, 'invalid')

          expect(subject).to be(true)
        end
      end

      context 'with job_token' do
        it 'returns true' do
          set_param(:job_token, 'invalid')

          expect(subject).to be(true)
        end
      end

      context 'with token' do
        it 'returns true' do
          set_param(:token, 'invalid')

          expect(subject).to be(true)
        end
      end
    end
  end
end
