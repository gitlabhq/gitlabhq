# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information' do
  include GraphqlHelpers

  let(:query) { graphql_query_for('metadata', {}, all_graphql_fields_for('Metadata')) }

  context 'logged in' do
    let(:expected_data) do
      {
        'metadata' => {
          'version' => Gitlab::VERSION,
          'revision' => Gitlab.revision,
          'kas' => {
            'enabled' => Gitlab::Kas.enabled?,
            'version' => expected_kas_version,
            'externalUrl' => expected_kas_external_url
          }
        }
      }
    end

    context 'kas is enabled' do
      let(:expected_kas_version) { Gitlab::Kas.version }
      let(:expected_kas_external_url) { Gitlab::Kas.external_url }

      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
        post_graphql(query, current_user: create(:user))
      end

      it 'returns version, revision, kas_enabled, kas_version, kas_external_url' do
        expect(graphql_errors).to be_nil
        expect(graphql_data).to eq(expected_data)
      end
    end

    context 'kas is disabled' do
      let(:expected_kas_version) { nil }
      let(:expected_kas_external_url) { nil }

      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(false)
        post_graphql(query, current_user: create(:user))
      end

      it 'returns version and revision' do
        expect(graphql_errors).to be_nil
        expect(graphql_data).to eq(expected_data)
      end
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
