# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/_signup_box_form', feature_category: :system_access do
  before do
    stub_devise
    allow(view).to receive_messages(
      arkose_labs_enabled?: false,
      url: '_url_',
      button_text: '',
      preregistration_tracking_label: '',
      signup_submit_button_data: {}
    )
    stub_template 'devise/shared/_error_messages.html.haml' => ''
  end

  it 'renders the terms' do
    render

    expect(rendered).to render_template('devise/shared/_terms_of_service_notice')
  end

  it 'renders the Vue submit button mount point' do
    render

    expect(rendered).to have_css('#js-signup-submit-button')
  end

  def stub_devise
    allow(view).to receive_messages(devise_mapping: Devise.mappings[:user], resource: spy, resource_name: :user)
  end
end
