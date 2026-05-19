# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::Finders::BaseEncryptedPartitioned, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:token) { runner.token }
    let(:strategy) { Authn::TokenField::Encrypted.fabricate(Ci::Runner, :token, options) }
    let(:options) { { encrypted: :required, expires_at: :compute_token_expiration } }
    let(:unscoped) { true }

    subject(:finder) { described_class.new(strategy, token, unscoped) }

    it 'raises not implemented error' do
      expect { finder.execute }
        .to raise_error(NotImplementedError)
    end

    context 'with implemented partition_key' do
      before do
        allow(finder).to receive(:partition_key).and_return(runner.partition_id)
      end

      it 'raises not implemented error' do
        expect { finder.execute }
          .to raise_error(NotImplementedError)
      end

      context 'with implemented' do
        before do
          allow(finder).to receive_messages(partition_key: runner.partition_id,
            partition_scope: Ci::Runner.with_runner_type(runner.runner_type))
        end

        it 'finds the runner using token_encrypted' do
          recorder = ActiveRecord::QueryRecorder.new do
            expect(finder.execute).to eq(runner)
          end

          expect(recorder.count).to eq(1)
          expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
          expect(recorder.log.first).to match(/"ci_runners"."runner_type" =/)
        end
      end
    end
  end
end
