# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PwaController, feature_category: :navigation do
  describe 'GET #manifest' do
    it 'responds with json' do
      get manifest_path(format: :json)

      expect(response.body).to include('The complete DevOps platform.')
      expect(response).to have_gitlab_http_status(:success)
    end
  end

  describe 'GET #offline' do
    it 'responds with static HTML page' do
      get offline_path

      expect(response.body).to include('You are currently offline')
      expect(response).to have_gitlab_http_status(:success)
    end
  end
end
