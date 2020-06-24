# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CronFreezePeriodTimezoneValidator do
  using RSpec::Parameterized::TableSyntax

  subject { create :ci_freeze_period }

  where(:freeze_start, :freeze_end, :is_valid) do
    '0 23 * * 5'  | '0 7 * * 1'  | true
    '0 23 * * 5'  | 'invalid'    | false
    'invalid'     | '0 7 * * 1'  | false
  end

  with_them do
    it 'crontab validation' do
      subject.freeze_start = freeze_start
      subject.freeze_end = freeze_end

      expect(subject.valid?).to eq(is_valid)
    end
  end
end
