# frozen_string_literal: true

RSpec.shared_examples 'Secure OAuth Authorizations' do
  context 'when user is confirmed' do
    let_it_be(:user) { create(:user, organizations: [current_organization]) }

    it 'asks the user to authorize the application' do
      expect(page).to have_text "#{application.name} is requesting access to your account on"
    end
  end

  context 'when user is unconfirmed' do
    let_it_be(:user) { create(:user, :unconfirmed) }

    it 'displays an error' do
      expect(page).to have_text I18n.t('doorkeeper.errors.messages.unconfirmed_email')
    end
  end
end

RSpec.shared_examples 'Secure Device OAuth Authorizations' do
  let(:user) { create(:user) }

  context 'when authorize page is rendered' do
    it 'asks user to authorize the device' do
      expect(page).to have_text "Authorize device to access to your GitLab account"
      within_testid('authorization-button') do
        expect(page).to have_content(format(_('Authorize')))
      end
    end

    it 'does not render authorize button with id' do
      expect(find_by_testid('authorization-button')[:id].nil?).to be_truthy
    end
  end

  context 'when confirmation page is rendered' do
    before do
      find_by_testid('authorization-button').click
    end

    it 'renders confirmatoin button without id' do
      within_testid('authorization-button') do
        expect(page).to have_content(format(_('Confirm')))
      end

      expect(find_by_testid('authorization-button')[:id].nil?).to be_truthy
    end
  end
end
