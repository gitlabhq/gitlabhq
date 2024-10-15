# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'HTTP Router Version Route', type: :request, feature_category: :api do
  shared_examples 'a successful empty response' do |http_method|
    it "responds with 204 status code for #{http_method.to_s.upcase}" do
      send(http_method, '/-/http_router/version') # Use send to make the request dynamically

      expect(response).to have_gitlab_http_status(:no_content) # Check for 204 No Content
      expect(response.body).to be_empty # Ensure the response body is empty
    end
  end

  # Specify all the HTTP methods you want to test
  %i[get post put delete patch head options].each do |http_method|
    include_examples 'a successful empty response', http_method
  end
end
