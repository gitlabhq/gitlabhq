# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/registrations/profiles/new', feature_category: :onboarding do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    allow(view).to receive_messages(
      admin_registrations_profile_path: '/admin/registrations/profile',
      skip_admin_registrations_profile_path: '/admin/registrations/profile/skip',
      terms_path: '/terms'
    )
  end

  it 'renders the page heading' do
    render

    expect(rendered).to have_css('h2', text: 'Set up your profile')
  end

  it 'renders a form patching to the profile path' do
    render

    expect(rendered).to have_css("form[action='/admin/registrations/profile']")
  end

  it 'renders the first name field with label "First name"' do
    render

    expect(rendered).to have_field('user[first_name]')
    expect(rendered).to have_css('label', text: 'First name')
  end

  it 'renders the last name field with label "Last name"' do
    render

    expect(rendered).to have_field('user[last_name]')
    expect(rendered).to have_css('label', text: 'Last name')
  end

  it 'renders the email field with label "Email" (not "Business email")' do
    render

    expect(rendered).to have_field('user[email]')
    expect(rendered).to have_css('label', text: 'Email')
    expect(rendered).not_to have_css('label', text: 'Business email')
  end

  it 'renders the organization name field with label "Organization name" (not "Company name")' do
    render

    expect(rendered).to have_field('user[user_detail_attributes][company]')
    expect(rendered).to have_css('label', text: 'Organization name')
    expect(rendered).not_to have_css('label', text: 'Company name')
  end

  it 'marks all profile fields as required' do
    render

    expect(rendered).to have_css("input[name='user[first_name]'][required]")
    expect(rendered).to have_css("input[name='user[last_name]'][required]")
    expect(rendered).to have_css("input[name='user[email]'][required]")
    expect(rendered).to have_css("input[name='user[user_detail_attributes][company]'][required]")
  end

  it 'renders a Continue submit button' do
    render

    expect(rendered).to have_button('Continue')
  end

  it 'renders a Skip link' do
    render

    expect(rendered).to have_link('Skip', href: '/admin/registrations/profile/skip')
  end

  it 'wraps the form in a bordered card' do
    render

    expect(rendered).to have_css('.gl-border.gl-rounded-lg')
  end

  it 'does not mount any Vue components' do
    render

    expect(rendered).not_to have_css('[data-component]')
  end
end
