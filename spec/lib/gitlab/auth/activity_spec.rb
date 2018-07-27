require 'spec_helper'

describe Gitlab::Auth::Activity do
  describe '#each_counter' do
    it 'has all static counters defined' do
      described_class.each_counter do |counter|
        expect(described_class).to respond_to(counter)
      end
    end

    # todo incrementer pairs
    # todo all metrics starting with `user`_
  end
end
