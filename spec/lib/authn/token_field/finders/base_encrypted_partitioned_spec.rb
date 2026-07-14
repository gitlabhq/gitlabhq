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

        context 'when fast-path misses (partition_scope returns nothing)' do
          before do
            allow(finder).to receive(:partition_scope).and_return(Ci::Runner.none)
          end

          it 'falls back to base_scope query and logs the fallback outcome' do
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                Labkit::Fields::CLASS_NAME => described_class.name,
                Labkit::Fields::LOG_MESSAGE => "Partition pruning missed, falling back to all partitions query",
                has_prefix: "Authn::Tokens::RunnerAuthenticationToken",
                partition_key: 1,
                fallback_record_id: runner.id,
                fallback_record_partition_id: runner.partition_id,
                token_length: token.length,
                token_dot_count: token.count('.')
              )
            )

            expect(finder.execute).to eq(runner)
          end

          it 'does not log the token or any portion of it' do
            expect(Gitlab::AppLogger).to receive(:info) do |payload|
              payload.each_value do |value|
                expect(value.to_s).not_to include(token)
              end
            end

            finder.execute
          end

          context 'when the fallback query also finds nothing' do
            before do
              allow(finder).to receive(:base_scope).and_return(Ci::Runner.none)
            end

            it 'logs that no record was found and returns nil', :aggregate_failures do
              expect(Gitlab::AppLogger).to receive(:info).with(
                hash_including(
                  fallback_record_id: nil,
                  fallback_record_partition_id: nil
                )
              )

              expect(finder.execute).to be_nil
            end
          end
        end
      end
    end
  end
end
