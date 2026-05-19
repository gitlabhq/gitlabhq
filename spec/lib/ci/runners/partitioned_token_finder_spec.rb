# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::PartitionedTokenFinder, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:token) { runner.token }
    let(:strategy) { Authn::TokenField::Encrypted.fabricate(Ci::Runner, :token, options) }
    let(:unscoped) { true }
    let(:options) do
      { encrypted: :required,
        expires_at: :compute_token_expiration,
        format_with_prefix: :prefix_for_new_and_legacy_runner }
    end

    subject(:finder) { described_class.new(strategy, token, unscoped) }

    context 'with uniqueness_check: true' do
      subject(:finder) { described_class.new(strategy, token, unscoped, uniqueness_check: true) }

      it 'finds the runner using runner_type-scoped query only' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(runner)
        end

        expect(recorder.count).to eq(1)
        expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
        expect(recorder.log.first).to match(/"ci_runners"."runner_type" =/)
      end

      context 'when runner_type is incorrect (fast-path miss)' do
        before do
          allow(::Ci::Runners::TokenPartition).to receive_message_chain(:new, :decode).and_return('project_type')
        end

        it 'returns nil without falling back to all-partitions query' do
          recorder = ActiveRecord::QueryRecorder.new do
            expect(finder.execute).to be_nil
          end

          expect(recorder.count).to eq(1)
          expect(recorder.log.first).to match(/"ci_runners"."runner_type" =/)
        end
      end
    end

    it 'uses runner_type filter in query' do
      recorder = ActiveRecord::QueryRecorder.new do
        expect(finder.execute).to eq(runner)
      end

      expect(recorder.count).to eq(1)
      expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
      expect(recorder.log.first).to match(/"ci_runners"."runner_type" =/)
    end

    context 'when runner_type is incorrect' do
      before do
        allow(::Ci::Runners::TokenPartition).to receive_message_chain(:new, :decode).and_return('project_type')
      end

      it 'falls back to all partitions' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(runner)
        end

        expect(recorder.count).to eq(2)
        expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
        expect(recorder.log.first).to match(/"ci_runners"."runner_type" =/)
        expect(recorder.log.second).to match(/"ci_runners"."token_encrypted" IN/)
        expect(recorder.log.second).not_to match(/"ci_runners"."runner_type" =/)
      end
    end

    context 'when runner_type cannot be decoded' do
      before do
        allow(::Ci::Runners::TokenPartition).to receive_message_chain(:new, :decode).and_return(nil)
      end

      it 'queries all partitions without partition filter' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(runner)
        end

        expect(recorder.count).to eq(1)
        expect(recorder.log.first).to match(/"ci_runners"."token_encrypted" IN/)
        expect(recorder.log.first).not_to match(/"ci_runners"."runner_type" =/)
      end
    end

    context 'when the token has a known non-runner prefix' do
      let(:token) { 'glpat-abc123' }

      it 'returns nil without querying the database' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to be_nil
        end

        expect(recorder.count).to eq(0)
      end
    end

    context 'when the token has no prefix (legacy token)' do
      let(:token) { 'abc123xyz' }

      it 'does not exclude the token and queries the database' do
        recorder = ActiveRecord::QueryRecorder.new { finder.execute }

        expect(recorder.count).to be > 0
      end
    end
  end
end
