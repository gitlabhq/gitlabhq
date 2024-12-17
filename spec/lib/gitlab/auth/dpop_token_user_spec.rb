# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::DpopTokenUser, feature_category: :system_access do
  include Auth::DpopTokenHelper

  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

  let(:personal_access_token_plaintext) { personal_access_token.token }

  let(:ssh_public_key) { nil }
  let(:ath) { nil }
  let(:public_key_in_jwk) { nil }
  let(:dpop_proof) do
    generate_dpop_proof_for(user, ssh_public_key: ssh_public_key, ath: ath, public_key_in_jwk: public_key_in_jwk)
  end

  let(:dpop_token) do
    Gitlab::Auth::DpopToken.new(data: dpop_proof.proof)
  end

  describe '#validate!' do
    subject(:validate!) do
      described_class.new(token: dpop_token, user: user,
        personal_access_token_plaintext: personal_access_token_plaintext).validate!
    end

    context 'when the token is valid' do
      it 'initializes with valid token' do
        expect { validate! }.not_to raise_error
      end
    end

    context "when input isn't valid" do
      context 'when the DPoP token is invalid' do
        let(:dpop_token) { Gitlab::Auth::DpopToken.new(data: 'invalid') }

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Malformed JWT, unable to decode. Not enough or too many segments/)
        end
      end

      context "when the PAT doesn't belong to the user" do
        let(:personal_access_token_plaintext) { 'invalid' }

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Personal access token does not belong to the requesting user/)
        end
      end

      context "when the DPoP token isn't valid for the user" do
        context "when the jwk value is malformed" do
          let(:public_key_in_jwk) { { kty: Auth::DpopTokenHelper::VALID_KTY } }

          it 'raises DpopValidationError' do
            expect do
              validate!
            end.to raise_error(Gitlab::Auth::DpopValidationError,
              /Key format is invalid for RSA/)
          end
        end

        context "when the jwk value is invalid" do
          let(:public_key_in_jwk) { { kty: Auth::DpopTokenHelper::VALID_KTY, n: '', e: '' } }

          it 'raises DpopValidationError' do
            expect do
              validate!
            end.to raise_error(Gitlab::Auth::DpopValidationError,
              /Failed to parse JWK: invalid JWK/)
          end
        end
      end

      context 'when the access token hash is incorrect' do
        let(:ath) { 'incorrect' }

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Incorrect access token hash in JWT/)
        end
      end

      context 'when the SSH public key is invalid' do
        it 'raises DpopValidationError' do
          allow(SSHData::PublicKey).to receive(:parse_openssh)
            .with(dpop_proof.ssh_public_key)
            .and_raise(SSHData::DecodeError)

          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Unable to parse public key/)
        end
      end

      context 'when then SSH public key is unsupported' do
        let(:ssh_public_key) do
          # rubocop:disable Layout/LineLength -- Value is not important
          'ssh-dss AAAAB3NzaC1kc3MAAACBAIOcJlrYLOHfYxRY/i5nw2vcQZ8QpkNLObfjEBl5DsTWCXbKkkbNIkABpMjpH22nxJxzqolyiG8hwIRvtPmwUd3o4x+kvaWXmabPQhs6xDlHMV30ZXwliT5qjb04AkBtH1QH1wz6e9tEAMlUi7pCU76NREWjTjc30s+NmOIqItBhAAAAFQDhJ3PVkV2ytA24pZkr6QMppFzPxQAAAIBF4oicI5FBc0w4C8USL37NIa0uxrAPQ/Zkz3b0hdNNAmnNFjN9PihGrsTURa9zBgpV5tM2LfvS9qlAgnrbu7VY8NV0OSTxXeUfkn+k40DspHfY0sl8IKGvCYt0uO3tpfu0lZOJFgr/vFc4ODzE5QEm9eKMsWX8SJbRuXaGMn0myQAAAIBSzNgHW/lU/BgycBefJpe1NGnVVGRBPI9QHjxh/6HvyFHYc2N506wPDiRXyX03QREoUe4VXMWbOoFHpjZWX9dhwvvg3vBBQMeH7I5V0o5sEXbvdgtXBDtoiZlbZSiSC9wvw4c7rwSWsfm+iF1Ub1XPf2ALwh/BWHJzb93viCePcg=='
          # rubocop:enable Layout/LineLength
        end

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Currently only RSA keys are supported/)
        end
      end
    end
  end
end
