# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Jobs::PartitionedTokenFinder, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:job) { create(:ci_build, pipeline: pipeline, status: :running) }
    let_it_be(:token) { job.token }
    let(:strategy) { Authn::TokenField::Encrypted.fabricate(Ci::Build, :token, options) }
    let(:unscoped) { true }
    let(:options) do
      { encrypted: :required,
        format_with_prefix: :prefix_and_partition_for_token }
    end

    subject(:finder) { described_class.new(strategy, token, unscoped) }

    it 'uses partition_id filter in query' do
      recorder = ActiveRecord::QueryRecorder.new do
        expect(finder.execute).to eq(job)
      end

      expect(recorder.count).to eq(1)
      expect(recorder.log.first).to match(/"p_ci_builds"."token_encrypted" IN/)
      expect(recorder.log.first).to match(/"p_ci_builds"."partition_id" =/)
    end

    context 'when partition_id is incorrect' do
      before do
        allow(::Ci::Builds::TokenPrefix).to receive(:decode_partition).with(token).and_return(999)
      end

      it 'falls back to all partitions' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(job)
        end

        expect(recorder.count).to eq(2)
        expect(recorder.log.first).to match(/"p_ci_builds"."token_encrypted" IN/)
        expect(recorder.log.first).to match(/"p_ci_builds"."partition_id" =/)
        expect(recorder.log.second).to match(/"p_ci_builds"."token_encrypted" IN/)
        expect(recorder.log.second).not_to match(/"p_ci_builds"."partition_id" =/)
      end
    end

    context 'when partition_id cannot be decoded' do
      before do
        allow(::Ci::Builds::TokenPrefix).to receive(:decode_partition).with(token).and_return(nil)
      end

      it 'queries all partitions without partition filter' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(job)
        end

        expect(recorder.count).to eq(1)
        expect(recorder.log.first).to match(/"p_ci_builds"."token_encrypted" IN/)
        expect(recorder.log.first).not_to match(/"p_ci_builds"."partition_id" =/)
      end
    end
  end
end
