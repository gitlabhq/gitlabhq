# frozen_string_literal: true

RSpec.shared_examples 'Read-only instance' do |message|
  it 'shows read-only banner' do
    visit root_dashboard_path

    expect(page).to have_content(message)
  end
end

RSpec.shared_examples 'Read-write instance' do |message|
  it 'does not show read-only banner' do
    visit root_dashboard_path

    expect(page).not_to have_content(message)
  end
end
