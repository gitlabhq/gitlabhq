require 'spec_helper'

describe Forever do
  describe '.date' do
    subject { described_class.date }

    it 'returns Postgresql future date' do
      Timecop.travel(Date.new(2999, 12, 31)) do
        is_expected.to be > Date.today
      end
    end
  end
end
