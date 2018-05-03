require 'spec_helper'

describe FastDestroyAll, :clean_gitlab_redis_shared_state do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  describe 'Forbid #destroy and #destroy_all' do
    let(:build) { create(:ci_build, :running, :trace_live, pipeline: pipeline, project: project) }
    let(:trace_chunks) { build.trace_chunks }

    it 'does not delete database rows and associted external data' do
      expect(trace_chunks.first).to be_a(described_class)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(1)
        expect(trace_chunks.count).to eq(1)

        expect { trace_chunks.first.destroy }.to raise_error('`destroy` and `destroy_all` are forbbiden. Please use `fast_destroy_all`')
        expect { trace_chunks.destroy_all }.to raise_error('`destroy` and `destroy_all` are forbbiden. Please use `fast_destroy_all`')

        expect(trace_chunks.count).to eq(1)
        expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(1)
      end
    end
  end

  describe '.fast_destroy_all' do
    let(:build) { create(:ci_build, :running, :trace_live, pipeline: pipeline, project: project) }
    let(:trace_chunks) { build.trace_chunks }

    it 'deletes database rows and associted external data' do
      expect(trace_chunks.first).to be_a(described_class)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(1)
        expect(trace_chunks.count).to eq(1)

        expect { build.trace_chunks.fast_destroy_all }.not_to raise_error

        expect(trace_chunks.count).to eq(0)
        expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(0)
      end
    end
  end

  describe '.use_fast_destroy' do
    let(:build) { create(:ci_build, :running, :trace_live, pipeline: pipeline, project: project) }
    let(:trace_chunks) { build.trace_chunks }

    it 'performs cascading delete with fast_destroy_all' do
      expect(trace_chunks.first).to be_a(described_class)
      expect(project).to be_a(described_class::Helpers)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(1)
        expect(trace_chunks.count).to eq(1)

        project.destroy

        expect(trace_chunks.count).to eq(0)
        expect(redis.scan_each(match: "gitlab:ci:trace:*:chunks:*").to_a.size).to eq(0)
      end
    end
  end
end
