require 'spec_helper'

describe Ci::TriggerSchedule, models: true do

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:trigger) }
  end

  describe '#schedule_next_run!' do
    subject { trigger_schedule.schedule_next_run! }

    let(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build, next_run_at: nil) }

    it 'updates next_run_at' do
      is_expected.not_to be_nil
    end
  end

  # describe '#update_last_run!' do
  #   subject { scheduled_trigger.update_last_run! }

  #   let(:scheduled_trigger) { create(:ci_scheduled_trigger, :cron_nightly_build, last_run_at: nil) }

  #   it 'updates last_run_at' do
  #     is_expected.not_to be_nil
  #   end
  # end
end
