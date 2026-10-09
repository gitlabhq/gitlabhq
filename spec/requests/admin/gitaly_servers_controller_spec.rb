# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::GitalyServersController, :enable_admin_mode, feature_category: :gitaly do
  describe 'GET #index' do
    before do
      sign_in(create(:admin))
    end

    it 'shows the gitaly servers page' do
      get admin_gitaly_servers_path

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
