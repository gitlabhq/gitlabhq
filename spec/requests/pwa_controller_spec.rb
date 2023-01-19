# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PwaController, feature_category: :navigation do
  describe 'GET #manifest' do
    it 'responds with json' do
      get manifest_path(format: :json)

      expect(Gitlab::Json.parse(response.body)).to include({ 'name' => 'GitLab' })
      expect(Gitlab::Json.parse(response.body)).to include({ 'short_name' => 'GitLab' })
      expect(response.body).to include('The complete DevOps platform.')
      expect(response).to have_gitlab_http_status(:success)
    end

    context 'with customized appearance' do
      let_it_be(:appearance) do
        create(:appearance, pwa_name: 'PWA name', pwa_short_name: 'Short name', pwa_description: 'This is a test')
      end

      it 'uses custom values', :aggregate_failures do
        get manifest_path(format: :json)

        expect(Gitlab::Json.parse(response.body)).to include({
                                                               'description' => 'This is a test',
                                                               'name' => 'PWA name',
                                                               'short_name' => 'Short name'
                                                             })
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when user is signed in' do
      before do
        user = create(:user)
        allow(user).to receive(:role_required?).and_return(true)

        sign_in(user)
      end

      it 'skips the required signup info storing of user location' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).not_to receive(:store_location_for).with(:user, manifest_path(format: :json))
        end

        get manifest_path(format: :json)
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
