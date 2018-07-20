require 'spec_helper'

describe Gitlab::Auth::Activity do
  describe 'counters' do
    it 'has all static counters defined' do
      described_class.each_counter do |counter|
        expect(described_class).to respond_to(counter)
      end
    end
  end
end
