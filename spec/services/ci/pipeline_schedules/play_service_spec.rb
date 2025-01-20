# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::PlayService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject(:execute_service) { service.execute(schedule) }

    let_it_be(:schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

    context 'when user can play the schedule' do
      before do
        allow(service).to receive(:can?).with(user, :play_pipeline_schedule, schedule).and_return(true)
      end

      it 'schedules next run' do
        expect(schedule).to receive(:schedule_next_run!)

        execute_service
      end

      it 'runs RunPipelineScheduleWorker' do
        expect(RunPipelineScheduleWorker)
          .to receive(:perform_async).with(schedule.id, schedule.owner.id)

        execute_service
      end

      context 'when owner is nil' do
        let(:schedule) { create(:ci_pipeline_schedule, project: project, owner: nil) }

        it 'does not raise an error' do
          expect { execute_service }.not_to raise_error
        end
      end

      context 'when the project is missing' do
        let_it_be(:project) { create(:project).tap(&:delete) }

        it 'does not raise an exception' do
          expect { execute_service }.not_to raise_error
        end

        it "returns a service response error" do
          expect(execute_service).to be_error
        end

        it 'does not run RunPipelineScheduleWorker' do
          expect(RunPipelineScheduleWorker)
            .not_to receive(:perform_async).with(schedule.id, schedule.owner.id)

          execute_service
        end
      end
    end

    context 'when user can not play the schedule' do
      before do
        allow(service).to receive(:can?).with(user, :play_pipeline_schedule, schedule).and_return(false)
      end

      it 'raises an AccessDeniedError' do
        expect { execute_service }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
