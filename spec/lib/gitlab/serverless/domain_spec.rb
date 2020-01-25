# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Serverless::Domain do
  describe '.generate_uuid' do
    it 'has 14 characters' do
      expect(described_class.generate_uuid.length).to eq(described_class::UUID_LENGTH)
    end

    it 'consists of only hexadecimal characters' do
      expect(described_class.generate_uuid).to match(/\A\h+\z/)
    end

    it 'uses random characters' do
      uuid = 'abcd1234567890'

      expect(SecureRandom).to receive(:hex).with(described_class::UUID_LENGTH / 2).and_return(uuid)
      expect(described_class.generate_uuid).to eq(uuid)
    end
  end
end
