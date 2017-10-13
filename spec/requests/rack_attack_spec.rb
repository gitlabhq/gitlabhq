require 'spec_helper'

describe Rack::Attack do
  let(:settings) { Gitlab::CurrentSettings.current_application_settings }

  before do
    # Instead of test environment's :null_store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    # Start with really high limits to ensure the right settings are being exercised.
    # Also note, settings will be saved later.
    settings.throttle_unauthenticated_requests_per_period = 100
    settings.throttle_unauthenticated_period_in_seconds = 1
    settings.throttle_authenticated_api_requests_per_period = 100
    settings.throttle_authenticated_api_period_in_seconds = 1
    settings.throttle_authenticated_web_requests_per_period = 100
    settings.throttle_authenticated_web_period_in_seconds = 1
  end

  # Make time-dependent tests deterministic
  around do |example|
    Timecop.freeze { example.run }
  end

  describe 'unauthenticated requests' do
    let(:requests_per_period) { settings.throttle_unauthenticated_requests_per_period }
    let(:period) { settings.throttle_unauthenticated_period_in_seconds.seconds }

    before do
      # Set low limits
      settings.throttle_unauthenticated_requests_per_period = 1
      settings.throttle_unauthenticated_period_in_seconds = 10
    end

    context 'when the throttle is enabled' do
      before do
        settings.throttle_unauthenticated_enabled = true
        settings.save!
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end

        # the last straw
        get '/users/sign_in'
        expect(response).to have_http_status 429
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end

        get '/users/sign_in'
        expect(response).to have_http_status 429

        Timecop.travel(period.from_now) do
          requests_per_period.times do
            get '/users/sign_in'
            expect(response).to have_http_status 200
          end

          get '/users/sign_in'
          expect(response).to have_http_status 429
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
        settings.throttle_unauthenticated_enabled = false
        settings.save!
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get '/users/sign_in'
          expect(response).to have_http_status 200
        end
      end
    end
  end

  describe 'authenticated API requests', :api do
    let(:requests_per_period) { settings.throttle_authenticated_api_requests_per_period }
    let(:period) { settings.throttle_authenticated_api_period_in_seconds.seconds }
    let(:user) { create(:user) }

    before do
      # Set low limits
      settings.throttle_authenticated_api_requests_per_period = 1
      settings.throttle_authenticated_api_period_in_seconds = 10
    end

    context 'when the throttle is enabled' do
      before do
        settings.throttle_authenticated_api_enabled = true
        settings.save!
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get api('/todos', user)
          expect(response).to have_http_status 200
        end

        # the last straw
        get api('/todos', user)
        expect(response).to have_http_status 429
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get api('/todos', user)
          expect(response).to have_http_status 200
        end

        get api('/todos', user)
        expect(response).to have_http_status 429

        Timecop.travel(period.from_now) do
          requests_per_period.times do
            get api('/todos', user)
            expect(response).to have_http_status 200
          end

          get api('/todos', user)
          expect(response).to have_http_status 429
        end
      end

      it 'counts requests from different users separately, even from the same IP' do
        other_user = create(:user)

        requests_per_period.times do
          get api('/todos', user)
          expect(response).to have_http_status 200
        end

        # would be over the limit if this wasn't a different user
        get api('/todos', other_user)
        expect(response).to have_http_status 200
      end

      it 'counts all requests from the same user, even via different IPs' do
        requests_per_period.times do
          get api('/todos', user)
          expect(response).to have_http_status 200
        end

        expect_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('1.2.3.4')

        get api('/todos', user)
        expect(response).to have_http_status 429
      end
    end

    context 'when the throttle is disabled' do
      before do
        settings.throttle_authenticated_api_enabled = false
        settings.save!
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get api('/todos', user)
          expect(response).to have_http_status 200
        end
      end
    end
  end

  describe 'authenticated web requests' do
    let(:requests_per_period) { settings.throttle_authenticated_web_requests_per_period }
    let(:period) { settings.throttle_authenticated_web_period_in_seconds.seconds }
    let(:user) { create(:user) }

    before do
      login_as(user)

      # Set low limits
      settings.throttle_authenticated_web_requests_per_period = 1
      settings.throttle_authenticated_web_period_in_seconds = 10
    end

    context 'when the throttle is enabled' do
      before do
        settings.throttle_authenticated_web_enabled = true
        settings.save!
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end

        # the last straw
        get '/dashboard/snippets'
        expect(response).to have_http_status 429
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end

        get '/dashboard/snippets'
        expect(response).to have_http_status 429

        Timecop.travel(period.from_now) do
          requests_per_period.times do
            get '/dashboard/snippets'
            expect(response).to have_http_status 200
          end

          get '/dashboard/snippets'
          expect(response).to have_http_status 429
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

        get '/dashboard/snippets'
        expect(response).to have_http_status 429
      end
    end

    context 'when the throttle is disabled' do
      before do
        settings.throttle_authenticated_web_enabled = false
        settings.save!
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get '/dashboard/snippets'
          expect(response).to have_http_status 200
        end
      end
    end
  end
end
