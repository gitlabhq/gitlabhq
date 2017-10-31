require 'spec_helper'

describe 'Rack Attack global throttles' do
  NUM_TRIES_FOR_REJECTION = 3 # Flaky tests, have not figured out how to fix it

  let(:settings) { Gitlab::CurrentSettings.current_application_settings }

  # Start with really high limits and override them with low limits to ensure
  # the right settings are being exercised
  let(:settings_to_set) do
    {
      throttle_unauthenticated_requests_per_period: 100,
      throttle_unauthenticated_period_in_seconds: 1,
      throttle_authenticated_api_requests_per_period: 100,
      throttle_authenticated_api_period_in_seconds: 1,
      throttle_authenticated_web_requests_per_period: 100,
      throttle_authenticated_web_period_in_seconds: 1
    }
  end

  let(:requests_per_period) { 1 }
  let(:period_in_seconds) { 10000 }
  let(:period) { period_in_seconds.seconds }

  # Make time-dependent tests deterministic
  around do |example|
    # Instead of test environment's :null_store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Timecop.freeze { example.run }

    Rack::Attack.cache.store = Rails.cache
  end

  # Requires let variables:
  # * throttle_setting_prefix (e.g. "throttle_authenticated_api" or "throttle_authenticated_web")
  # * get_args
  # * other_user_get_args
  shared_examples_for 'rate-limited token-authenticated requests' do
    before do
      # Set low limits
      settings_to_set[:"#{throttle_setting_prefix}_requests_per_period"] = requests_per_period
      settings_to_set[:"#{throttle_setting_prefix}_period_in_seconds"] = period_in_seconds
    end

    context 'when the throttle is enabled' do
      before do
        settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
        stub_application_setting(settings_to_set)
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get(*get_args)
          expect(response).to have_http_status 200
        end

        # the last straw
        expect_rejection { get(*get_args) }
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get(*get_args)
          expect(response).to have_http_status 200
        end

        expect_rejection { get(*get_args) }

        Timecop.travel((1.second + period).from_now) do # Add 1 because flaky
          requests_per_period.times do
            get(*get_args)
            expect(response).to have_http_status 200
          end

          expect_rejection { get(*get_args) }
        end
      end

      it 'counts requests from different users separately, even from the same IP' do
        requests_per_period.times do
          get(*get_args)
          expect(response).to have_http_status 200
        end

        # would be over the limit if this wasn't a different user
        get(*other_user_get_args)
        expect(response).to have_http_status 200
      end

      it 'counts all requests from the same user, even via different IPs' do
        requests_per_period.times do
          get(*get_args)
          expect(response).to have_http_status 200
        end

        expect_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('1.2.3.4')

        expect_rejection { get(*get_args) }
      end
    end

    context 'when the throttle is disabled' do
      before do
        settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
        stub_application_setting(settings_to_set)
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get(*get_args)
          expect(response).to have_http_status 200
        end
      end
    end
  end

  describe 'unauthenticated requests' do
    before do
      # Set low limits
      settings_to_set[:throttle_unauthenticated_requests_per_period] = requests_per_period
      settings_to_set[:throttle_unauthenticated_period_in_seconds] = period_in_seconds
    end

    context 'when the throttle is enabled' do
      before do
        settings_to_set[:throttle_unauthenticated_enabled] = true
        stub_application_setting(settings_to_set)
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end

        # the last straw
        expect_rejection { get '/users/sign_in' }
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end

        expect_rejection { get '/users/sign_in' }

        Timecop.travel((1.second + period).from_now) do # Add 1 because flaky
          requests_per_period.times do
            get '/users/sign_in'
            expect(response).to have_http_status 200
          end

          expect_rejection { get '/users/sign_in' }
        end
      end

      it 'counts requests from different IPs separately' do
        requests_per_period.times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end

        expect_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('1.2.3.4')

        # would be over limit for the same IP
        get '/users/sign_in'
        expect(response).to have_http_status 200
      end
    end

    context 'when the throttle is disabled' do
      before do
        settings_to_set[:throttle_unauthenticated_enabled] = false
        stub_application_setting(settings_to_set)
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end
      end
    end
  end

  describe 'API requests authenticated with private token', :api do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:throttle_setting_prefix) { 'throttle_authenticated_api' }

    context 'with the token in the query string' do
      let(:get_args) { [api('/todos', user)] }
      let(:other_user_get_args) { [api('/todos', other_user)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:get_args) { ["/api/#{API::API.version}/todos", nil, private_token_headers(user)] }
      let(:other_user_get_args) { ["/api/#{API::API.version}/todos", nil, private_token_headers(other_user)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end
  end

  describe 'API requests authenticated with personal access token', :api do
    let(:user) { create(:user) }
    let(:token) { create(:personal_access_token, user: user) }
    let(:other_user) { create(:user) }
    let(:other_user_token) { create(:personal_access_token, user: other_user) }
    let(:throttle_setting_prefix) { 'throttle_authenticated_api' }

    context 'with the token in the query string' do
      let(:get_args) { [api('/todos', personal_access_token: token)] }
      let(:other_user_get_args) { [api('/todos', personal_access_token: other_user_token)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:get_args) { ["/api/#{API::API.version}/todos", nil, personal_access_token_headers(token)] }
      let(:other_user_get_args) { ["/api/#{API::API.version}/todos", nil, personal_access_token_headers(other_user_token)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end
  end

  describe 'API requests authenticated with OAuth token', :api do
    let(:user) { create(:user) }
    let(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }
    let(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "api") }
    let(:other_user) { create(:user) }
    let(:other_user_application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: other_user) }
    let(:other_user_token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: other_user.id, scopes: "api") }
    let(:throttle_setting_prefix) { 'throttle_authenticated_api' }

    context 'with the token in the query string' do
      let(:get_args) { [api('/todos', oauth_access_token: token)] }
      let(:other_user_get_args) { [api('/todos', oauth_access_token: other_user_token)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:get_args) { ["/api/#{API::API.version}/todos", nil, oauth_token_headers(token)] }
      let(:other_user_get_args) { ["/api/#{API::API.version}/todos", nil, oauth_token_headers(other_user_token)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end
  end

  describe '"web" (non-API) requests authenticated with RSS token' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:throttle_setting_prefix) { 'throttle_authenticated_web' }

    context 'with the token in the query string' do
      context 'with the atom extension' do
        let(:get_args) { ["/dashboard/projects.atom?rss_token=#{user.rss_token}"] }
        let(:other_user_get_args) { ["/dashboard/projects.atom?rss_token=#{other_user.rss_token}"] }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'with the atom format in the Accept header' do
        let(:get_args) { ["/dashboard/projects?rss_token=#{user.rss_token}", nil, { 'HTTP_ACCEPT' => 'application/atom+xml' }] }
        let(:other_user_get_args) { ["/dashboard/projects?rss_token=#{other_user.rss_token}", nil, { 'HTTP_ACCEPT' => 'application/atom+xml' }] }

        it_behaves_like 'rate-limited token-authenticated requests'
      end
    end
  end

  describe 'web requests authenticated with regular login' do
    let(:user) { create(:user) }

    before do
      login_as(user)

      # Set low limits
      settings_to_set[:throttle_authenticated_web_requests_per_period] = requests_per_period
      settings_to_set[:throttle_authenticated_web_period_in_seconds] = period_in_seconds
    end

    context 'when the throttle is enabled' do
      before do
        settings_to_set[:throttle_authenticated_web_enabled] = true
        stub_application_setting(settings_to_set)
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end

        # the last straw
        expect_rejection { get '/dashboard/snippets' }
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end

        expect_rejection { get '/dashboard/snippets' }

        Timecop.travel((1.second + period).from_now) do # Add 1 because flaky
          requests_per_period.times do
            get '/dashboard/snippets'
            expect(response).to have_http_status 200
          end

          expect_rejection { get '/dashboard/snippets' }
        end
      end

      it 'counts requests from different users separately, even from the same IP' do
        requests_per_period.times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end

        # would be over the limit if this wasn't a different user
        login_as(create(:user))

        get '/dashboard/snippets'
        expect(response).to have_http_status 200
      end

      it 'counts all requests from the same user, even via different IPs' do
        requests_per_period.times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end

        expect_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('1.2.3.4')

        expect_rejection { get '/dashboard/snippets' }
      end
    end

    context 'when the throttle is disabled' do
      before do
        settings_to_set[:throttle_authenticated_web_enabled] = false
        stub_application_setting(settings_to_set)
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end
      end
    end
  end

  def private_token_headers(user)
    { 'HTTP_PRIVATE_TOKEN' => user.private_token }
  end

  def personal_access_token_headers(personal_access_token)
    { 'HTTP_PRIVATE_TOKEN' => personal_access_token.token }
  end

  def oauth_token_headers(oauth_access_token)
    { 'AUTHORIZATION' => "Bearer #{oauth_access_token.token}" }
  end

  def expect_rejection(&block)
    NUM_TRIES_FOR_REJECTION.times do |i|
      yield
      break if response.status == 429 # success
      Rails.logger.warn "Flaky test expected HTTP status 429 but got #{response.status}. Will attempt again (#{i + 1}/#{NUM_TRIES_FOR_REJECTION})"
    end

    expect(response).to have_http_status(429)
  end
end
