# frozen_string_literal: true
#
# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated_api", "throttle_authenticated_web", "throttle_protected_paths"
# * get_args
# * other_user_get_args
# * requests_per_period
# * period_in_seconds
# * period
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

      Timecop.travel(period.from_now) do
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

    it 'logs RackAttack info into structured logs' do
      requests_per_period.times do
        get(*get_args)
        expect(response).to have_http_status 200
      end

      arguments = {
        message: 'Rack_Attack',
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: 'GET',
        path: get_args.first,
        user_id: user.id,
        username: user.username
      }

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments).once

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

# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated_web" or "throttle_protected_paths"
# * user
# * url_that_requires_authentication
# * requests_per_period
# * period_in_seconds
# * period
shared_examples_for 'rate-limited web authenticated requests' do
  before do
    login_as(user)

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
        get url_that_requires_authentication
        expect(response).to have_http_status 200
      end

      # the last straw
      expect_rejection { get url_that_requires_authentication }
    end

    it 'allows requests after throttling and then waiting for the next period' do
      requests_per_period.times do
        get url_that_requires_authentication
        expect(response).to have_http_status 200
      end

      expect_rejection { get url_that_requires_authentication }

      Timecop.travel(period.from_now) do
        requests_per_period.times do
          get url_that_requires_authentication
          expect(response).to have_http_status 200
        end

        expect_rejection { get url_that_requires_authentication }
      end
    end

    it 'counts requests from different users separately, even from the same IP' do
      requests_per_period.times do
        get url_that_requires_authentication
        expect(response).to have_http_status 200
      end

      # would be over the limit if this wasn't a different user
      login_as(create(:user))

      get url_that_requires_authentication
      expect(response).to have_http_status 200
    end

    it 'counts all requests from the same user, even via different IPs' do
      requests_per_period.times do
        get url_that_requires_authentication
        expect(response).to have_http_status 200
      end

      expect_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('1.2.3.4')

      expect_rejection { get url_that_requires_authentication }
    end

    it 'logs RackAttack info into structured logs' do
      requests_per_period.times do
        get url_that_requires_authentication
        expect(response).to have_http_status 200
      end

      arguments = {
        message: 'Rack_Attack',
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: 'GET',
        path: '/dashboard/snippets',
        user_id: user.id,
        username: user.username
      }

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments).once

      get url_that_requires_authentication
    end
  end

  context 'when the throttle is disabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        get url_that_requires_authentication
        expect(response).to have_http_status 200
      end
    end
  end
end
