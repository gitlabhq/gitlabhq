# frozen_string_literal: true

RSpec.shared_examples 'issuable anonymous search' do
  context 'with anonymous user' do
    context 'with disable_anonymous_search disabled' do
      before do
        stub_feature_flags(disable_anonymous_search: false)
      end

      it 'returns issuables matching given search string for title' do
        get api(url), params: { scope: 'all', search: issuable.title }

        expect_paginated_array_response(result)
      end

      it 'returns issuables matching given search string for description' do
        get api(url), params: { scope: 'all', search: issuable.description }

        expect_paginated_array_response(result)
      end
    end

    context 'with disable_anonymous_search enabled' do
      before do
        stub_feature_flags(disable_anonymous_search: true)
      end

      it "returns 422 error" do
        get api(url), params: { scope: 'all', search: issuable.title }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('User must be authenticated to use search')
      end
    end
  end
end
