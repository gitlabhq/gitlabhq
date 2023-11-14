# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Geo, feature_category: :geo_replication do
  include WorkhorseHelpers

  describe 'GET /geo/proxy' do
    subject { get api('/geo/proxy'), headers: workhorse_headers }

    include_context 'workhorse headers'

    let(:non_proxy_response_schema) do
      {
        'type' => 'object',
        'additionalProperties' => false,
        'required' => %w[geo_enabled],
        'properties' => {
          'geo_enabled' => { 'type' => 'boolean' }
        }
      }
    end

    context 'with valid auth' do
      it 'returns empty data' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match_schema(non_proxy_response_schema)
        expect(json_response['geo_enabled']).to be_falsey
      end
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
