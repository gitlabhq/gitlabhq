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

        # TODO: remove below tests once the following issue is resolved
        # https://gitlab.com/gitlab-org/gitlab/-/work_items/594564
        it 'does not log when fast-path succeeds' do
          expect(Gitlab::AppLogger).not_to receive(:info)

          finder.execute
        end

        context 'when fast-path misses but fallback finds the record' do
          before do
            allow(finder).to receive(:partition_scope).and_return(Ci::Runner.none)
          end

          it 'logs fast-path miss and fallback found' do
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning fast-path miss: record not found in decoded partition",
                record_class: "Ci::Runner",
                partition_key: runner.partition_id
              )
            ).ordered

            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning fallback: found record",
                record_id: runner.id,
                record_partition_id: runner.partition_id,
                partition_key: runner.partition_id
              )
            ).ordered

            expect(finder.execute).to eq(runner)
          end
        end

        context 'when fast-path misses and fallback also finds nothing' do
          let(:unknown_token) { 'nonexistent_token' }

          subject(:finder) { described_class.new(strategy, unknown_token, unscoped) }

          before do
            allow(finder).to receive_messages(
              partition_scope: Ci::Runner.none,
              partition_key: -1
            )
          end

          it 'logs fast-path miss and fallback not-found' do
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning fast-path miss: record not found in decoded partition",
                record_class: "Ci::Runner",
                partition_key: -1
              )
            ).ordered

            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning fallback: record not-found",
                record_class: "Ci::Runner",
                partition_key: -1
              )
            ).ordered

            expect(finder.execute).to be_nil
          end
        end

        context 'when partition_key is blank and fallback finds the record' do
          before do
            allow(finder).to receive(:partition_key).and_return(nil)
          end

          it 'logs pruning skipped and fallback found' do
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning skipped: partition_key is blank",
                record_class: "Ci::Runner",
                token_prefix: token.to_s[0, 10]
              )
            ).ordered

            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning fallback: found record",
                record_id: runner.id,
                partition_key: nil
              )
            ).ordered

            expect(finder.execute).to eq(runner)
          end
        end

        context 'when partition_key is blank and fallback finds nothing' do
          let(:unknown_token) { 'nonexistent_token' }

          subject(:finder) { described_class.new(strategy, unknown_token, unscoped) }

          before do
            allow(finder).to receive(:partition_key).and_return(nil)
          end

          it 'logs pruning skipped and fallback not-found' do
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning skipped: partition_key is blank",
                record_class: "Ci::Runner",
                token_prefix: unknown_token[0, 10]
              )
            ).ordered

            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Partition pruning fallback: record not-found",
                record_class: "Ci::Runner",
                partition_key: nil
              )
            ).ordered

            expect(finder.execute).to be_nil
          end
        end
      end
    end
  end
end
