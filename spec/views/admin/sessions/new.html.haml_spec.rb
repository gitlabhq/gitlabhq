# frozen_string_literal: true

require 'spec_helper'

describe 'admin/sessions/new.html.haml' do
  let(:user) { create(:admin) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:omniauth_enabled?).and_return(false)
  end

  context 'internal admin user' do
    it 'shows enter password form' do
      render

      expect(rendered).to have_css('#login-pane.active')
      expect(rendered).to have_selector('input[name="password"]')
    end

    it 'warns authentication not possible if password not set' do
      allow(user).to receive(:require_password_creation_for_web?).and_return(true)

      render

      expect(rendered).not_to have_css('#login-pane')
      expect(rendered).to have_content _('No authentication methods configured.')
    end
  end

  context 'omniauth authentication enabled' do
    before do
      allow(view).to receive(:omniauth_enabled?).and_return(true)
      allow(view).to receive(:button_based_providers_enabled?).and_return(true)
    end

    it 'shows omniauth form' do
      render

      expect(rendered).to have_css('.omniauth-container')
      expect(rendered).to have_content _('Sign in with')

      expect(rendered).not_to have_content _('No authentication methods configured.')
    end
  end
end
