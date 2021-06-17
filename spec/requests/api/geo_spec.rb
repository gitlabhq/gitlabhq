# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Geo do
  include WorkhorseHelpers

  describe 'GET /geo/proxy' do
    subject { get api('/geo/proxy'), headers: workhorse_headers }

    include_context 'workhorse headers'

    context 'with valid auth' do
      it 'returns empty data' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
