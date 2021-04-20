# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomersDot::ProxyController, type: :request do
  describe 'POST graphql' do
    let_it_be(:customers_dot) { "#{Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL}/graphql" }

    it 'forwards request body to customers dot' do
      request_params = '{ "foo" => "bar" }'

      stub_request(:post, customers_dot)

      post customers_dot_proxy_graphql_path, params: request_params

      expect(WebMock).to have_requested(:post, customers_dot).with(body: request_params)
    end

    it 'responds with customers dot status' do
      stub_request(:post, customers_dot).to_return(status: 500)

      post customers_dot_proxy_graphql_path

      expect(response).to have_gitlab_http_status(:internal_server_error)
    end

    it 'responds with customers dot response body' do
      customers_dot_response = 'foo'

      stub_request(:post, customers_dot).to_return(body: customers_dot_response)

      post customers_dot_proxy_graphql_path

      expect(response.body).to eq(customers_dot_response)
    end
  end
end
