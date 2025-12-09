# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Glql::QueryService, feature_category: :custom_dashboards_foundation do
  let_it_be(:user) { create(:user) }
  let(:query) { 'query { __typename }' }
  let(:original_query) { 'type = issue' }
  let(:variables) { { 'limit' => 10 } }
  let(:context) { { is_sessionless_user: true } }
  let(:request) { instance_double(ActionDispatch::Request, headers: {}) }
  let(:rate_limit_message) do
    'Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope.'
  end

  let(:service) do
    described_class.new(
      current_user: user,
      original_query: original_query,
      request: request,
      current_organization: nil
    )
  end

  before do
    Gitlab::Redis::RateLimiting.with(&:flushdb)
    allow(RequestStore).to receive(:store).and_return({})
  end

  describe '#execute' do
    context 'when GraphQL execution succeeds' do
      let(:graphql_result) do
        {
          'data' => { '__typename' => 'Query' },
          'errors' => nil
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(graphql_result)
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: [{ complexity: 5 }] })
      end

      it 'returns successful result with metrics' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: { '__typename' => 'Query' },
          errors: nil,
          complexity_score: 5,
          timeout_occurred: false,
          rate_limited: false
        )
        expect(result[:duration_s]).to be_a(Float)
      end

      it 'calls LoggingService to log execution metrics' do
        logging_service = instance_double(Analytics::Glql::LoggingService)
        expect(Analytics::Glql::LoggingService).to receive(:new).with(
          current_user: user,
          result: hash_including(
            data: { '__typename' => 'Query' },
            complexity_score: 5,
            timeout_occurred: false
          ),
          query_sha: service.send(:query_sha)
        ).and_return(logging_service)
        expect(logging_service).to receive(:execute)

        service.execute(query: query, variables: variables, context: context)
      end

      it 'calls GitlabSchema.execute with correct parameters' do
        expected_context = {
          current_user: user,
          current_organization: nil,
          request: request,
          is_sessionless_user: true
        }

        expect(GitlabSchema).to receive(:execute).with(
          query,
          variables: variables,
          context: expected_context
        )

        service.execute(query: query, variables: variables, context: context)
      end

      it 'tracks SLI metrics for successful execution' do
        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with(
          labels: hash_including(error_type: nil),
          error: false
        )

        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_apdex).with(
          labels: hash_including(error_type: nil),
          success: true
        )

        service.execute(query: query, variables: variables, context: context)
      end
    end

    context 'when GraphQL execution has errors' do
      let(:graphql_result) do
        {
          'data' => nil,
          'errors' => [{ 'message' => 'Field not found' }]
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(graphql_result)
      end

      it 'returns result with errors' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: nil,
          errors: [{ 'message' => 'Field not found' }],
          timeout_occurred: false,
          rate_limited: false
        )
      end
    end

    context 'when GraphQL execution returns partial data with errors' do
      let(:graphql_result) do
        {
          'data' => { 'user' => { 'id' => '1' } },
          'errors' => [{ 'message' => 'Field error' }]
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(graphql_result)
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: [{ complexity: 8 }] })
      end

      it 'returns both data and errors' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: { 'user' => { 'id' => '1' } },
          errors: [{ 'message' => 'Field error' }],
          complexity_score: 8,
          timeout_occurred: false,
          rate_limited: false
        )
      end
    end

    context 'when ActiveRecord::QueryAborted is raised' do
      before do
        allow(GitlabSchema).to receive(:execute).and_raise(ActiveRecord::QueryAborted)
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: [{ complexity: 3 }] })
      end

      it 'returns timeout result and increments rate limiter' do
        expect(Gitlab::ApplicationRateLimiter).to receive(:peek).and_return(false)
        expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(
          :glql,
          hash_including(scope: service.send(:query_sha))
        )

        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: nil,
          errors: [{ message: 'Query timed out' }],
          timeout_occurred: true,
          rate_limited: false
        )
      end

      it 'calls LoggingService to log timeout' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:peek).and_return(false)
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)

        logging_service = instance_double(Analytics::Glql::LoggingService)
        expect(Analytics::Glql::LoggingService).to receive(:new).with(
          current_user: user,
          result: hash_including(
            timeout_occurred: true,
            complexity_score: 3
          ),
          query_sha: service.send(:query_sha)
        ).and_return(logging_service)
        expect(logging_service).to receive(:execute)

        service.execute(query: query, variables: variables, context: context)
      end

      it 'tracks SLI metrics for timeout' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:peek).and_return(false)
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)

        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with(
          labels: hash_including(error_type: :query_aborted),
          error: true
        )

        service.execute(query: query, variables: variables, context: context)
      end
    end

    context 'when rate limiting is triggered' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:peek).and_return(true)
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: [] })
      end

      it 'returns rate limited result' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: nil,
          errors: [{ message: rate_limit_message }],
          timeout_occurred: false,
          rate_limited: true
        )
      end

      it 'does not execute GraphQL query' do
        expect(GitlabSchema).not_to receive(:execute)

        service.execute(query: query, variables: variables, context: context)
      end
    end

    context 'when other StandardError is raised' do
      let(:error) { StandardError.new('Something went wrong') }

      before do
        allow(GitlabSchema).to receive(:execute).and_raise(error)
      end

      it 'returns error result with exception' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: nil,
          errors: [{ message: 'Something went wrong' }],
          timeout_occurred: false,
          rate_limited: false,
          exception: error
        )
      end

      it 'tracks SLI metrics for other errors' do
        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with(
          labels: hash_including(error_type: :other),
          error: true
        )

        service.execute(query: query, variables: variables, context: context)
      end
    end

    context 'with load balancing enabled', :db_load_balancing do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'data' => { '__typename' => 'Query' }, 'errors' => nil })
      end

      it 'uses load balancing session map' do
        expect(Gitlab::Database::LoadBalancing::SessionMap).to receive(:use_replica_if_available).and_yield

        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: { '__typename' => 'Query' },
          errors: nil,
          timeout_occurred: false,
          rate_limited: false
        )
      end
    end

    context 'when graphql_logs are empty' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { '__typename' => 'Query' }, 'errors' => nil }
        )
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: [] })
      end

      it 'returns result with nil complexity_score' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: { '__typename' => 'Query' },
          complexity_score: nil,
          timeout_occurred: false,
          rate_limited: false
        )
      end
    end

    context 'when graphql_logs have no complexity field' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { '__typename' => 'Query' }, 'errors' => nil }
        )
        allow(RequestStore).to receive(:store).and_return({
          graphql_logs: [{ other_field: 'value' }]
        })
      end

      it 'returns result with nil complexity_score' do
        result = service.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: { '__typename' => 'Query' },
          complexity_score: nil,
          timeout_occurred: false,
          rate_limited: false
        )
      end
    end

    context 'when no graphql_logs in RequestStore during execution' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { '__typename' => 'Query' }, 'errors' => nil }
        )
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: nil })
      end

      it 'does not raise error' do
        expect do
          service.execute(query: query, variables: variables, context: context)
        end.not_to raise_error
      end
    end

    context 'when request has referer header' do
      let(:request_with_referer) do
        instance_double(ActionDispatch::Request, headers: { 'Referer' => 'https://example.com/dashboard' })
      end

      let(:service_with_referer) do
        described_class.new(
          current_user: user,
          original_query: original_query,
          request: request_with_referer,
          current_organization: nil
        )
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { '__typename' => 'Query' }, 'errors' => nil }
        )
        allow(RequestStore).to receive(:store).and_return({
          graphql_logs: [{ complexity: 5 }]
        })
      end

      it 'executes successfully with referer header' do
        result = service_with_referer.execute(query: query, variables: variables, context: context)

        expect(result).to include(
          data: { '__typename' => 'Query' },
          complexity_score: 5,
          timeout_occurred: false,
          rate_limited: false
        )
      end
    end
  end

  describe 'exception handling' do
    it 'defines GlqlQueryLockedError' do
      expect(described_class::GlqlQueryLockedError).to be < StandardError
    end

    it 'can raise and rescue GlqlQueryLockedError' do
      expect do
        raise described_class::GlqlQueryLockedError, 'Test message'
      end.to raise_error(described_class::GlqlQueryLockedError, 'Test message')
    end
  end
end
