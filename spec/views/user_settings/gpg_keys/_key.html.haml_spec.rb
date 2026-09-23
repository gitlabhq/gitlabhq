# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/gpg_keys/_key.html.haml', feature_category: :user_profile do
  let(:user) { build_stubbed(:user, email: GpgHelpers::UserWithRevokedUid.emails.first) }

  before do
    allow(view).to receive_messages(key: key, is_admin: false, require_external_verification: false)
  end

  context 'when a uid of the key has been revoked' do
    let(:key) do
      build_stubbed(
        :gpg_key,
        user: user,
        key: GpgHelpers::UserWithRevokedUid.public_key,
        fingerprint: GpgHelpers::UserWithRevokedUid.fingerprint
      )
    end

    it 'lists the live uid only', :aggregate_failures do
      render

      expect(rendered).to have_text(GpgHelpers::UserWithRevokedUid.fingerprint)
      expect(rendered).to have_text("#{GpgHelpers::UserWithRevokedUid.emails.first} Verified")
      expect(rendered).not_to have_text(GpgHelpers::UserWithRevokedUid.revoked_emails.first)
    end
  end

  context 'when every uid of the key has been revoked' do
    let(:user) { build_stubbed(:user, email: GpgHelpers::UserWithOnlyRevokedUid.revoked_emails.first) }

    let(:key) do
      build_stubbed(
        :gpg_key,
        user: user,
        key: GpgHelpers::UserWithOnlyRevokedUid.public_key,
        fingerprint: GpgHelpers::UserWithOnlyRevokedUid.fingerprint
      )
    end

    it 'shows the fingerprint and no email', :aggregate_failures do
      render

      expect(rendered).to have_text(GpgHelpers::UserWithOnlyRevokedUid.fingerprint)
      expect(rendered).not_to have_text(GpgHelpers::UserWithOnlyRevokedUid.revoked_emails.first)
      expect(rendered).not_to have_text('Verified')
      expect(rendered).not_to have_text('Unverified')
    end
  end
end
