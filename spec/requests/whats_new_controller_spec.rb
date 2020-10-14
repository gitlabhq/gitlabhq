# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewController do
  describe 'whats_new_path' do
    before do
      allow_any_instance_of(WhatsNewController).to receive(:whats_new_most_recent_release_items).and_return('items')
    end

    context 'with whats_new_drawer feature enabled' do
      before do
        stub_feature_flags(whats_new_drawer: true)
      end

      it 'is successful' do
        get whats_new_path, xhr: true

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with whats_new_drawer feature disabled' do
      before do
        stub_feature_flags(whats_new_drawer: false)
      end

      it 'returns a 404' do
        get whats_new_path, xhr: true

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
