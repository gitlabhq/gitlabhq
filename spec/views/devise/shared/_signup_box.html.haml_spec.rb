# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_signup_box' do
  before do
    stub_devise
    allow(view).to receive(:show_omniauth_providers).and_return(false)
    allow(view).to receive(:url).and_return('_url_')
    allow(view).to receive(:terms_path).and_return('_terms_path_')
    allow(view).to receive(:button_text).and_return('_button_text_')
    allow(view).to receive(:signup_username_data_attributes).and_return({})
    stub_template 'devise/shared/_error_messages.html.haml' => ''
  end

  context 'when terms are enforced' do
    before do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enforce_terms?).and_return(true)
    end

    it 'shows expected text with placeholders' do
      render

      expect(rendered).to have_content('By clicking _button_text_')
      expect(rendered).to have_link('Terms of Use and Privacy Policy')
    end

    context 'when on .com' do
      before do
        allow(Gitlab).to receive(:dev_env_or_com?).and_return(true)
      end

      it 'shows expected GitLab text' do
        render

        expect(rendered).to have_content('I have read and accepted the GitLab Terms')
      end
    end

    context 'when not on .com' do
      before do
        allow(Gitlab).to receive(:dev_env_or_com?).and_return(false)
      end

      it 'shows expected text without GitLab' do
        render

        expect(rendered).to have_content('I have read and accepted the Terms')
      end
    end
  end

  context 'when terms are not enforced' do
    before do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enforce_terms?).and_return(false)
      allow(Gitlab).to receive(:dev_env_or_com?).and_return(true)
    end

    it 'shows expected text with placeholders' do
      render

      expect(rendered).not_to have_content('By clicking')
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end
end
