# frozen_string_literal: true

RSpec.shared_examples 'an endpoint with keyset pagination' do |invalid_order: 'name', invalid_sort: 'asc'|
  include KeysetPaginationHelpers

  let(:keyset_params) { { pagination: 'keyset', per_page: 1 } }
  let(:additional_params) { {} }

  subject do
    get api_call, params: keyset_params.merge(additional_params)
    response
  end

  context 'on making requests with supported ordering structure' do
    it 'includes keyset url params in the url response' do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to include_keyset_url_params
    end

    it 'does not include pagination headers' do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.not_to include_pagination_headers
    end

    it 'paginates the records correctly', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      records = json_response
      expect(records.size).to eq(1)
      expect(records.first['id']).to eq(first_record.id)

      get api_call, params: pagination_params_from_next_url(response)

      expect(response).to have_gitlab_http_status(:ok)
      records = Gitlab::Json.parse(response.body)
      expect(records.size).to eq(1)
      expect(records.first['id']).to eq(second_record.id)
    end
  end

  context 'on making requests with unsupported ordering structure' do
    let(:additional_params) { { order_by: invalid_order, sort: invalid_sort } }

    if invalid_order
      it 'returns error', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:method_not_allowed)
        expect(json_response['error']).to eq('Keyset pagination is not yet available for this type of request')
      end
    end
  end
end
