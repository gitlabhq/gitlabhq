# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineScheduleService do
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

    context 'when owner is nil' do
      let(:schedule) { create(:ci_pipeline_schedule, project: project, owner: nil) }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the project is missing' do
      before do
        project.delete
      end

      it 'does not raise an exception' do
        expect { subject }.not_to raise_error
      end

      it 'does not run RunPipelineScheduleWorker' do
        expect(RunPipelineScheduleWorker)
          .not_to receive(:perform_async).with(schedule.id, schedule.owner.id)

        subject
      end
    end
  end
end
