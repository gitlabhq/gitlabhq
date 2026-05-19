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

    context 'with uniqueness_check: true' do
      subject(:finder) { described_class.new(strategy, token, unscoped, uniqueness_check: true) }

      it 'finds the job using partition-scoped query only' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to eq(job)
        end

        expect(recorder.count).to eq(1)
        expect(recorder.log.first).to match(/"p_ci_builds"."token_encrypted" IN/)
        expect(recorder.log.first).to match(/"p_ci_builds"."partition_id" =/)
      end

      context 'when partition_id is incorrect (fast-path miss)' do
        before do
          allow(::Ci::Builds::TokenPrefix).to receive(:decode_partition).with(token).and_return(999)
        end

        it 'returns nil without falling back to all-partitions query' do
          recorder = ActiveRecord::QueryRecorder.new do
            expect(finder.execute).to be_nil
          end

          expect(recorder.count).to eq(1)
          expect(recorder.log.first).to match(/"p_ci_builds"."partition_id" =/)
        end
      end
    end

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

      it 'returns nil without querying the database' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to be_nil
        end

        expect(recorder.count).to eq(0)
      end
    end

    context 'when the token has a known non-job prefix' do
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

    context 'when the token has the CI job prefix but partition_key is blank' do
      let(:token) { "#{Ci::Build::TOKEN_PREFIX}invalidpartition" }

      before do
        allow(::Ci::Builds::TokenPrefix).to receive(:decode_partition).with(token).and_return(nil)
      end

      it 'returns nil without querying the database' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(finder.execute).to be_nil
        end

        expect(recorder.count).to eq(0)
      end
    end
  end
end
