# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Instrumentation::Storage, :request_store, feature_category: :shared do
  subject(:storage) { described_class }

  describe '.active?' do
    context 'when SafeRequestStore is active' do
      it 'returns true' do
        allow(Gitlab::SafeRequestStore).to receive(:active?).and_return(true)

        expect(storage.active?).to be(true)
      end
    end

    context 'when SafeRequestStore is not active' do
      it 'returns false' do
        allow(Gitlab::SafeRequestStore).to receive(:active?).and_return(false)

        expect(storage.active?).to be(false)
      end
    end
  end

  it 'stores data' do
    storage[:a] = 1
    storage[:b] = 'hey'

    expect(storage[:a]).to eq(1)
    expect(storage[:b]).to eq('hey')
  end

  describe '.clear!' do
    it 'removes all values' do
      storage[:a] = 1
      storage[:b] = 'hey'

      storage.clear!

      expect(storage[:a]).to be_nil
      expect(storage[:b]).to be_nil
    end
  end

  # This is testing implementation details, but until we have a truly segregated
  # instrumentation data store, we need to make sure we do not "pollute" the
  # underlying RequestStore or interfere with other co-located data.
  describe 'backing storage' do
    it 'stores data in the instrumentation bucket' do
      storage[:a] = 1

      expect(::RequestStore[:instrumentation]).to eq({ a: 1 })
    end

    describe '.clear!' do
      it 'resets only the instrumentation bucket' do
        storage[:a] = 1
        storage[:b] = 'hey'
        ::RequestStore[:b] = 2

        storage.clear!

        expect(::RequestStore[:instrumentation]).to eq({})
        expect(::RequestStore[:b]).to eq(2)
      end
    end
  end
end
