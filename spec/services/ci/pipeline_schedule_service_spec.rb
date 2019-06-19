# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineScheduleService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject { service.execute(schedule) }

    let(:schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

    it 'schedules next run' do
      expect(schedule).to receive(:schedule_next_run!)

      subject
    end

    it 'runs RunPipelineScheduleWorker' do
      expect(RunPipelineScheduleWorker)
        .to receive(:perform_async).with(schedule.id, schedule.owner.id)

      subject
    end

    context 'when ci_pipeline_schedule_async feature flag is disabled' do
      before do
        stub_feature_flags(ci_pipeline_schedule_async: false)
      end

      it 'runs RunPipelineScheduleWorker synchronously' do
        expect_next_instance_of(RunPipelineScheduleWorker) do |worker|
          expect(worker).to receive(:perform).with(schedule.id, schedule.owner.id)
        end

        subject
      end

      it 'calls Garbage Collection manually' do
        expect(GC).to receive(:start)

        subject
      end

      context 'when ci_pipeline_schedule_force_gc feature flag is disabled' do
        before do
          stub_feature_flags(ci_pipeline_schedule_force_gc: false)
        end

        it 'does not call Garbage Collection manually' do
          expect(GC).not_to receive(:start)

          subject
        end
      end
    end

    context 'when owner is nil' do
      let(:schedule) { create(:ci_pipeline_schedule, project: project, owner: nil) }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
