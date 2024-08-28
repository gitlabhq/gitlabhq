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

  describe 'banzai_timeout_disabled?' do
    context 'when GITLAB_DISABLE_MARKDOWN_TIMEOUT set' do
      it 'returns true' do
        stub_env('GITLAB_DISABLE_MARKDOWN_TIMEOUT' => '1')

        expect(described_class.banzai_timeout_disabled?).to be_truthy
      end
    end

    context 'when GITLAB_DISABLE_MARKDOWN_TIMEOUT is not set' do
      it 'returns false' do
        expect(described_class.banzai_timeout_disabled?).to be_falsey
      end
    end
  end
end
