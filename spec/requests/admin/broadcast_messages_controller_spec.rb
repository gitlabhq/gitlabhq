# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BroadcastMessagesController, :enable_admin_mode do
  before do
    sign_in(create(:admin))
  end

  describe 'POST /preview' do
    it 'renders preview partial' do
      post preview_admin_broadcast_messages_path, params: { broadcast_message: { message: "Hello, world!" } }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to render_template(:_preview)
    end
  end
end
