# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewController, :clean_gitlab_redis_cache, feature_category: :onboarding do
  after do
    ReleaseHighlight.instance_variable_set(:@file_paths, nil)
  end

  describe 'GET #index' do
    let(:item) { double(:item) }
    let(:highlights) { double(:highlight, items: [item], map: [item].map, next_page: 2) }

    context 'with no page param' do
      it 'responds with paginated data and headers' do
        allow(ReleaseHighlight).to receive(:paginated).with(page: 1).and_return(highlights)

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

    context 'with whats_new_variant = disabled' do
      before do
        Gitlab::CurrentSettings.current_application_settings.whats_new_variant_disabled!
      end

      it 'returns a 404' do
        get whats_new_path, xhr: true

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #mark_as_read' do
    let(:article_id) { '123' }

    subject do
      post whats_new_mark_as_read_path(article_id: article_id)
      response
    end

    context 'when user is not authenticated' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when user is authenticated' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      context 'when whats_new is disabled' do
        before do
          Gitlab::CurrentSettings.current_application_settings.whats_new_variant_disabled!
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when the service call is successful' do
        before do
          allow_next_instance_of(Onboarding::WhatsNew::ReadStatusService) do |service|
            allow(service).to receive(:mark_article_as_read).with(article_id).and_return(ServiceResponse.success)
          end
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      context 'when the service call is unsuccessful' do
        before do
          allow_next_instance_of(Onboarding::WhatsNew::ReadStatusService) do |service|
            allow(service).to receive(:mark_article_as_read).with(article_id)
                                                            .and_return(ServiceResponse.error(message: 'bad'))
          end
        end

        it { is_expected.to have_gitlab_http_status(:bad_request) }
      end

      subject do
        post whats_new_mark_as_read_path(article_id: article_id)
        response
      end

      it 'initialize the service class with correct parameters' do
        allow(ReleaseHighlight).to receive(:most_recent_version_digest).and_return("digest")

        expect(Onboarding::WhatsNew::ReadStatusService).to receive(:new).with(user.id, "digest").and_call_original

        post whats_new_mark_as_read_path(article_id: article_id)
      end
    end
  end
end
