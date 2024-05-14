# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::SshKeysController, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'DELETE /-/profile/keys/:id/revoke' do
    it 'returns 404 if a key not found' do
      delete revoke_user_settings_ssh_key_path(non_existing_record_id)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'revokes ssh commit signatures' do
      key = create(:key, user: user)
      signature = create(:ssh_signature, key: key)

      expect do
        delete revoke_user_settings_ssh_key_path(signature.key)
      end.to change { signature.reload.key }.from(signature.key).to(nil)
        .and change { signature.verification_status }.from('verified').to('revoked_key')

      expect(response).to have_gitlab_http_status(:found)
    end
  end
end
