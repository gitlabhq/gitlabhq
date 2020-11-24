# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewController do
  describe 'whats_new_path' do
    context 'with whats_new_drawer feature enabled' do
      before do
        stub_feature_flags(whats_new_drawer: true)
      end

      context 'with no page param' do
        let(:most_recent) { { items: [item], next_page: 2 } }
        let(:item) { double(:item) }

        it 'responds with paginated data and headers' do
          allow(ReleaseHighlight).to receive(:paginated).with(page: 1).and_return(most_recent)
          allow(Gitlab::WhatsNew::ItemPresenter).to receive(:present).with(item).and_return(item)

          get whats_new_path, xhr: true

          expect(response.body).to eq(most_recent[:items].to_json)
          expect(response.headers['X-Next-Page']).to eq(2)
        end
      end

      context 'with page param' do
        it 'passes the page parameter' do
          expect(ReleaseHighlight).to receive(:paginated).with(page: 2).and_call_original

          get whats_new_path(page: 2), xhr: true
        end

        it 'returns a 404 if page param is negative' do
          get whats_new_path(page: -1), xhr: true

          expect(response).to have_gitlab_http_status(:not_found)
        end
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
