# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PwaController, feature_category: :navigation do
  describe 'GET #manifest' do
    it 'responds with json' do
      get manifest_path(format: :json)

      expect(response.body).to include('The complete DevOps platform.')
      expect(Gitlab::Json.parse(response.body)).to include({ 'short_name' => 'GitLab' })
      expect(response).to have_gitlab_http_status(:success)
    end

    context 'with customized appearance' do
      let_it_be(:appearance) do
        create(:appearance, title: 'Long name', pwa_short_name: 'Short name', description: 'This is a test')
      end

      it 'uses custom values', :aggregate_failures do
        get manifest_path(format: :json)

        expect(Gitlab::Json.parse(response.body)).to include({
                                                               'description' => 'This is a test',
                                                               'name' => 'Long name',
                                                               'short_name' => 'Short name'
                                                             })
        expect(response).to have_gitlab_http_status(:success)
      end
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
