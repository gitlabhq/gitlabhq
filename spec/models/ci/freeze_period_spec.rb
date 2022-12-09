# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::FreezePeriod, feature_category: :release_orchestration, type: :model do
  let_it_be(:project) { create(:project) }

  # Freeze period factory is on a weekend, so we travel in time, in and around that.
  let(:friday_2300_time)   { Time.utc(2020, 4, 10, 23, 0) }
  let(:saturday_1200_time) { Time.utc(2020, 4, 11, 12, 0) }
  let(:monday_0700_time)   { Time.utc(2020, 4, 13, 7, 0) }
  let(:tuesday_0800_time)  { Time.utc(2020, 4, 14, 8, 0) }

  subject { build(:ci_freeze_period) }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:project) }
    let!(:model)  { create(:ci_freeze_period, project: parent) }
  end

  it { is_expected.to belong_to(:project) }

  it { is_expected.to respond_to(:freeze_start) }
  it { is_expected.to respond_to(:freeze_end) }
  it { is_expected.to respond_to(:cron_timezone) }

  describe 'cron validations' do
    let(:invalid_cron) { '0 0 0 * *' }

    it 'allows valid cron patterns' do
      freeze_period = build_stubbed(:ci_freeze_period)

      expect(freeze_period).to be_valid
    end

    it 'does not allow invalid cron patterns on freeze_start' do
      freeze_period = build_stubbed(:ci_freeze_period, freeze_start: invalid_cron)

      expect(freeze_period).not_to be_valid
    end

    it 'does not allow invalid cron patterns on freeze_end' do
      freeze_period = build_stubbed(:ci_freeze_period, freeze_end: invalid_cron)

      expect(freeze_period).not_to be_valid
    end

    it 'does not allow an invalid timezone' do
      freeze_period = build_stubbed(:ci_freeze_period, cron_timezone: 'invalid')

      expect(freeze_period).not_to be_valid
    end

    context 'when cron contains trailing whitespaces' do
      it 'strips the attribute' do
        freeze_period = build_stubbed(:ci_freeze_period, freeze_start: ' 0 0 * * *   ')

        expect(freeze_period).to be_valid
        expect(freeze_period.freeze_start).to eq('0 0 * * *')
      end
    end
  end

  shared_examples 'within freeze period' do |time|
    it 'is frozen' do
      travel_to(time) do
        expect(subject).to eq(Ci::FreezePeriod::STATUS_ACTIVE)
      end
    end
  end

  shared_examples 'outside freeze period' do |time|
    it 'is not frozen' do
      travel_to(time) do
        expect(subject).to eq(Ci::FreezePeriod::STATUS_INACTIVE)
      end
    end
  end

  describe '#status' do
    subject { freeze_period.status }

    describe 'single freeze period' do
      let(:freeze_period) do
        build_stubbed(:ci_freeze_period, project: project)
      end

      it_behaves_like 'outside freeze period', Time.utc(2020, 4, 10, 22, 59)
      it_behaves_like 'within freeze period',  Time.utc(2020, 4, 10, 23, 1)
      it_behaves_like 'within freeze period',  Time.utc(2020, 4, 13, 6, 59)
      it_behaves_like 'outside freeze period', Time.utc(2020, 4, 13, 7, 1)
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/370472
    context 'when period overlaps with itself' do
      let(:freeze_period) do
        build_stubbed(:ci_freeze_period, project: project, freeze_start: '* * * 8 *', freeze_end: '* * * 10 *')
      end

      it_behaves_like 'within freeze period',  Time.utc(2020, 8, 11, 0, 0)
      it_behaves_like 'outside freeze period', Time.utc(2020, 10, 11, 0, 0)
    end
  end

  shared_examples 'a freeze period method' do
    let(:freeze_period) { build_stubbed(:ci_freeze_period, project: project) }

    it 'returns the correct value' do
      travel_to(now) do
        expect(freeze_period.send(method)).to eq(expected)
      end
    end
  end

  describe '#active?' do
    context 'when freeze period status is active' do
      it_behaves_like 'a freeze period method' do
        let(:now) { saturday_1200_time }
        let(:method) { :active? }
        let(:expected) { true }
      end
    end

    context 'when freeze period status is inactive' do
      it_behaves_like 'a freeze period method' do
        let(:now) { tuesday_0800_time }
        let(:method) { :active? }
        let(:expected) { false }
      end
    end
  end

  describe '#time_start' do
    it_behaves_like 'a freeze period method' do
      let(:now) { monday_0700_time }
      let(:method) { :time_start }
      let(:expected) { friday_2300_time }
    end
  end

  describe '#next_time_start' do
    let(:next_friday_2300_time) { Time.utc(2020, 4, 17, 23, 0) }

    it_behaves_like 'a freeze period method' do
      let(:now) { monday_0700_time }
      let(:method) { :next_time_start }
      let(:expected) { next_friday_2300_time }
    end
  end

  describe '#time_end_from_now' do
    it_behaves_like 'a freeze period method' do
      let(:now) { saturday_1200_time }
      let(:method) { :time_end_from_now }
      let(:expected) { monday_0700_time }
    end
  end

  describe '#time_end_from_start' do
    it_behaves_like 'a freeze period method' do
      let(:now) { saturday_1200_time }
      let(:method) { :time_end_from_start }
      let(:expected) { monday_0700_time }
    end
  end
end
