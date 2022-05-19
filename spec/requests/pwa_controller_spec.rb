# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PwaController do
  describe 'GET #offline' do
    it 'responds with static HTML page' do
      get offline_path

      expect(response.body).to include('You are currently offline')
      expect(response).to have_gitlab_http_status(:success)
    end
  end
end
