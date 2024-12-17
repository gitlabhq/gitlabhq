# frozen_string_literal: true

RSpec.shared_examples 'token handling with unsupported token type' do
  context 'with unsupported token type' do
    let_it_be(:plaintext) { 'unsupported' }

    describe '#initialize' do
      it 'is nil when the token type is not supported' do
        expect(token.revocable).to be_nil
      end
    end

    describe '#revoke!' do
      it 'raises error when the token type is not found' do
        expect do
          token.revoke!(user)
        end
          .to raise_error(::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found')
      end
    end
  end
end

RSpec.shared_examples 'finding the valid revocable' do
  describe '#initialize' do
    it 'finds the plaintext token' do
      expect(token.revocable).to eq(valid_revocable)
    end
  end

  describe '#present_with' do
    it 'returns a constant that is a subclass of Grape::Entity' do
      expect(token.present_with).to be <= Grape::Entity
    end
  end
end

RSpec.shared_examples 'rotating token succeeds' do |token_type|
  it "displays the newly created token" do
    visit resource_settings_access_tokens_path
    accept_gl_confirm(button_text: s_('AccessTokens|Rotate')) { click_on s_('AccessTokens|Rotate') }

    wait_for_all_requests
    expect(page).to have_content("Your new #{token_type} access token has been created.")
    expect(active_access_tokens).to have_text(resource_access_token.name)
    expect(created_access_token).to match(/[\w-]{20}/)
  end
end

RSpec.shared_examples 'rotating already revoked token fails' do
  it "displays an error message" do
    visit resource_settings_access_tokens_path

    accept_gl_confirm(button_text: s_('AccessTokens|Rotate')) do
      resource_access_token.revoke!
      click_on s_('AccessTokens|Rotate')
    end

    wait_for_all_requests
    expect(page).to have_content(s_('AccessTokens|Token already revoked'))
  end
end

RSpec.shared_examples 'rotating token fails due to missing access rights' do |token_type|
  it 'does not rotate token' do
    owner_role = resource.add_owner(user)

    visit resource_settings_access_tokens_path

    accept_gl_confirm(button_text: s_('AccessTokens|Rotate')) do
      owner_role.destroy!
      click_on s_('AccessTokens|Rotate')
    end

    wait_for_all_requests
    expect(page).not_to have_content("Your new #{token_type} access token has been created.")
  end
end
