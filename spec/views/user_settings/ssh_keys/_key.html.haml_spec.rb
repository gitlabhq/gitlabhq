# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/ssh_keys/_key.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:key).and_return(key)
    allow(view).to receive(:is_admin).and_return(false)
  end

  context 'when the key partial is used' do
    let_it_be(:key) do
      build_stubbed(
        :personal_key,
        user: user,
        last_used_at: 7.days.ago,
        expires_at: 2.days.from_now
      )
    end

    it 'displays the correct values', :aggregate_failures do
      render

      expect(rendered).to have_text(key.title)
      expect(rendered).to have_css('[data-testid="key-icon"]')
      expect(rendered).to have_text(key.fingerprint)
      expect(rendered).to have_text(l(key.created_at, format: "%b %d, %Y"))
      expect(rendered).to have_text(key.expires_at.to_date)
      expect(rendered).to have_button('Remove')
    end

    it 'displays the correct last used date' do
      render

      expect(rendered).to have_text(l(key.last_used_at, format: "%b %d, %Y"))
    end

    context 'when the key has not been used' do
      let_it_be(:key) do
        build_stubbed(:personal_key, user: user, last_used_at: nil)
      end

      it 'renders "Never" for last used' do
        render

        expect(rendered).to have_text('Never')
      end
    end

    context 'when usage type is displayed' do
      where(:usage_type, :usage_type_text, :displayed_buttons, :hidden_buttons) do
        [
          [:auth, 'Authentication', ['Remove'], ['Revoke']],
          [:auth_and_signing, 'Authentication & Signing', %w[Remove Revoke], []],
          [:signing, 'Signing', %w[Remove Revoke], []]
        ]
      end

      with_them do
        let(:key) { build_stubbed(:key, user: user, usage_type: usage_type) }

        it 'renders usage type text and remove/revoke buttons', :aggregate_failures do
          render

          expect(rendered).to have_text(usage_type_text)

          displayed_buttons.each do |button|
            expect(rendered).to have_css("button[aria-label=#{button}]")
          end

          hidden_buttons.each do |button|
            expect(rendered).not_to have_css("button[aria-label=#{button}]")
          end
        end
      end
    end

    context 'when the key does not have an expiration date' do
      let_it_be(:key) do
        build_stubbed(:personal_key, user: user, expires_at: nil)
      end

      it 'renders "Never" for expires' do
        render

        expect(rendered).to have_text('Never')
      end
    end

    context 'when the key has expired' do
      let_it_be(:key) { build_stubbed(:personal_key, :expired, user: user) }

      it 'renders "Expired" as the expiration date label' do
        render

        expect(rendered).to have_text('Expired')
      end
    end

    context 'when the key is not deletable' do
      # Turns out key.can_delete? is only false for LDAP keys
      # but LDAP keys don't exist outside EE
      before do
        allow(key).to receive(:can_delete?).and_return(false)
      end

      it 'does not render the partial' do
        render

        expect(response).not_to have_text('Remove')
        expect(response).not_to have_text('Revoke')
      end
    end

    context 'for icon tooltip' do
      using RSpec::Parameterized::TableSyntax

      where(:valid, :expiry, :result) do
        false | 2.days.from_now | 'Key type is forbidden. Must be DSA, ECDSA, ED25519, ECDSA_SK, or ED25519_SK'
        true  | 2.days.from_now | ''
      end

      with_them do
        let_it_be(:key) do
          build_stubbed(:personal_key, user: user)
        end

        it 'renders the correct icon', :aggregate_failures do
          stub_application_setting(rsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE) unless valid

          key.expires_at = expiry

          render

          if result.empty?
            expect(rendered).to have_css('[data-testid="key-icon"]')
          else
            expect(rendered).to have_css('[data-testid="warning-solid-icon"]')
            expect(rendered).to have_selector("span.has-tooltip[title='#{result}']")
          end
        end
      end
    end
  end
end
