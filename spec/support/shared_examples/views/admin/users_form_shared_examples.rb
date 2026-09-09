# frozen_string_literal: true

RSpec.shared_examples 'admin user form with the account, password and profile sections' do
  it 'renders the account, password and profile fields' do
    render

    expect(rendered).to have_field('Name')
    expect(rendered).to have_field('Username')
    expect(rendered).to have_field('Email')
    expect(rendered).to have_field('Website URL')
  end
end

RSpec.shared_examples 'admin user form with only the organization section' do
  it 'renders the organization section' do
    render

    expect(rendered).to have_css('[data-testid="organization-section"]')
  end

  it 'does not render the account, password and profile fields' do
    render

    expect(rendered).not_to have_field('Name')
    expect(rendered).not_to have_field('Username')
    expect(rendered).not_to have_field('Email')
    expect(rendered).not_to have_field('Website URL')
  end
end
