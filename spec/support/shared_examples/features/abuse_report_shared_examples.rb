# frozen_string_literal: true

RSpec.shared_examples 'reports the user with an abuse category' do
  it 'creates abuse report' do
    click_button 'Report abuse to administrator'
    choose "They're posting spam."
    click_button 'Next'

    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'

    expect(page).to have_content 'Thank you for your report'
  end
end
