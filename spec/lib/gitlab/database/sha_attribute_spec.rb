# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::ShaAttribute do
  let(:sha) do
    '9a573a369a5bfbb9a4a36e98852c21af8a44ea8b'
  end

  let(:binary_sha) do
    [sha].pack('H*')
  end

  let(:binary_from_db) do
    "\\x#{sha}"
  end

  let(:attribute) { described_class.new }

  describe '#deserialize' do
    it 'converts the binary SHA to a String' do
      expect(attribute.deserialize(binary_from_db)).to eq(sha)
    end
  end

  describe '#serialize' do
    it 'converts a SHA String to binary data' do
      expect(described_class.serialize(sha).to_s).to eq(binary_sha)
    end
  end
end
