require 'spec_helper'

describe Gitlab::Auth::Activity do
  describe 'counters' do
    it 'has all static counters defined' do
      described_class::COUNTERS.each_key do |metric|
        expect(described_class).to respond_to("#{metric}_counter")
      end
    end
  end
end
