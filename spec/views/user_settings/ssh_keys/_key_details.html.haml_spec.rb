# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/ssh_keys/_key_details.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:key, key)
    allow(view).to receive(:is_admin).and_return(false)
  end

  describe 'displays the usage type' do
    where(:usage_type, :usage_type_text) do
      [
        [:auth, 'Authentication'],
        [:auth_and_signing, 'Authentication & Signing'],
        [:signing, 'Signing']
      ]
    end

    with_them do
      let(:key) { build_stubbed(:key, user: user, usage_type: usage_type) }

      it 'renders usage type text' do
        render

        expect(rendered).to have_text(usage_type_text)
      end
    end
  end

  describe 'displays key attributes' do
    let(:key) { build_stubbed(:key, :expired, last_used_at: Date.today, user: user) }

    it 'renders key attributes' do
      render

      expect(rendered).to have_text(key.title)
      expect(rendered).to have_text(key.created_at.to_fs(:medium))
      expect(rendered).to have_text(key.expires_at.to_fs(:medium))
      expect(rendered).to have_text(key.last_used_at.to_fs(:medium))
      expect(rendered).to have_text(key.fingerprint)
      expect(rendered).to have_text(key.fingerprint_sha256)
    end
  end
end
