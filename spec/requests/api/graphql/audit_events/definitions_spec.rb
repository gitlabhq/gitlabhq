# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of audit event definitions', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:path) { %i[audit_event_definitions nodes] }
  let(:audit_event_definition_keys) do
    Gitlab::Audit::Type::Definition.definitions.keys
  end

  let(:query) { graphql_query_for(:audit_event_definitions, {}, 'nodes { name }') }

  it 'returns the audit event definitions' do
    post_graphql(query, current_user: current_user)

    returned_names = graphql_data_at(*path).map { |v| v['name'].to_sym }

    expect(returned_names).to all be_in(audit_event_definition_keys)
  end
end
