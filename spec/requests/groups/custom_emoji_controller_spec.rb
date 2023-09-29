# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CustomEmojiController, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group) }

  describe 'GET #index' do
    context 'with custom_emoji feature flag disabled' do
      before do
        stub_feature_flags(custom_emoji: false)

        get group_custom_emoji_index_url(group)
      end

      it { expect(response).to have_gitlab_http_status(:not_found) }
    end

    context 'with custom_emoji feature flag enabled' do
      before do
        get group_custom_emoji_index_url(group)
      end

      it { expect(response).to have_gitlab_http_status(:ok) }
    end
  end
end
