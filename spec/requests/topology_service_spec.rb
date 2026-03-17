# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topology Service Cache Route', feature_category: :api do
  shared_examples 'a successful empty response' do |http_method|
    it "responds with 204 status code for #{http_method.to_s.upcase}" do
      send(http_method, '/-/topology-service/__cache/v1/classify')

      expect(response).to have_gitlab_http_status(:no_content)
      expect(response.body).to be_empty
    end
  end

  %i[get post put delete patch head options].each do |http_method|
    include_examples 'a successful empty response', http_method
  end
end
