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

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end
end
