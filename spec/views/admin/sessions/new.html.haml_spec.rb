# frozen_string_literal: true

require 'spec_helper'

describe 'admin/sessions/new.html.haml' do
  context 'admin has password set' do
    before do
      allow(view).to receive(:password_authentication_enabled_for_web?).and_return(true)
    end

    it "shows enter password form" do
      render

      expect(rendered).to have_css('#login-pane.active')
      expect(rendered).to have_selector('input[name="password"]')
    end
  end

  context 'admin has no password set' do
    before do
      allow(view).to receive(:password_authentication_enabled_for_web?).and_return(false)
    end

    it "warns authentication not possible" do
      render

      expect(rendered).not_to have_css('#login-pane')
      expect(rendered).to have_content 'No authentication methods configured'
    end
  end
end
