# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/_signup_box_form', feature_category: :system_access do
  before do
    stub_devise
    allow(view).to receive(:arkose_labs_enabled?).and_return(false)
    allow(view).to receive(:url).and_return('_url_')
    allow(view).to receive(:button_text).and_return('')
    allow(view).to receive(:preregistration_tracking_label).and_return('')
    stub_template 'devise/shared/_error_messages.html.haml' => ''
  end

  it 'renders the terms' do
    render

    expect(rendered).to render_template('devise/shared/_terms_of_service_notice')
  end

  context 'when arkose_reactive_submit_button? returns true' do
    before do
      allow(view).to receive(:arkose_reactive_submit_button?).and_return(true)
      allow(view).to receive(:signup_submit_button_data).and_return({})
    end

    it 'renders the Vue submit button mount point' do
      render

      expect(rendered).to have_css('#js-signup-submit-button')
    end

    it 'does not render the server-rendered submit button' do
      render

      expect(rendered).not_to have_testid('new-user-register-button')
    end
  end

  context 'when arkose_reactive_submit_button? returns false' do
    before do
      allow(view).to receive(:arkose_reactive_submit_button?).and_return(false)
    end

    it 'renders the server-rendered submit button' do
      render

      expect(rendered).to have_testid('new-user-register-button')
    end

    it 'does not render the Vue submit button mount point' do
      render

      expect(rendered).not_to have_css('#js-signup-submit-button')
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end
end
