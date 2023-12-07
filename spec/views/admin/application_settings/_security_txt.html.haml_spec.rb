# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_security_txt.html.haml', feature_category: :compliance_management do
  let(:app_settings) { build(:application_setting) }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:expanded).and_return(true)
  end

  context 'when security contact information is not set' do
    it 'renders the form correctly' do
      render

      expect(rendered).to have_selector(
        'textarea',
        id: 'application_setting_security_txt_content',
        exact_text: ''
      )
    end
  end

  context 'when security contact information is set' do
    let(:app_settings) { build(:application_setting, security_txt_content: 'HELLO') }

    it 'renders the form correctly' do
      render

      expect(rendered).to have_selector(
        'textarea',
        id: 'application_setting_security_txt_content',
        exact_text: 'HELLO'
      )
    end
  end
end
