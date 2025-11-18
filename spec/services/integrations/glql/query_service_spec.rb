# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Glql::QueryService, feature_category: :integrations do
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
  end

  describe '#query_sha' do
    it 'generates SHA256 hash of original query' do
      expected_sha = Digest::SHA256.hexdigest(original_query)

      expect(service.send(:query_sha)).to eq(expected_sha)
    end
  end

  describe '#build_graphql_context' do
    it 'builds context with base fields' do
      context = service.send(:build_graphql_context, { custom_field: 'value' })

      expect(context).to include(
        current_user: user,
        current_organization: nil,
        request: request,
        custom_field: 'value'
      )
    end
  end

  describe '#extract_complexity_score' do
    context 'when graphql_logs are present in RequestStore' do
      before do
        allow(RequestStore).to receive(:store).and_return({
          graphql_logs: [
            { complexity: 10 },
            { complexity: 15 }
          ]
        })
      end

      it 'returns complexity from last log entry' do
        expect(service.send(:extract_complexity_score)).to eq(15)
      end
    end

    context 'when no graphql_logs in RequestStore' do
      before do
        allow(RequestStore).to receive(:store).and_return({ graphql_logs: nil })
      end

      it 'returns nil' do
        expect(service.send(:extract_complexity_score)).to be_nil
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
