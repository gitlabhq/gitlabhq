# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_configure_later_button.html.haml', feature_category: :system_access do
  let(:deadline) { Time.utc(2026, 7, 19, 0, 5, 15) }

  it 'renders a client-side localized time element with a labelled UTC fallback' do
    render partial: 'profiles/two_factor_auths/configure_later_button',
      locals: { message: 'Enable 2FA.', grace_period_deadline: deadline, group_list: nil }

    expect(rendered).to have_css(
      "time.js-local-datetime[datetime='2026-07-19T00:05:15Z']",
      text: 'July 19, 2026 00:05 UTC'
    )
  end

  it 'renders the "Configure it later" button' do
    render partial: 'profiles/two_factor_auths/configure_later_button',
      locals: { message: 'Enable 2FA.', grace_period_deadline: deadline, group_list: nil }

    expect(rendered).to have_css('.gl-alert-actions [data-testid="configure-it-later-button"]')
  end

  it 'renders the group list when present' do
    render partial: 'profiles/two_factor_auths/configure_later_button',
      locals: { message: 'Enable 2FA.', grace_period_deadline: deadline,
                group_list: '<p data-testid="group-list-stub"></p>'.html_safe }

    expect(rendered).to have_css('[data-testid="group-list-stub"]')
  end
end
