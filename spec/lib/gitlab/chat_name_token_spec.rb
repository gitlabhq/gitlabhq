# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ChatNameToken do
  context 'when using unknown token' do
    let(:token) {}

    subject { described_class.new(token).get }

    it 'returns empty data' do
      is_expected.to be_nil
    end
  end

  context 'when storing data' do
    let(:data) { { key: 'value' } }

    subject { described_class.new(@token) }

    before do
      @token = described_class.new.store!(data)
    end

    it 'returns stored data' do
      expect(subject.get).to eq(data)
    end

    context 'and after deleting them' do
      before do
        subject.delete
      end

      it 'data are removed' do
        expect(subject.get).to be_nil
      end
    end
  end
end
