# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PwaController, feature_category: :navigation do
  describe 'GET #manifest' do
    shared_examples 'text values' do |params, result|
      let_it_be(:appearance) { create(:appearance, **params) }

      it 'uses custom values', :aggregate_failures do
        get manifest_path(format: :json)

        expect(Gitlab::Json.parse(response.body)).to include(result)
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'with default appearance' do
      it_behaves_like 'text values', {}, {
                                           'name' => 'GitLab',
                                           'short_name' => 'GitLab',
                                           'description' => 'The complete DevOps platform. ' \
                                                            'One application with endless possibilities. ' \
                                                            'Organizations rely on GitLab’s source code management, ' \
                                                            'CI/CD, security, and more to deliver software rapidly.'
                                           }
    end

    context 'with customized appearance' do
      context 'with custom text values' do
        it_behaves_like 'text values', { pwa_name: 'PWA name' }, { 'name' => 'PWA name' }
        it_behaves_like 'text values', { pwa_short_name: 'Short name' }, { 'short_name' => 'Short name' }
        it_behaves_like 'text values', { pwa_description: 'This is a test' }, { 'description' => 'This is a test' }
      end

      shared_examples 'icon paths' do
        it 'returns expected icon paths', :aggregate_failures do
          get manifest_path(format: :json)

          expect(Gitlab::Json.parse(response.body)["icons"]).to match_array(result)
          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'with custom icon' do
        let_it_be(:appearance) { create(:appearance, :with_pwa_icon) }
        let_it_be(:result) do
          [{ "src" => "/uploads/-/system/appearance/pwa_icon/#{appearance.id}/dk.png?width=192", "sizes" => "192x192",
             "type" => "image/png" },
            { "src" => "/uploads/-/system/appearance/pwa_icon/#{appearance.id}/dk.png?width=512", "sizes" => "512x512",
              "type" => "image/png" }]
        end

        it_behaves_like 'icon paths'
      end

      context 'with no custom icon' do
        let_it_be(:appearance) { create(:appearance) }
        let_it_be(:result) do
          [{ "src" => "/-/pwa-icons/logo-192.png", "sizes" => "192x192", "type" => "image/png" },
            { "src" => "/-/pwa-icons/logo-512.png", "sizes" => "512x512", "type" => "image/png" },
            { "src" => "/-/pwa-icons/maskable-logo.png", "sizes" => "512x512", "type" => "image/png",
              "purpose" => "maskable" }]
        end

        it_behaves_like 'icon paths'
      end
    end

    describe 'GET #offline' do
      it 'responds with static HTML page' do
        get offline_path

        expect(response.body).to include('You are currently offline')
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
end
