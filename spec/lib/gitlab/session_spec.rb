# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Session do
  it 'uses the current thread as a data store' do
    Thread.current[:session_storage] = { a: :b }

    expect(described_class.current).to eq(a: :b)
  ensure
    Thread.current[:session_storage] = nil
  end

  describe '#with_session' do
    it 'sets session hash' do
      described_class.with_session(one: 1) do
        expect(described_class.current).to eq(one: 1)
      end
    end

    it 'restores current store after' do
      described_class.with_session(two: 2) {}

      expect(described_class.current).to eq nil
    end
  end
end
