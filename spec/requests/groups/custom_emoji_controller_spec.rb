# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CustomEmojiController, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group) }

  describe 'GET #index' do
    before do
      get group_custom_emoji_index_url(group)
    end

    it { expect(response).to have_gitlab_http_status(:ok) }
  end
end
