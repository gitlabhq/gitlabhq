# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::RenderTimeout do
  def expect_timeout(period)
    block = proc {}

    expect(Timeout).to receive(:timeout).with(period) do |_, &block|
      expect(block).to eq(block)
    end

    described_class.timeout(&block)
  end

  it 'utilizes timeout for web' do
    expect_timeout(described_class::FOREGROUND)
  end

  it 'utilizes longer timeout for sidekiq' do
    allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)

    expect_timeout(described_class::BACKGROUND)
  end
end
