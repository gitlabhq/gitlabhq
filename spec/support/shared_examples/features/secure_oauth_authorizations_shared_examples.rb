# frozen_string_literal: true

RSpec.shared_examples 'Secure OAuth Authorizations' do
  context 'when user is confirmed' do
    let(:user) { create(:user) }

    it 'asks the user to authorize the application' do
      expect(page).to have_text "Authorize #{application.name} to use your account?"
    end
  end

  context 'when user is unconfirmed' do
    let(:user) { create(:user, confirmed_at: nil) }

    it 'displays an error' do
      expect(page).to have_text I18n.t('doorkeeper.errors.messages.unconfirmed_email')
    end
  end
end
