# frozen_string_literal: true

RSpec.shared_examples 'showing user status' do
  let!(:status) { create(:user_status, user: user_with_status, emoji: 'smirk', message: 'Authoring this object') }

  it 'shows the status' do
    subject

    expect(page).to show_user_status(status)
  end
end
