# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::CommentTemplatesController, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    before do
      get '/-/profile/comment_templates'
    end

    it { expect(response).to have_gitlab_http_status(:ok) }

    it 'sets hide search settings ivar' do
      expect(assigns(:hide_search_settings)).to eq(true)
    end
  end
end
