# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_signup_box', feature_category: :system_access do
  let(:button_text) { '_button_text_' }
  let(:terms_path) { '_terms_path_' }

  let(:translation_com) do
    s_("SignUp|By clicking %{button_text} or registering through a third party you "\
      "accept the GitLab %{link_start}Terms of Use and acknowledge the Privacy Statement "\
      "and Cookie Policy%{link_end}.")
  end

  let(:translation_non_com) do
    s_("SignUp|By clicking %{button_text} or registering through a third party you "\
      "accept the %{link_start}Terms of Use and acknowledge the Privacy Statement and "\
      "Cookie Policy%{link_end}.")
  end

  before do
    stub_devise
    allow(view).to receive(:arkose_labs_enabled?).and_return(false)
    allow(view).to receive(:show_omniauth_providers).and_return(false)
    allow(view).to receive(:url).and_return('_url_')
    allow(view).to receive(:terms_path).and_return(terms_path)
    allow(view).to receive(:button_text).and_return(button_text)
    allow(view).to receive(:signup_username_data_attributes).and_return({})
    allow(view).to receive(:tracking_label).and_return('')
    stub_template 'devise/shared/_error_messages.html.haml' => ''
  end

  def text(translation)
    format(
      translation,
      button_text: button_text,
      link_start: "<a href='#{terms_path}' target='_blank' rel='noreferrer noopener'>",
      link_end: '</a>'
    )
  end

  context 'when terms are enforced' do
    before do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enforce_terms?).and_return(true)
    end

    context 'when on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'shows expected GitLab text' do
        render

        expect(rendered).to include(text(translation_com))
      end
    end

    context 'when not on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'shows expected text without GitLab' do
        render

        expect(rendered).to include(text(translation_non_com))
      end
    end
  end

  context 'when terms are not enforced' do
    before do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enforce_terms?).and_return(false)
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'shows expected text with placeholders' do
      render

      expect(rendered).not_to include(text(translation_com))
    end
  end

  context 'when signup_intent_step_one experiment is control' do
    before do
      stub_experiments(signup_intent_step_one: :control)
    end

    it 'does not render signup_intent select' do
      render

      expect(rendered).not_to have_css('label[for="signup_intent"]')
      expect(rendered).not_to have_css('select[id="signup_intent"]')
    end
  end

  context 'when signup_intent_step_one experiment is candidate' do
    before do
      stub_experiments(signup_intent_step_one: :candidate)
    end

    it 'renders signup_intent select' do
      render

      expect(rendered).to include(s_('SignUp|I want to...'))
      expect(rendered).to include(s_('SignUp|Set up a new team'))
      expect(rendered).to include(s_('SignUp|Set up a new personal account'))
      expect(rendered).to include(s_('SignUp|Join an existing team'))
      expect(rendered).to include(s_('SignUp|Contribute to a public project on GitLab'))

      expect(rendered).to have_css('select[name="signup_intent"]')
      expect(rendered).to have_css('option[value="new_team"]')
      expect(rendered).to have_css('option[value="new_personal_account"]')
      expect(rendered).to have_css('option[value="join_existing_team"]')
      expect(rendered).to have_css('option[value="contribute_public_project"]')
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end
end
