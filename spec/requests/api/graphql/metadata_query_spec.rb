# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information' do
  include GraphqlHelpers

  let(:query) { graphql_query_for('metadata', {}, all_graphql_fields_for('Metadata')) }

  context 'logged in' do
    it 'returns version and revision' do
      post_graphql(query, current_user: create(:user))

      expect(graphql_errors).to be_nil
      expect(graphql_data).to eq(
        'metadata' => {
          'version' => Gitlab::VERSION,
          'revision' => Gitlab.revision
        }
      )
    end
  end

  context 'anonymous user' do
    it 'returns nothing' do
      post_graphql(query, current_user: nil)

      expect(graphql_errors).to be_nil
      expect(graphql_data).to eq('metadata' => nil)
    end
  end
end
