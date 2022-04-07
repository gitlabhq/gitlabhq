# frozen_string_literal: true

RSpec.shared_examples 'shows and resets runner registration token' do
  include Spec::Support::Helpers::ModalHelpers

  before do
    click_on dropdown_text
  end

  describe 'shows registration instructions' do
    before do
      click_on 'Show runner installation and registration instructions'

      wait_for_requests
    end

    it 'opens runner installation modal', :aggregate_failures do
      within_modal do
        expect(page).to have_text "Install a runner"
        expect(page).to have_text "Environment"
        expect(page).to have_text "Architecture"
        expect(page).to have_text "Download and install binary"
      end
    end

    it 'dismisses runner installation modal' do
      within_modal do
        click_button('Close', match: :first)
      end

      expect(page).not_to have_text "Install a runner"
    end
  end

  it 'has a registration token' do
    click_on 'Click to reveal'
    expect(page.find('[data-testid="token-value"]')).to have_content(registration_token)
  end

  describe 'reset registration token' do
    let!(:old_registration_token) { find('[data-testid="token-value"]').text }

    before do
      click_on 'Reset registration token'

      within_modal do
        click_button('Reset token', match: :first)
      end

      wait_for_requests
    end

    it 'changes registration token' do
      expect(find('.gl-toast')).to have_content('New registration token generated!')

      click_on dropdown_text
      click_on 'Click to reveal'

      expect(old_registration_token).not_to eq registration_token
    end
  end
end
