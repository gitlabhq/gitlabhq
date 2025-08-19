# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::SshKeysController, feature_category: :source_code_management do
  let_it_be(:user) { create(:user, :with_namespace) }

  before do
    login_as(user)
  end

  describe 'GET #show' do
    context "with RSA Key" do
      let(:key_1024) { build(:rsa_key_1024).key }
      let(:key_2048) { build(:rsa_key_2048).key }

      it 'sets the weak key warning for a weak RSA key' do
        ssh_key = create(:key, user: user, key: key_1024)
        get user_settings_ssh_key_path(ssh_key)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include('Key length should be at least 2048 bits.')
      end

      it 'does not set the weak key warning for a strong RSA key' do
        ssh_key = create(:key, user: user, key: key_2048)
        get user_settings_ssh_key_path(ssh_key)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).not_to include('Key length should be at least 2048 bits.')
      end
    end

    context "with DSA key regardless of size" do
      where :factory do
        [:dsa_key_1024, :dsa_key_2048]
      end

      with_them do
        let(:key) { build(factory).key }

        it 'includes a warning about DSA being deprecated' do
          ssh_key = create(:key, user: user, key: key)
          get user_settings_ssh_key_path(ssh_key)

          expect(response).to have_gitlab_http_status(:success)
          expect(response.body).to include('DSA keys are considered deprecated.')
        end
      end
    end
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
