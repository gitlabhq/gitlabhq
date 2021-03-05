# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateBuildQueueService do
  let(:project) { create(:project, :repository) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  shared_examples 'refreshes runner' do
    it 'ticks runner queue value' do
      expect { subject.execute(build) }.to change { runner.ensure_runner_queue_value }
    end
  end

  shared_examples 'does not refresh runner' do
    it 'ticks runner queue value' do
      expect { subject.execute(build) }.not_to change { runner.ensure_runner_queue_value }
    end
  end

  shared_examples 'matching build' do
    context 'when there is a online runner that can pick build' do
      before do
        runner.update!(contacted_at: 30.minutes.ago)
      end

      it_behaves_like 'refreshes runner'

      it 'avoids running redundant queries' do
        expect(Ci::Runner).not_to receive(:owned_or_instance_wide)

        subject.execute(build)
      end

      context 'when feature flag ci_reduce_queries_when_ticking_runner_queue is disabled' do
        before do
          stub_feature_flags(ci_reduce_queries_when_ticking_runner_queue: false)
          stub_feature_flags(ci_runners_short_circuit_assignable_for: false)
        end

        it 'runs redundant queries using `owned_or_instance_wide` scope' do
          expect(Ci::Runner).to receive(:owned_or_instance_wide).and_call_original

          subject.execute(build)
        end
      end
    end
  end

  shared_examples 'mismatching tags' do
    context 'when there is no runner that can pick build due to tag mismatch' do
      before do
        build.tag_list = [:docker]
      end

      it_behaves_like 'does not refresh runner'
    end
  end

  shared_examples 'recent runner queue' do
    context 'when there is runner with expired cache' do
      before do
        runner.update!(contacted_at: Ci::Runner.recent_queue_deadline)
      end

      it_behaves_like 'does not refresh runner'
    end
  end

  context 'when updating specific runners' do
    let(:runner) { create(:ci_runner, :project, projects: [project]) }

    it_behaves_like 'matching build'
    it_behaves_like 'mismatching tags'
    it_behaves_like 'recent runner queue'

    context 'when the runner is assigned to another project' do
      let(:another_project) { create(:project) }
      let(:runner) { create(:ci_runner, :project, projects: [another_project]) }

      it_behaves_like 'does not refresh runner'
    end
  end

  context 'when updating shared runners' do
    let(:runner) { create(:ci_runner, :instance) }

    it_behaves_like 'matching build'
    it_behaves_like 'mismatching tags'
    it_behaves_like 'recent runner queue'

    context 'when there is no runner that can pick build due to being disabled on project' do
      before do
        build.project.shared_runners_enabled = false
      end

      it_behaves_like 'does not refresh runner'
    end
  end

  context 'when updating group runners' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:runner) { create(:ci_runner, :group, groups: [group]) }

    it_behaves_like 'matching build'
    it_behaves_like 'mismatching tags'
    it_behaves_like 'recent runner queue'

    context 'when there is no runner that can pick build due to being disabled on project' do
      before do
        build.project.group_runners_enabled = false
      end

      it_behaves_like 'does not refresh runner'
    end
  end

  context 'avoids N+1 queries', :request_store do
    let!(:build) { create(:ci_build, pipeline: pipeline, tag_list: %w[a b]) }
    let!(:project_runner) { create(:ci_runner, :project, :online, projects: [project], tag_list: %w[a b c]) }

    context 'when ci_preload_runner_tags and ci_reduce_queries_when_ticking_runner_queue are enabled' do
      before do
        stub_feature_flags(
          ci_reduce_queries_when_ticking_runner_queue: true,
          ci_preload_runner_tags: true
        )
      end

      it 'does execute the same amount of queries regardless of number of runners' do
        control_count = ActiveRecord::QueryRecorder.new { subject.execute(build) }.count

        create_list(:ci_runner, 10, :project, :online, projects: [project], tag_list: %w[b c d])

        expect { subject.execute(build) }.not_to exceed_all_query_limit(control_count)
      end
    end

    context 'when ci_preload_runner_tags and ci_reduce_queries_when_ticking_runner_queue are disabled' do
      before do
        stub_feature_flags(
          ci_reduce_queries_when_ticking_runner_queue: false,
          ci_preload_runner_tags: false
        )
      end

      it 'does execute more queries for more runners' do
        control_count = ActiveRecord::QueryRecorder.new { subject.execute(build) }.count

        create_list(:ci_runner, 10, :project, :online, projects: [project], tag_list: %w[b c d])

        expect { subject.execute(build) }.to exceed_all_query_limit(control_count)
      end
    end
  end
end
