# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/user_settings/authentication_log', feature_category: :system_access do
  let(:user) { create(:user) }

  before do
    assign(:user, user)
    assign(:events, AuthenticationEvent.all.page(params[:page]))
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'when user has successful and failure events' do
    before do
      create(:authentication_event, :successful, user: user)
      create(:authentication_event, :failed, user: user)
    end

    it 'only shows successful events' do
      render

      expect(rendered).to have_text('Signed in with standard authentication', count: 1)
    end
  end
end
