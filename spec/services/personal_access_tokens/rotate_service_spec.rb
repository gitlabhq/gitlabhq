# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::RotateService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:token, reload: true) { create(:personal_access_token) }

    subject(:response) { described_class.new(token.user, token).execute }

    shared_examples_for 'rotates token succesfully' do
      it "rotates user's own token", :freeze_time do
        expect(response).to be_success

        new_token = response.payload[:personal_access_token]

        expect(new_token.token).not_to eq(token.token)
        expect(new_token.expires_at).to eq(Date.today + 1.week)
        expect(new_token.user).to eq(token.user)
      end
    end

    it_behaves_like "rotates token succesfully"

    it 'revokes the previous token' do
      expect { response }.to change { token.reload.revoked? }.from(false).to(true)

      new_token = response.payload[:personal_access_token]
      expect(new_token).not_to be_revoked
    end

    it 'saves the previous token as previous PAT attribute' do
      response

      new_token = response.payload[:personal_access_token]
      expect(new_token.previous_personal_access_token).to eql(token)
    end

    context 'when user tries to rotate already revoked token' do
      let_it_be(:token, reload: true) { create(:personal_access_token, :revoked) }

      it 'returns an error' do
        expect { response }.not_to change { token.reload.revoked? }.from(true)
        expect(response).to be_error
        expect(response.message).to eq('token already revoked')
      end
    end

    context 'when revoking previous token fails' do
      it 'returns an error' do
        expect(token).to receive(:revoke!).and_return(false)

        expect(response).to be_error
      end
    end

    context 'when creating the new token fails' do
      let(:error_message) { 'boom!' }

      before do
        allow_next_instance_of(PersonalAccessToken) do |token|
          allow(token).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return(error_message)
          allow(token).to receive_message_chain(:errors, :clear)
          allow(token).to receive_message_chain(:errors, :empty?).and_return(false)
        end
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to eq(error_message)
      end

      it 'reverts the changes' do
        expect { response }.not_to change { token.reload.revoked? }.from(false)
      end
    end
  end
end
