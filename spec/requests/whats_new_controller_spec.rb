# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewController do
  describe 'whats_new_path' do
    let(:item) { double(:item) }
    let(:highlights) { double(:highlight, items: [item], map: [item].map, next_page: 2) }

    context 'with no page param' do
      it 'responds with paginated data and headers' do
        allow(ReleaseHighlight).to receive(:paginated).with(page: 1).and_return(highlights)
        allow(Gitlab::WhatsNew::ItemPresenter).to receive(:present).with(item).and_return(item)

        get whats_new_path, xhr: true

        expect(response.body).to eq(highlights.items.to_json)
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

    context 'with version param' do
      it 'returns items without pagination headers' do
        allow(ReleaseHighlight).to receive(:for_version).with(version: '42').and_return(highlights)
        allow(Gitlab::WhatsNew::ItemPresenter).to receive(:present).with(item).and_return(item)

        get whats_new_path(version: 42), xhr: true

        expect(response.body).to eq(highlights.items.to_json)
        expect(response.headers['X-Next-Page']).to be_nil
      end
    end
  end
end
