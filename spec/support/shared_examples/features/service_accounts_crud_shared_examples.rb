# frozen_string_literal: true

RSpec.shared_examples 'service account CRUD' do |path_helper_method:|
  include Features::ServiceAccountsHelpers

  describe 'create service account' do
    it 'creates a service account with a name' do
      visit send(path_helper_method, resource)

      click_button s_('ServiceAccounts|Add service account')

      within '#create-edit-service-account-modal' do
        fill_in _('Name'), with: 'New Bot'
        click_button s_('AdminUsers|Create')
      end

      expect(page).to have_content(s_('ServiceAccounts|The service account was created.'))
      expect(page).to have_css('[data-testid="service-account-name"]', text: 'New Bot')
    end
  end

  describe 'edit service account' do
    it 'edits an existing service account name' do
      create(:user, :service_account, name: 'Old Name', **provisioning_attribute)

      visit send(path_helper_method, resource)

      expect(page).to have_css('[data-testid="service-account-name"]', text: 'Old Name')

      open_service_account_options
      click_button s_('ServiceAccounts|Edit')

      within '#create-edit-service-account-modal' do
        fill_in _('Name'), with: 'New Name'
        click_button s_('AdminUsers|Edit')
      end

      expect(page).to have_content(s_('ServiceAccounts|The service account was updated.'))
      expect(page).to have_css('[data-testid="service-account-name"]', text: 'New Name')
    end
  end

  describe 'delete service account' do
    it 'deletes an existing service account' do
      create(:user, :service_account, name: 'Doomed SA', **provisioning_attribute)

      visit send(path_helper_method, resource)

      expect(page).to have_css('[data-testid="service-account-name"]', text: 'Doomed SA')

      open_service_account_options
      click_button s_('ServiceAccounts|Delete account')

      # The GlFormFields input in this modal has no stable name, id, or
      # data-testid - only a random `gl-form-field-*` id. The `within`
      # scope guarantees a single input.
      within '#delete-user-modal' do
        fill_in with: 'Doomed SA'
        click_button s_('AdminUsers|Delete user')
      end

      expect(page).to have_content(s_('ServiceAccounts|The service account is being deleted.'))
    end
  end

  describe 'access token management' do
    let_it_be(:service_account) do
      create(:user, :service_account, name: 'Token SA', **provisioning_attribute)
    end

    it 'creates a personal access token' do
      navigate_to_token_management(send(path_helper_method, resource))

      click_button s_('AccessTokens|Add new token')

      fill_in s_('AccessTokens|Token name'), with: 'ci-token'
      find_by_testid('api-checkbox').click
      click_button s_('AccessTokens|Generate token')

      expect(page).to have_content(s_('AccessTokens|Your token'))
      expect(page).to have_css('[data-testid="created-access-token-field"]')
    end

    context 'when revoking an existing token' do
      let(:token) { create(:personal_access_token, user: service_account, name: 'revoke-me') }

      before do
        token
      end

      it 'revokes a token' do
        navigate_to_token_management(send(path_helper_method, resource))

        expect(page).to have_css('[data-testid="field-name"]', text: 'revoke-me')

        find_by_testid('access-token-options').click
        click_button s_('AccessTokens|Revoke')

        within '#token-action-modal' do
          click_button s_('AccessTokens|Revoke')
        end

        expect(page).to have_content(s_('AccessTokens|The token was revoked successfully.'))
        expect(page).not_to have_css('[data-testid="field-name"]', text: 'revoke-me')
      end
    end

    context 'when rotating an existing token' do
      let(:token) { create(:personal_access_token, user: service_account, name: 'rotate-me') }

      before do
        token
      end

      it 'rotates a token' do
        navigate_to_token_management(send(path_helper_method, resource))

        expect(page).to have_css('[data-testid="field-name"]', text: 'rotate-me')

        find_by_testid('access-token-options').click
        click_button s_('AccessTokens|Rotate')

        within '#token-action-modal' do
          click_button s_('AccessTokens|Rotate')
        end

        expect(page).to have_content(s_('AccessTokens|Your token'))
        expect(page).to have_css('[data-testid="created-access-token-field"]')
      end
    end
  end
end
