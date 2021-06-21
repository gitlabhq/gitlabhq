# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateBuildQueueService do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  describe 'pending builds queue push / pop' do
    describe '#push' do
      let(:transition) { double('transition') }

      before do
        allow(transition).to receive(:to).and_return('pending')
        allow(transition).to receive(:within_transaction).and_yield
      end

      context 'when pending build can be created' do
        it 'creates a new pending build in transaction' do
          queued = subject.push(build, transition)

          expect(queued).to eq build.id
        end

        it 'increments queue push metric' do
          metrics = spy('metrics')

          described_class.new(metrics).push(build, transition)

          expect(metrics)
            .to have_received(:increment_queue_operation)
            .with(:build_queue_push)
        end
      end

      context 'when invalid transition is detected' do
        it 'raises an error' do
          allow(transition).to receive(:to).and_return('created')

          expect { subject.push(build, transition) }
            .to raise_error(described_class::InvalidQueueTransition)
        end
      end

      context 'when duplicate entry exists' do
        before do
          create(:ci_pending_build, build: build, project: build.project)
        end

        it 'does nothing and returns build id' do
          queued = subject.push(build, transition)

          expect(queued).to eq build.id
        end
      end
    end

    describe '#pop' do
      let(:transition) { double('transition') }

      before do
        allow(transition).to receive(:from).and_return('pending')
        allow(transition).to receive(:within_transaction).and_yield
      end

      context 'when pending build exists' do
        before do
          create(:ci_pending_build, build: build, project: build.project)
        end

        it 'removes pending build in a transaction' do
          dequeued = subject.pop(build, transition)

          expect(dequeued).to eq build.id
        end

        it 'increments queue pop metric' do
          metrics = spy('metrics')

          described_class.new(metrics).pop(build, transition)

          expect(metrics)
            .to have_received(:increment_queue_operation)
            .with(:build_queue_pop)
        end
      end

      context 'when pending build does not exist' do
        it 'does nothing if there is no pending build to remove' do
          dequeued = subject.pop(build, transition)

          expect(dequeued).to be_nil
        end
      end

      context 'when invalid transition is detected' do
        it 'raises an error' do
          allow(transition).to receive(:from).and_return('created')

          expect { subject.pop(build, transition) }
            .to raise_error(described_class::InvalidQueueTransition)
        end
      end
    end
  end

  describe 'shared runner builds tracking' do
    let(:runner) { create(:ci_runner, :instance_type) }
    let(:build) { create(:ci_build, runner: runner, pipeline: pipeline) }

    describe '#track' do
      let(:transition) { double('transition') }

      before do
        allow(transition).to receive(:to).and_return('running')
        allow(transition).to receive(:within_transaction).and_yield
      end

      context 'when a shared runner build can be tracked' do
        it 'creates a new shared runner build tracking entry' do
          build_id = subject.track(build, transition)

          expect(build_id).to eq build.id
        end

        it 'increments new shared runner build metric' do
          metrics = spy('metrics')

          described_class.new(metrics).track(build, transition)

          expect(metrics)
            .to have_received(:increment_queue_operation)
            .with(:shared_runner_build_new)
        end
      end

      context 'when invalid transition is detected' do
        it 'raises an error' do
          allow(transition).to receive(:to).and_return('pending')

          expect { subject.track(build, transition) }
            .to raise_error(described_class::InvalidQueueTransition)
        end
      end

      context 'when duplicate entry exists' do
        before do
          create(:ci_running_build, build: build, project: project, runner: runner)
        end

        it 'does nothing and returns build id' do
          build_id = subject.track(build, transition)

          expect(build_id).to eq build.id
        end
      end
    end

    describe '#untrack' do
      let(:transition) { double('transition') }

      before do
        allow(transition).to receive(:from).and_return('running')
        allow(transition).to receive(:within_transaction).and_yield
      end

      context 'when shared runner build tracking entry exists' do
        before do
          create(:ci_running_build, build: build, project: project, runner: runner)
        end

        it 'removes shared runner build' do
          build_id = subject.untrack(build, transition)

          expect(build_id).to eq build.id
        end

        it 'increments shared runner build done metric' do
          metrics = spy('metrics')

          described_class.new(metrics).untrack(build, transition)

          expect(metrics)
            .to have_received(:increment_queue_operation)
            .with(:shared_runner_build_done)
        end
      end

      context 'when tracking entry does not exist' do
        it 'does nothing if there is no tracking entry to remove' do
          build_id = subject.untrack(build, transition)

          expect(build_id).to be_nil
        end
      end

      context 'when invalid transition is detected' do
        it 'raises an error' do
          allow(transition).to receive(:from).and_return('pending')

          expect { subject.untrack(build, transition) }
            .to raise_error(described_class::InvalidQueueTransition)
        end
      end
    end
  end

  describe '#tick' do
    shared_examples 'refreshes runner' do
      it 'ticks runner queue value' do
        expect { subject.tick(build) }.to change { runner.ensure_runner_queue_value }
      end
    end

    shared_examples 'does not refresh runner' do
      it 'ticks runner queue value' do
        expect { subject.tick(build) }.not_to change { runner.ensure_runner_queue_value }
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

          subject.tick(build)
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

      context 'when ci_preload_runner_tags is enabled' do
        before do
          stub_feature_flags(
            ci_preload_runner_tags: true
          )
        end

        it 'does execute the same amount of queries regardless of number of runners' do
          control_count = ActiveRecord::QueryRecorder.new { subject.tick(build) }.count

          create_list(:ci_runner, 10, :project, :online, projects: [project], tag_list: %w[b c d])

          expect { subject.tick(build) }.not_to exceed_all_query_limit(control_count)
        end
      end

      context 'when ci_preload_runner_tags are disabled' do
        before do
          stub_feature_flags(
            ci_preload_runner_tags: false
          )
        end

        it 'does execute more queries for more runners' do
          control_count = ActiveRecord::QueryRecorder.new { subject.tick(build) }.count

          create_list(:ci_runner, 10, :project, :online, projects: [project], tag_list: %w[b c d])

          expect { subject.tick(build) }.to exceed_all_query_limit(control_count)
        end
      end
    end
  end
end
