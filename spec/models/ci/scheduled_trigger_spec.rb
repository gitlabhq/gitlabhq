require 'spec_helper'

describe Ci::ScheduledTrigger, models: true do

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:owner) }
  end

  describe '#schedule_next_run!' do
    subject { scheduled_trigger.schedule_next_run! }

    let(:scheduled_trigger) { create(:ci_scheduled_trigger, :cron_nightly_build, next_run_at: nil) }

    it 'updates next_run_at' do
      is_expected.not_to be_nil
    end
  end

  describe '#update_last_run!' do
    subject { scheduled_trigger.update_last_run! }

    let(:scheduled_trigger) { create(:ci_scheduled_trigger, :cron_nightly_build, last_run_at: nil) }

    it 'updates last_run_at' do
      is_expected.not_to be_nil
    end
  end
end
