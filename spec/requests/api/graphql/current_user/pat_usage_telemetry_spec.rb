# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'use_pat telemetry for GraphQL requests', :request_store, feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('todos', {}, 'nodes { id }'))
  end

  before do
    stub_feature_flags(track_api_request_from_personal_access_token: true)
    stub_feature_flags(granular_personal_access_tokens: true)
  end

  context 'with a granular PAT that lacks the required permissions' do
    let(:granular_pat) { create(:granular_pat, user: user) }

    subject(:request) { post_graphql(query, token: { personal_access_token: granular_pat }) }

    # The query denies at the `currentUser` field (read_user); its `todos` child is never resolved,
    # so only `read_user` is recorded. GraphQL serves the denial as HTTP 200, so `denied_permissions`
    # is the denial signal.
    it 'emits use_pat with the denied permission' do
      expect { request }.to trigger_internal_events('use_pat')
        .with(
          user: user,
          category: 'InternalEventTracking',
          additional_properties: {
            pat_type: 'granular',
            label: 'unknown',
            response_code: 200,
            denied_permissions: 'read_user'
          }
        )
    end
  end

  context 'with a legacy PAT' do
    let(:legacy_pat) { create(:personal_access_token, user: user, scopes: %w[api]) }

    subject(:request) { post_graphql(query, token: { personal_access_token: legacy_pat }) }

    it 'emits use_pat without denied_permissions' do
      expect { request }.to trigger_internal_events('use_pat')
        .with(
          user: user,
          category: 'InternalEventTracking',
          additional_properties: { pat_type: 'legacy', label: 'unknown', response_code: 200 }
        )
    end

    context 'when the request raises an error' do
      subject(:request) { post_graphql(query, token: { personal_access_token: legacy_pat }) }

      before do
        allow(GitlabSchema).to receive(:execute).and_raise(ActiveRecord::QueryAborted)
      end

      it 'still emits use_pat exactly once' do
        expect { request }.to trigger_internal_events('use_pat')
          .with(
            user: user,
            category: 'InternalEventTracking',
            additional_properties: { pat_type: 'legacy', label: 'unknown', response_code: 200 }
          ).exactly(1).time
      end
    end

    context 'with a multiplex request whose joined operation names exceed the label limit' do
      let(:limit) { GraphqlController::GRAPHQL_OPERATION_NAME_LABEL_LIMIT }
      let(:operation_names) { (1..20).map { |i| "PatUsageMultiplexedOperationNumber#{i}" } }
      let(:queries) do
        operation_names.map { |name| { query: "query #{name} { currentUser { id } }", operationName: name } }
      end

      subject(:request) do
        post_multiplex(queries, headers: { 'Private-Token' => legacy_pat.token })
      end

      it 'truncates the label to the configured limit' do
        expected_label = operation_names.join(',').truncate(limit)

        expect(expected_label.length).to eq(limit)

        expect { request }.to trigger_internal_events('use_pat')
          .with(
            user: user,
            category: 'InternalEventTracking',
            additional_properties: { pat_type: 'legacy', label: expected_label, response_code: 200 }
          ).exactly(1).time
      end
    end
  end
end
