# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_signup_omniauth_provider_list', feature_category: :system_access do
  let_it_be(:provider_label) { :github }.freeze
  let_it_be(:tracking_label) { 'free_registration' }.freeze
  let_it_be(:tracking_action) { "#{provider_label}_sso" }.freeze

  subject { rendered }

  before do
    allow(view).to receive(:providers).and_return([provider_label])
    allow(view).to receive(:tracking_label).and_return(tracking_label)
    allow(view).to receive(:glm_tracking_params).and_return({})
    render
  end

  shared_examples 'sso buttons have snowplow tracking' do
    it 'contains tracking attributes' do
      css = "[data-track-action='#{tracking_action}']"
      css += "[data-track-label='#{tracking_label}']"

      expect(rendered).to have_css(css)
    end
  end

  it { is_expected.to have_content(_("Register with:")) }

  it_behaves_like 'sso buttons have snowplow tracking'

  it 'renders button in form' do
    expect(rendered).to have_css('form[action="/users/auth/github"]')
  end
end
