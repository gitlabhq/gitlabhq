# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::Finders::BaseEncrypted, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:token) { runner.token }
    let(:strategy) { Authn::TokenField::Encrypted.fabricate(Ci::Runner, :token, options) }
    let(:options) { { encrypted: :required, expires_at: :compute_token_expiration } }
    let(:unscoped) { true }

    subject(:finder) { described_class.new(strategy, token, unscoped) }

    it 'finds the runner using token_encrypted' do
      recorder = ActiveRecord::QueryRecorder.new do
        expect(finder.execute).to eq(runner)
      end

      expect(recorder.count).to eq(1)
      expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
      expect(recorder.log.first).not_to match(/token_expires_at >= NOW/)
    end

    context 'with false unscoped' do
      let(:unscoped) { false }

      it 'finds the runner using token_encrypted and token_expires_at' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(runner)
        end

        expect(recorder.count).to eq(1)
        expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
        expect(recorder.log.first).to match(/token_expires_at >= NOW/)
      end
    end

    context 'with several db_key_base keys' do
      include DbKeyBaseHelpers

      let(:new_key) { SecureRandom.hex(64) }

      it 'finds a token encrypted with the previous key' do
        stub_db_key_base_keys(Settings.db_key_base_keys.last, new_key)

        expect(finder.execute).to eq(runner)
      end

      it 'does not find it with an unrelated key only' do
        stub_db_key_base_keys(new_key)

        expect(finder.execute).to be_nil
      end
    end

    context 'with invalid strategy' do
      let(:strategy) { Authn::TokenField::Insecure.fabricate(Ci::Runner, :token, options) }
      let(:options) { { expires_at: :compute_token_expiration } }

      it 'raises argument error' do
        expect { finder.execute }
          .to raise_error(ArgumentError, 'Please provide an encrypted strategy.')
      end
    end
  end
end
