# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DowntimeCheck::Message do
  describe '#to_s' do
    it 'returns an ANSI formatted String for an offline migration' do
      message = described_class.new('foo.rb', true, 'hello')

      expect(message.to_s).to eq("[\e[31moffline\e[0m]: foo.rb:\n\nhello\n\n")
    end

    it 'returns an ANSI formatted String for an online migration' do
      message = described_class.new('foo.rb')

      expect(message.to_s).to eq("[\e[32monline\e[0m]: foo.rb")
    end
  end

  describe '#reason?' do
    it 'returns false when no reason is specified' do
      message = described_class.new('foo.rb')

      expect(message.reason?).to eq(false)
    end

    it 'returns true when a reason is specified' do
      message = described_class.new('foo.rb', true, 'hello')

      expect(message.reason?).to eq(true)
    end
  end

  describe '#reason' do
    it 'strips excessive whitespace from the returned String' do
      message = described_class.new('foo.rb', true, " hello\n world\n\n foo")

      expect(message.reason).to eq("hello\nworld\n\nfoo")
    end
  end
end
