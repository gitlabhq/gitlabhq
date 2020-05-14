# frozen_string_literal: true
require 'spec_helper'

describe Ci::FreezePeriodStatus do
  let(:project) { create :project }
  # '0 23 * * 5' == "At 23:00 on Friday."", '0 7 * * 1' == "At 07:00 on Monday.""
  let(:friday_2300) { '0 23 * * 5' }
  let(:monday_0700) { '0 7 * * 1' }

  subject { described_class.new(project: project).execute }

  shared_examples 'within freeze period' do |time|
    it 'is frozen' do
      Timecop.freeze(time) do
        expect(subject).to be_truthy
      end
    end
  end

  shared_examples 'outside freeze period' do |time|
    it 'is not frozen' do
      Timecop.freeze(time) do
        expect(subject).to be_falsy
      end
    end
  end

  describe 'single freeze period' do
    let!(:freeze_period) { create(:ci_freeze_period, project: project, freeze_start: friday_2300, freeze_end: monday_0700) }

    it_behaves_like 'outside freeze period', Time.utc(2020, 4, 10, 22, 59)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 10, 23, 1)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 13, 6, 59)

    it_behaves_like 'outside freeze period', Time.utc(2020, 4, 13, 7, 1)
  end

  describe 'multiple freeze periods' do
    # '30 23 * * 5' == "At 23:30 on Friday."", '0 8 * * 1' == "At 08:00 on Monday.""
    let(:friday_2330) { '30 23 * * 5' }
    let(:monday_0800) { '0 8 * * 1' }

    let!(:freeze_period_1) { create(:ci_freeze_period, project: project, freeze_start: friday_2300, freeze_end: monday_0700) }
    let!(:freeze_period_2) { create(:ci_freeze_period, project: project, freeze_start: friday_2330, freeze_end: monday_0800) }

    it_behaves_like 'outside freeze period', Time.utc(2020, 4, 10, 22, 59)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 10, 23, 29)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 11, 10, 0)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 10, 23, 1)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 13, 6, 59)

    it_behaves_like 'within freeze period', Time.utc(2020, 4, 13, 7, 59)

    it_behaves_like 'outside freeze period', Time.utc(2020, 4, 13, 8, 1)
  end
end
