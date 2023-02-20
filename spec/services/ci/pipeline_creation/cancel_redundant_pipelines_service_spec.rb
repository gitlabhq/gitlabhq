# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::CancelRedundantPipelinesService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:prev_pipeline) { create(:ci_pipeline, project: project) }
  let!(:new_commit) { create(:commit, project: project) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: new_commit.sha) }

  let(:service) { described_class.new(pipeline) }

  before do
    create(:ci_build, :interruptible, :running, pipeline: prev_pipeline)
    create(:ci_build, :interruptible, :success, pipeline: prev_pipeline)
    create(:ci_build, :created, pipeline: prev_pipeline)

    create(:ci_build, :interruptible, pipeline: pipeline)
  end

  describe '#execute!' do
    subject(:execute) { service.execute }

    context 'when build statuses are set up correctly' do
      it 'has builds of all statuses' do
        expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')
        expect(build_statuses(pipeline)).to contain_exactly('pending')
      end
    end

    context 'when auto-cancel is enabled' do
      before do
        project.update!(auto_cancel_pending_pipelines: 'enabled')
      end

      it 'cancels only previous interruptible builds' do
        execute

        expect(build_statuses(prev_pipeline)).to contain_exactly('canceled', 'success', 'canceled')
        expect(build_statuses(pipeline)).to contain_exactly('pending')
      end

      it 'logs canceled pipelines' do
        allow(Gitlab::AppLogger).to receive(:info)

        execute

        expect(Gitlab::AppLogger).to have_received(:info).with(
          class: described_class.name,
          message: "Pipeline #{pipeline.id} auto-canceling pipeline #{prev_pipeline.id}",
          canceled_pipeline_id: prev_pipeline.id,
          canceled_by_pipeline_id: pipeline.id,
          canceled_by_pipeline_source: pipeline.source
        )
      end

      it 'cancels the builds with 2 queries to avoid query timeout' do
        second_query_regex = /WHERE "ci_pipelines"\."id" = \d+ AND \(NOT EXISTS/
        recorder = ActiveRecord::QueryRecorder.new { execute }
        second_query = recorder.occurrences.keys.filter { |occ| occ =~ second_query_regex }

        expect(second_query).to be_one
      end

      context 'when the previous pipeline has a child pipeline' do
        let(:child_pipeline) { create(:ci_pipeline, child_of: prev_pipeline) }

        context 'with another nested child pipeline' do
          let(:another_child_pipeline) { create(:ci_pipeline, child_of: child_pipeline) }

          before do
            create(:ci_build, :interruptible, :running, pipeline: another_child_pipeline)
            create(:ci_build, :interruptible, :running, pipeline: another_child_pipeline)
          end

          it 'cancels all nested child pipeline builds' do
            expect(build_statuses(another_child_pipeline)).to contain_exactly('running', 'running')

            execute

            expect(build_statuses(another_child_pipeline)).to contain_exactly('canceled', 'canceled')
          end
        end

        context 'when started after pipeline was finished' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
            prev_pipeline.update!(status: "success")
          end

          it 'cancels child pipeline builds' do
            expect(build_statuses(child_pipeline)).to contain_exactly('running')

            execute

            expect(build_statuses(child_pipeline)).to contain_exactly('canceled')
          end
        end

        context 'when the child pipeline has interruptible running jobs' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
          end

          it 'cancels all child pipeline builds' do
            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'running')

            execute

            expect(build_statuses(child_pipeline)).to contain_exactly('canceled', 'canceled')
          end

          context 'when the child pipeline includes completed interruptible jobs' do
            before do
              create(:ci_build, :interruptible, :failed, pipeline: child_pipeline)
              create(:ci_build, :interruptible, :success, pipeline: child_pipeline)
            end

            it 'cancels all child pipeline builds with a cancelable_status' do
              expect(build_statuses(child_pipeline)).to contain_exactly('running', 'running', 'failed', 'success')

              execute

              expect(build_statuses(child_pipeline)).to contain_exactly('canceled', 'canceled', 'failed', 'success')
            end
          end
        end

        context 'when the child pipeline has started non-interruptible job' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
            # non-interruptible started
            create(:ci_build, :success, pipeline: child_pipeline)
          end

          it 'does not cancel any child pipeline builds' do
            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'success')

            execute

            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'success')
          end
        end

        context 'when the child pipeline has non-interruptible non-started job' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
          end

          not_started_statuses = Ci::HasStatus::AVAILABLE_STATUSES - Ci::HasStatus::STARTED_STATUSES
          context 'when the jobs are cancelable' do
            cancelable_not_started_statuses =
              Set.new(not_started_statuses).intersection(Ci::HasStatus::CANCELABLE_STATUSES)
            cancelable_not_started_statuses.each do |status|
              it "cancels all child pipeline builds when build status #{status} included" do
                # non-interruptible but non-started
                create(:ci_build, status.to_sym, pipeline: child_pipeline)

                expect(build_statuses(child_pipeline)).to contain_exactly('running', status)

                execute

                expect(build_statuses(child_pipeline)).to contain_exactly('canceled', 'canceled')
              end
            end
          end

          context 'when the jobs are not cancelable' do
            not_cancelable_not_started_statuses = not_started_statuses - Ci::HasStatus::CANCELABLE_STATUSES
            not_cancelable_not_started_statuses.each do |status|
              it "does not cancel child pipeline builds when build status #{status} included" do
                # non-interruptible but non-started
                create(:ci_build, status.to_sym, pipeline: child_pipeline)

                expect(build_statuses(child_pipeline)).to contain_exactly('running', status)

                execute

                expect(build_statuses(child_pipeline)).to contain_exactly('canceled', status)
              end
            end
          end
        end
      end

      context 'when the pipeline is a child pipeline' do
        let!(:parent_pipeline) { create(:ci_pipeline, project: project, sha: new_commit.sha) }
        let(:pipeline) { create(:ci_pipeline, child_of: parent_pipeline) }

        before do
          create(:ci_build, :interruptible, :running, pipeline: parent_pipeline)
          create(:ci_build, :interruptible, :running, pipeline: parent_pipeline)
        end

        it 'does not cancel any builds' do
          expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')
          expect(build_statuses(parent_pipeline)).to contain_exactly('running', 'running')

          execute

          expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')
          expect(build_statuses(parent_pipeline)).to contain_exactly('running', 'running')
        end
      end

      context 'when the previous pipeline source is webide' do
        let(:prev_pipeline) { create(:ci_pipeline, :webide, project: project) }

        it 'does not cancel builds of the previous pipeline' do
          execute

          expect(build_statuses(prev_pipeline)).to contain_exactly('created', 'running', 'success')
          expect(build_statuses(pipeline)).to contain_exactly('pending')
        end
      end

      it 'does not cancel future pipelines' do
        expect(prev_pipeline.id).to be < pipeline.id
        expect(build_statuses(pipeline)).to contain_exactly('pending')
        expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')

        described_class.new(prev_pipeline).execute

        expect(build_statuses(pipeline.reload)).to contain_exactly('pending')
      end
    end

    context 'when auto-cancel is disabled' do
      before do
        project.update!(auto_cancel_pending_pipelines: 'disabled')
      end

      it 'does not cancel any build' do
        subject

        expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')
        expect(build_statuses(pipeline)).to contain_exactly('pending')
      end
    end
  end

  private

  def build_statuses(pipeline)
    pipeline.builds.pluck(:status)
  end
end
