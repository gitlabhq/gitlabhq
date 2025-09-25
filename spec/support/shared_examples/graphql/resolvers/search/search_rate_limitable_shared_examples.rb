# frozen_string_literal: true

RSpec.shared_examples 'search rate is limitable' do
  context 'when current_user is nil' do
    context 'when request is throttled' do
      it 'ApplicationRateLimiter receives key as search_rate_limit_unauthenticated and API returns an error' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(
          anything, nil, :search_rate_limit_unauthenticated, scope: anything, users_allowlist: nil
        ).and_return(true)
        post_graphql(query)
        expect_graphql_errors_to_include(%r{This endpoint has been requested too many times. Try again later.})
      end
    end

    context 'when request is not throttled' do
      it 'ApplicationRateLimiter receives key as search_rate_limit_unauthenticated and API returns no error' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(
          anything, nil, :search_rate_limit_unauthenticated, scope: anything, users_allowlist: nil
        ).and_return(false)
        post_graphql(query)
        expect_graphql_errors_to_be_empty
      end
    end
  end

  context 'when current_user is present' do
    context 'when request is throttled' do
      it 'ApplicationRateLimiter receives key as search_rate_limit and API returns an error' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?)
          .with(anything,
            current_user,
            :search_rate_limit,
            scope: anything,
            users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist
          ).and_return(true)
        post_graphql(query, current_user: current_user)
        expect_graphql_errors_to_include(%r{This endpoint has been requested too many times. Try again later.})
      end
    end

    context 'when request is not throttled' do
      it 'ApplicationRateLimiter receives key as search_rate_limit and API returns no error' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?)
          .with(anything,
            current_user,
            :search_rate_limit,
            scope: anything,
            users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist
          ).and_return(false)
        post_graphql(query, current_user: current_user)
        expect_graphql_errors_to_be_empty
      end
    end
  end
end
