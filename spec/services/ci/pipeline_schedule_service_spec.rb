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
  end
end
