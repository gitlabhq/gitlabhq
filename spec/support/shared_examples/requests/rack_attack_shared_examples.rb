# frozen_string_literal: true
#
# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated_api", "throttle_authenticated_web", "throttle_protected_paths"
# * request_method
# * request_args
# * other_user_request_args
# * requests_per_period
# * period_in_seconds
# * period
shared_examples_for 'rate-limited token-authenticated requests' do
  let(:throttle_types) do
    {
      "throttle_protected_paths" => "throttle_authenticated_protected_paths_api",
      "throttle_authenticated_api" => "throttle_authenticated_api",
      "throttle_authenticated_web" => "throttle_authenticated_web"
    }
  end

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
        make_request(request_args)
        expect(response).not_to have_http_status 429
      end

      # the last straw
      expect_rejection { make_request(request_args) }
    end

    it 'allows requests after throttling and then waiting for the next period' do
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_http_status 429
      end

      expect_rejection { make_request(request_args) }

      Timecop.travel(period.from_now) do
        requests_per_period.times do
          make_request(request_args)
          expect(response).not_to have_http_status 429
        end

        expect_rejection { make_request(request_args) }
      end
    end

    it 'counts requests from different users separately, even from the same IP' do
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_http_status 429
      end

      # would be over the limit if this wasn't a different user
      make_request(other_user_request_args)
      expect(response).not_to have_http_status 429
    end

    it 'counts all requests from the same user, even via different IPs' do
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_http_status 429
      end

      expect_any_instance_of(Rack::Attack::Request).to receive(:ip).at_least(:once).and_return('1.2.3.4')

      expect_rejection { make_request(request_args) }
    end

    it 'logs RackAttack info into structured logs' do
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_http_status 429
      end

      arguments = {
        message: 'Rack_Attack',
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: request_method,
        path: request_args.first,
        user_id: user.id,
        username: user.username,
        throttle_type: throttle_types[throttle_setting_prefix]
      }

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments).once

      expect_rejection { make_request(request_args) }
    end
  end

  context 'when the throttle is disabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        make_request(request_args)
        expect(response).not_to have_http_status 429
      end
    end
  end

  def make_request(args)
    if request_method == 'POST'
      post(*args)
    else
      get(*args)
    end
  end
end

# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated_web" or "throttle_protected_paths"
# * user
# * url_that_requires_authentication
# * request_method
# * requests_per_period
# * period_in_seconds
# * period
shared_examples_for 'rate-limited web authenticated requests' do
  let(:throttle_types) do
    {
      "throttle_protected_paths" => "throttle_authenticated_protected_paths_web",
      "throttle_authenticated_web" => "throttle_authenticated_web"
    }
  end

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
        request_authenticated_web_url
        expect(response).not_to have_http_status 429
      end

      # the last straw
      expect_rejection { request_authenticated_web_url }
    end

    it 'allows requests after throttling and then waiting for the next period' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_http_status 429
      end

      expect_rejection { request_authenticated_web_url }

      Timecop.travel(period.from_now) do
        requests_per_period.times do
          request_authenticated_web_url
          expect(response).not_to have_http_status 429
        end

        expect_rejection { request_authenticated_web_url }
      end
    end

    it 'counts requests from different users separately, even from the same IP' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_http_status 429
      end

      # would be over the limit if this wasn't a different user
      login_as(create(:user))

      request_authenticated_web_url
      expect(response).not_to have_http_status 429
    end

    it 'counts all requests from the same user, even via different IPs' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_http_status 429
      end

      expect_any_instance_of(Rack::Attack::Request).to receive(:ip).at_least(:once).and_return('1.2.3.4')

      expect_rejection { request_authenticated_web_url }
    end

    it 'logs RackAttack info into structured logs' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_http_status 429
      end

      arguments = {
        message: 'Rack_Attack',
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: request_method,
        path: url_that_requires_authentication,
        user_id: user.id,
        username: user.username,
        throttle_type: throttle_types[throttle_setting_prefix]
      }

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments).once

      request_authenticated_web_url
    end
  end

  context 'when the throttle is disabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        request_authenticated_web_url
        expect(response).not_to have_http_status 429
      end
    end
  end

  def request_authenticated_web_url
    if request_method == 'POST'
      post url_that_requires_authentication
    else
      get url_that_requires_authentication
    end
  end
end
