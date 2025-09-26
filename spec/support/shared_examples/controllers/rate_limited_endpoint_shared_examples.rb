# frozen_string_literal: true

#
# Requires a context containing:
# - request (use method definition to avoid memoizing!)
# - request_with_second_scope # required when use_second_scope is true - use to ensure correct rate limiting by scope
# - current_user
# - error_message # optional

RSpec.shared_examples 'rate limited endpoint' do |rate_limit_key:, graphql: false, with_redirect: false,
  use_second_scope: false|
  let(:error_message) { _('This endpoint has been requested too many times. Try again later.') }

  context 'when rate limiter enabled', :freeze_time, :clean_gitlab_redis_rate_limiting do
    let(:expected_logger_attributes) do
      {
        message: 'Application_Rate_Limiter_Request',
        env: :"#{rate_limit_key}_request_limit",
        remote_ip: kind_of(String),
        method: kind_of(String),
        path: kind_of(String)
      }.merge(expected_user_attributes)
    end

    let(:expected_user_attributes) do
      if defined?(current_user) && current_user.present?
        { user_id: current_user.id, username: current_user.username }
      else
        {}
      end
    end

    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).and_call_original
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(rate_limit_key).and_return(1)
    end

    it 'logs request and declines it when endpoint called more than the threshold for the same scope' do
      allow(Gitlab::AuthLogger).to receive(:error)

      request
      expect(Gitlab::AuthLogger).not_to have_received(:error)

      request
      expect(Gitlab::AuthLogger).to have_received(:error).with(expected_logger_attributes).once

      if graphql
        expect_graphql_errors_to_include(error_message)
      elsif with_redirect
        expect(response).to be_redirect
        expect(flash[:alert]).to eq(error_message)
      else
        expect(response).to have_gitlab_http_status(:too_many_requests)

        if response.content_type == 'application/json' # it is API spec
          expect(response.body).to eq({ message: { error: error_message } }.to_json)
        else
          expect(response.body).to eq(error_message)
        end
      end

      if use_second_scope
        expect(Gitlab::AuthLogger).not_to receive(:error)
        request_with_second_scope
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  context 'when rate limiter is disabled' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).and_call_original
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(rate_limit_key).and_return(0)
    end

    it 'does not log request and does not block the request' do
      expect(Gitlab::AuthLogger).not_to receive(:error)

      request

      if graphql
        expect_graphql_errors_to_be_empty
      else
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end

RSpec.shared_examples 'unthrottled endpoint' do |graphql: false|
  let(:error_message) { _('This endpoint has been requested too many times. Try again later.') }

  context 'when rate limiter enabled', :freeze_time, :clean_gitlab_redis_rate_limiting do
    it 'does not log request and accepts it when endpoint called more than the threshold' do
      expect(Gitlab::ApplicationRateLimiter).not_to receive(:threshold)
      expect(Gitlab::AuthLogger).not_to receive(:error)

      request
      request

      if graphql
        expect(flattened_errors).not_to include(error_message)
      else
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
