# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_packages_limits_settings', feature_category: :package_registry do
  let_it_be(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:form_errors).and_return('')
  end

  it 'renders package limits settings form' do
    render

    expect(rendered).to have_selector('.gl-mt-7 h4', text: 'Package limits')
    expect(rendered).to have_selector('p',
      text: 'Setting high package limits can impact database performance. ' \
        'Consider the size of your instance when configuring these values.')
    expect(rendered).to have_selector(
      'form.fieldset-form[action="/admin/application_settings/ci_cd#js-package-settings"]' \
        '[method="post"][data-testid="package-limits-form"]'
    ) do |form|
      expect(form).to have_field('_method', type: 'hidden', with: 'patch')
    end
  end

  it 'renders helm packages count field with default value' do
    render

    expect(rendered).to have_selector('form') do |form|
      expect(form).to have_selector('label', text: 'Maximum number of Helm packages per channel')
      expect(form).to have_field(
        'application_setting[helm_max_packages_count]',
        type: 'number'
      )
      expect(form).to have_selector(
        "input[placeholder='#{ApplicationSetting::DEFAULT_HELM_MAX_PACKAGES_COUNT}']"
      )
      expect(form).to have_selector('.form-text',
        text: 'Maximum number of Helm packages that can be listed per channel. Must be at least 1.')
    end
  end

  it 'renders save changes button with pajamas' do
    render

    expect(rendered).to have_button('Save changes', class: ['gl-button'])
  end
end
