# encoding: utf-8
require 'rails_helper'

describe Blob do
  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil)).to be_nil
    end
  end

  describe '#data' do
    context 'using a binary blob' do
      it 'returns the data as-is' do
        data = "\n\xFF\xB9\xC3"
        blob = described_class.new(double(binary?: true, data: data))

        expect(blob.data).to eq(data)
      end
    end

    context 'using a text blob' do
      it 'converts the data to UTF-8' do
        blob = described_class.new(double(binary?: false, data: "\n\xFF\xB9\xC3"))

        expect(blob.data).to eq("\n���")
      end
    end
  end

  # TODO: Test new methods
end
