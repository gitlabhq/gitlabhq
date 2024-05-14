# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UserCancelPipelineWorker, :aggregate_failures, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline, :running) }
  let_it_be(:current_user) { create(:user) }
  let(:current_user_id) { current_user.id }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id, pipeline.id, current_user_id) }

    let(:cancel_service) { instance_double(::Ci::CancelPipelineService) }

    context 'when the user id is nil' do
      let(:current_user_id) { nil }

      it 'cancels the pipeline by calling force_execute' do
        allow(::Ci::Pipeline).to receive(:find_by_id).twice.and_return(pipeline)
        expect(::Ci::CancelPipelineService)
          .to receive(:new)
          .with(
            pipeline: pipeline,
            current_user: nil,
            auto_canceled_by_pipeline: pipeline,
            cascade_to_children: true)
          .and_return(cancel_service)

        expect(cancel_service).to receive(:execute)

        perform
      end
    end

    context 'when the current user id is provided' do
      context 'when the user does not exist' do
        let(:current_user_id) { non_existing_record_id }

        it 'cancels the pipeline by calling force_execute' do
          allow(::Ci::Pipeline).to receive(:find_by_id).twice.and_return(pipeline)
          expect(::Ci::CancelPipelineService)
            .to receive(:new)
            .with(
              pipeline: pipeline,
              current_user: nil,
              auto_canceled_by_pipeline: pipeline,
              cascade_to_children: true)
            .and_return(cancel_service)

          expect(cancel_service).to receive(:execute)

          perform
        end
      end

      context 'when the user exists' do
        it 'cancels the pipeline by calling execute' do
          allow(::Ci::Pipeline).to receive(:find_by_id).twice.and_return(pipeline)
          expect(::Ci::CancelPipelineService)
            .to receive(:new)
            .with(
              pipeline: pipeline,
              current_user: current_user,
              auto_canceled_by_pipeline: pipeline,
              cascade_to_children: true)
            .and_return(cancel_service)

          expect(cancel_service).to receive(:execute)

          perform
        end
      end
    end

    context 'if pipeline is deleted' do
      subject(:perform) { described_class.new.perform(non_existing_record_id, pipeline.id, current_user_id) }

      it 'does not error' do
        expect(::Ci::CancelPipelineService).not_to receive(:new)

        perform
      end
    end

    context 'when auto_canceled_by_pipeline is deleted' do
      subject(:perform) { described_class.new.perform(pipeline.id, non_existing_record_id, current_user_id) }

      it 'does not error' do
        expect(::Ci::CancelPipelineService)
          .to receive(:new)
          .with(
            pipeline: an_instance_of(::Ci::Pipeline),
            current_user: current_user,
            auto_canceled_by_pipeline: nil,
            cascade_to_children: true)
          .and_call_original

        perform
      end
    end

    describe 'with builds and state transition side effects', :sidekiq_inline do
      let!(:build) { create(:ci_build, :running, pipeline: pipeline) }
      let(:job_args) { [pipeline.id, pipeline.id, current_user_id] }

      context 'when the user id is nil' do
        let(:current_user_id) { nil }

        it_behaves_like 'an idempotent worker', :sidekiq_inline do
          it 'does not cancel the pipeline' do
            perform

            pipeline.reload

            expect(pipeline).not_to be_canceled
            expect(pipeline.builds.first).not_to be_canceled
            expect(pipeline.builds.first.auto_canceled_by_id).to be_nil
            expect(pipeline.auto_canceled_by_id).to be_nil
          end
        end
      end

      context 'when the user id exists' do
        context 'when the user can cancel the pipeline' do
          let_it_be(:project) { create(:project) }
          let_it_be(:pipeline) { create(:ci_pipeline, :running, project: project) }
          let_it_be(:current_user) { project.owner }

          it_behaves_like 'an idempotent worker', :sidekiq_inline do
            it 'cancels the pipeline' do
              perform

              pipeline.reload

              expect(pipeline).to be_canceled
              expect(pipeline.builds.first).to be_canceled
              expect(pipeline.builds.first.auto_canceled_by_id).to eq pipeline.id
              expect(pipeline.auto_canceled_by_id).to eq pipeline.id
            end
          end
        end

        context 'when the user cannot cancel the pipeline' do
          it_behaves_like 'an idempotent worker', :sidekiq_inline do
            it 'does not cancel the pipeline' do
              perform

              pipeline.reload

              expect(pipeline).not_to be_canceled
              expect(pipeline.builds.first).not_to be_canceled
              expect(pipeline.builds.first.auto_canceled_by_id).to be_nil
              expect(pipeline.auto_canceled_by_id).to be_nil
            end
          end
        end
      end
    end
  end
end
