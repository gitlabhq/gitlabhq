# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::FreezePeriod, type: :model do
  subject { build(:ci_freeze_period) }

  it { is_expected.to belong_to(:project) }

  it { is_expected.to respond_to(:freeze_start) }
  it { is_expected.to respond_to(:freeze_end) }
  it { is_expected.to respond_to(:cron_timezone) }

  describe 'cron validations' do
    it 'allows valid cron patterns' do
      freeze_period = build(:ci_freeze_period, freeze_start: '0 23 * * 5')

      expect(freeze_period).to be_valid
    end

    it 'does not allow invalid cron patterns' do
      freeze_period = build(:ci_freeze_period, freeze_start: '0 0 0 * *')

      expect(freeze_period).not_to be_valid
    end

    it 'does not allow non-cron strings' do
      freeze_period = build(:ci_freeze_period, cron_timezone: 'invalid')

      expect(freeze_period).not_to be_valid
    end

    context 'when cron contains trailing whitespaces' do
      it 'strips the attribute' do
        freeze_period = build(:ci_freeze_period, freeze_start: ' 0 0 * * *   ')

        expect(freeze_period).to be_valid
        expect(freeze_period.freeze_start).to eq('0 0 * * *')
      end
    end
  end
end
