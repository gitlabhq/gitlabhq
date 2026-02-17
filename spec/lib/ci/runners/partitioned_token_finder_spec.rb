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
  end
end
