# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sessions::CacheStoreCoder, feature_category: :system_access do
  let(:hash) { { a: 1, b: 2 } }

  shared_examples 'unmarshal' do
    it 'returns ActiveSupport::Cache::Entry object' do
      ret = load

      expect(ret).to be_an_instance_of(ActiveSupport::Cache::Entry)
      expect(ret.value).to eq(expected)
    end
  end

  describe '.load' do
    let(:expected) { hash }

    subject(:load) { described_class.load(serialized) }

    context 'with ActiveSupport::Cache::Entry value' do
      let(:serialized) { Marshal.dump(ActiveSupport::Cache::Entry.new(hash)) }

      it_behaves_like 'unmarshal'
    end

    context 'with hash value' do
      let(:serialized) { Marshal.dump(hash) }

      it_behaves_like 'unmarshal'
    end

    context 'with nil value' do
      let(:serialized) { Marshal.dump(nil) }
      let(:expected) { nil }

      it_behaves_like 'unmarshal'
    end
  end
end
