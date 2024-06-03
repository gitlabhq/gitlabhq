# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_signup_box_form', feature_category: :acquisition do
  let(:button_text) { '_button_text_' }

  before do
    stub_devise
    allow(view).to receive(:arkose_labs_enabled?).and_return(false)
    allow(view).to receive(:show_omniauth_providers).and_return(false)
    allow(view).to receive(:url).and_return('_url_')
    allow(view).to receive(:button_text).and_return(button_text)
    allow(view).to receive(:signup_username_data_attributes).and_return({})
    allow(view).to receive(:tracking_label).and_return('')
    stub_template 'devise/shared/_error_messages.html.haml' => ''
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

      expect(rendered).to have_css(
        'option[value="select_signup_intent_dropdown_new_team_registration_step_one"]'
      )

      expect(rendered).to have_css(
        'option[value="select_signup_intent_dropdown_new_personal_account_registration_step_one"]'
      )

      expect(rendered).to have_css(
        'option[value="select_signup_intent_dropdown_join_existing_team_registration_step_one"]'
      )

      expect(rendered).to have_css(
        'option[value="select_signup_intent_dropdown_contribute_public_project_registration_step_one"]'
      )
    end
  end

  def stub_devise
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end
end
