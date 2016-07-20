require 'spec_helper'

describe Gitlab::DowntimeCheck::Message do
  describe '#to_s' do
    it 'returns an ANSI formatted String for an offline migration' do
      message = described_class.new('foo.rb', true, 'hello')

      expect(message.to_s).to eq("[\e[32moffline\e[0m]: foo.rb: hello")
    end

    it 'returns an ANSI formatted String for an online migration' do
      message = described_class.new('foo.rb')

      expect(message.to_s).to eq("[\e[31monline\e[0m]: foo.rb")
    end
  end
end
