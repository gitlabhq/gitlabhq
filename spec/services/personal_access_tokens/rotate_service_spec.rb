# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::RotateService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:token, reload: true) { create(:personal_access_token, expires_at: Time.zone.today + 30.days) }
    let(:params) { {} }

    subject(:response) { described_class.new(token.user, token, nil, params).execute }

    shared_examples_for 'rotates token successfully' do
      it "rotates user's own token", :freeze_time do
        expect(response).to be_success

        new_token = response.payload[:personal_access_token]

        expect(new_token.token).not_to eq(token.token)
        expect(new_token.expires_at).to eq(Time.zone.today + 1.week)
        expect(new_token.user).to eq(token.user)
        expect(new_token.organization).to eq(token.organization)
        expect(new_token.description).to eq(token.description)
      end
    end

    it_behaves_like "rotates token successfully"

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

    context 'when expires_at param is set' do
      let(:params) { { expires_at: Time.zone.today + 60.days } }

      it 'sets the custom expiration time', :freeze_time do
        response

        new_token = response.payload[:personal_access_token]
        expect(new_token.expires_at).to eql(Time.zone.today + 60.days)
      end
    end

    context 'when keep_token_lifetime param is set' do
      let(:params) { { keep_token_lifetime: true } }

      it 'keeps the lifetime of the new token the same with the old token', :freeze_time do
        travel 1.day

        response

        new_token = response.payload[:personal_access_token]
        expect(new_token.expires_at).to eql(Time.zone.today + 30.days)
      end

      context 'when token never expires' do
        before do
          allow_next_instance_of(PersonalAccessToken) do |token|
            allow(token).to receive(:allow_expires_at_to_be_empty?).and_return(true)
          end
          token.update!(expires_at: nil)
        end

        it 'sets the new token to never expire' do
          response

          new_token = response.payload[:personal_access_token]
          expect(new_token.expires_at).to be_nil
        end
      end
    end

    context 'when user tries to rotate already revoked token' do
      let_it_be(:token, reload: true) { create(:personal_access_token, :revoked) }

      it 'returns an error' do
        expect { response }.not_to change { token.reload.revoked? }.from(true)
        expect(response).to be_error
        expect(response.message).to eq(s_('AccessTokens|Token already revoked'))
      end
    end

    context 'when revoking previous token fails' do
      it 'returns an error' do
        expect(token).to receive(:revoke!).and_return(false)

        expect(response).to be_error
      end
    end

    context 'when creating the new token fails' do
      before do
        # change the default expiration for rotation to create an invalid token
        stub_const('::PersonalAccessTokens::RotateService::EXPIRATION_PERIOD', 10.years)
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to include('Expiration date must be before')
      end

      it 'reverts the changes' do
        expect { response }.not_to change { token.reload.revoked? }.from(false)
      end
    end
  end
end
