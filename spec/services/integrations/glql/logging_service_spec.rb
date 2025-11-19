# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Glql::LoggingService, feature_category: :integrations do
  let_it_be(:user) { create(:user) }

  let(:glql_query) { 'type = issue and state = opened' }
  let(:generated_graphql) { 'query { workItems { nodes { id title } } }' }
  let(:query_sha) { Digest::SHA256.hexdigest(glql_query) }
  let(:fields) { 'id,title' }
  let(:context) { { project: 'gitlab-org/gitlab' } }
  let(:result) do
    {
      data: { 'workItems' => { 'nodes' => [] } },
      errors: nil,
      complexity_score: 50,
      duration_s: 0.5,
      timeout_occurred: false,
      rate_limited: false
    }
  end

  # Service with GLQL-specific details (API path)
  let(:service_with_glql) do
    described_class.new(
      current_user: user,
      result: result,
      query_sha: query_sha,
      glql_query: glql_query,
      generated_graphql: generated_graphql,
      fields: fields,
      context: context
    )
  end

  # Service without GLQL-specific details (Controller path)
  let(:service_without_glql) do
    described_class.new(
      current_user: user,
      result: result,
      query_sha: query_sha
    )
  end

  let(:service) { service_with_glql }

  describe '#execute' do
    context 'when query times out' do
      let(:result) do
        {
          data: nil,
          errors: [{ message: 'Query timed out' }],
          complexity_score: 150,
          duration_s: 4.0, # Below slow query threshold to avoid triggering slow query log
          timeout_occurred: true,
          rate_limited: false
        }
      end

      it 'logs timeout to GraphQL logger' do
        expect(Gitlab::GraphqlLogger).to receive(:warn).once.with(
          hash_including(
            message: 'GLQL GraphQL query timeout',
            glql_query: glql_query,
            generated_graphql: generated_graphql,
            complexity_score: 150,
            user_id: user.id
          )
        )

        service.execute
      end
    end

    context 'when query has high complexity' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: 150,
          duration_s: 2.0,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'logs high complexity to GraphQL logger' do
        expect(Gitlab::GraphqlLogger).to receive(:info).with(
          hash_including(
            message: 'GLQL high complexity query detected - Duo optimization needed',
            glql_query: glql_query,
            generated_graphql: generated_graphql,
            complexity_score: 150,
            duration_s: 2.0,
            user_id: user.id,
            optimization_needed: false
          )
        )

        service.execute
      end

      context 'when complexity exceeds 200' do
        let(:result) do
          {
            data: { 'workItems' => { 'nodes' => [] } },
            errors: nil,
            complexity_score: 250,
            duration_s: 3.0,
            timeout_occurred: false,
            rate_limited: false
          }
        end

        it 'marks optimization as needed' do
          expect(Gitlab::GraphqlLogger).to receive(:info).with(
            hash_including(
              message: 'GLQL high complexity query detected - Duo optimization needed',
              optimization_needed: true
            )
          )

          service.execute
        end
      end
    end

    context 'when query is slow' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: 50,
          duration_s: 6.5,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'logs slow query to GraphQL logger' do
        expect(Gitlab::GraphqlLogger).to receive(:warn).with(
          hash_including(
            message: 'GLQL slow query detected - Duo optimization needed',
            glql_query: glql_query,
            generated_graphql: generated_graphql,
            complexity_score: 50,
            duration_s: 6.5,
            user_id: user.id
          )
        )

        service.execute
      end
    end

    context 'when query has multiple issues' do
      let(:result) do
        {
          data: nil,
          errors: [{ message: 'Query timed out' }],
          complexity_score: 250,
          duration_s: 10.0,
          timeout_occurred: true,
          rate_limited: false
        }
      end

      it 'logs all applicable warnings' do
        expect(Gitlab::GraphqlLogger).to receive(:warn).with(
          hash_including(message: 'GLQL GraphQL query timeout')
        )

        expect(Gitlab::GraphqlLogger).to receive(:info).with(
          hash_including(
            message: 'GLQL high complexity query detected - Duo optimization needed',
            optimization_needed: true
          )
        )

        expect(Gitlab::GraphqlLogger).to receive(:warn).with(
          hash_including(message: 'GLQL slow query detected - Duo optimization needed')
        )

        service.execute
      end
    end

    context 'when query is successful and fast' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: 50,
          duration_s: 0.5,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'does not log anything' do
        expect(Gitlab::GraphqlLogger).not_to receive(:warn)
        expect(Gitlab::GraphqlLogger).not_to receive(:info)

        service.execute
      end
    end

    context 'when complexity score is nil' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: nil,
          duration_s: 0.5,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'does not log high complexity' do
        expect(Gitlab::GraphqlLogger).not_to receive(:info)

        service.execute
      end
    end

    context 'when duration is nil' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: 50,
          duration_s: nil,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'does not log slow query' do
        expect(Gitlab::GraphqlLogger).not_to receive(:warn)

        service.execute
      end
    end

    context 'when user is nil' do
      let(:service) do
        described_class.new(
          current_user: nil,
          result: result,
          query_sha: query_sha,
          glql_query: glql_query,
          generated_graphql: generated_graphql
        )
      end

      let(:result) do
        {
          data: nil,
          errors: [{ message: 'Query timed out' }],
          complexity_score: 150,
          duration_s: 4.0, # Below slow query threshold
          timeout_occurred: true,
          rate_limited: false
        }
      end

      it 'logs with nil user_id' do
        expect(Gitlab::GraphqlLogger).to receive(:warn).once.with(
          hash_including(
            message: 'GLQL GraphQL query timeout',
            user_id: nil
          )
        )

        service.execute
      end
    end

    context 'when used without GLQL-specific details (Controller path)' do
      let(:service) { service_without_glql }

      let(:result) do
        {
          data: nil,
          errors: [{ message: 'Query timed out' }],
          complexity_score: 150,
          duration_s: 4.0, # Below slow query threshold
          timeout_occurred: true,
          rate_limited: false
        }
      end

      it 'logs timeout without GLQL-specific fields' do
        expect(Gitlab::GraphqlLogger).to receive(:warn).once do |log_data|
          expect(log_data).to include(
            message: 'GLQL GraphQL query timeout',
            query_sha: query_sha,
            complexity_score: 150,
            user_id: user.id
          )
          expect(log_data).not_to have_key(:glql_query)
          expect(log_data).not_to have_key(:generated_graphql)
        end

        service.execute
      end
    end

    context 'when query is at complexity threshold' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: 100,
          duration_s: 0.5,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'does not log high complexity' do
        expect(Gitlab::GraphqlLogger).not_to receive(:info)

        service.execute
      end
    end

    context 'when query is at duration threshold' do
      let(:result) do
        {
          data: { 'workItems' => { 'nodes' => [] } },
          errors: nil,
          complexity_score: 50,
          duration_s: 5.0,
          timeout_occurred: false,
          rate_limited: false
        }
      end

      it 'does not log slow query' do
        expect(Gitlab::GraphqlLogger).not_to receive(:warn)

        service.execute
      end
    end
  end
end
