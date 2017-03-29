require 'spec_helper'

describe Ci::TriggerSchedule, models: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:trigger) { create(:ci_trigger, owner: user, project: project, ref: 'master') }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:trigger) }
  end

  describe 'validation' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build, trigger: trigger) }

    it { expect(trigger_schedule).to validate_presence_of(:trigger) }
    it { is_expected.to validate_presence_of(:cron) }
    it { is_expected.to validate_presence_of(:cron_time_zone) }

    it '#check_cron' do
      subject.cron = 'Hack'
      subject.valid?
      subject.errors[:screen_name].to include(' is invalid syntax')
    end

    it '#check_ref' do
    end
  end

  describe '#schedule_next_run!' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build, next_run_at: nil, trigger: trigger) }

    before do
      trigger_schedule.schedule_next_run!
    end

    it 'updates next_run_at' do
      expect(Ci::TriggerSchedule.last.next_run_at).not_to be_nil
    end
  end
end
