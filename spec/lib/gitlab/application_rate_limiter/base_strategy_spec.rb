# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::BaseStrategy do
  describe '#increment' do
    it 'raises NotImplementedError' do
      expect { subject.increment('cache_key', 0) }.to raise_error(NotImplementedError)
    end
  end

  describe '#read' do
    it 'raises NotImplementedError' do
      expect { subject.read('cache_key') }.to raise_error(NotImplementedError)
    end
  end
end
