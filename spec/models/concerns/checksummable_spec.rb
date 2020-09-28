# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Checksummable do
  subject do
    Class.new { include Checksummable }
  end

  describe ".crc32" do
    it 'returns the CRC32 of data' do
      expect(subject.crc32('abcd')).to eq 3984772369
    end
  end

  describe ".hexdigest" do
    it 'returns the SHA256 sum of the file' do
      expected = Digest::SHA256.file(__FILE__).hexdigest

      expect(subject.hexdigest(__FILE__)).to eq(expected)
    end
  end
end
