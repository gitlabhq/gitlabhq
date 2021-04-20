# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Bullet do
  describe '#enabled?' do
    it 'is enabled' do
      stub_env('ENABLE_BULLET', true)

      expect(described_class.enabled?).to be(true)
    end

    it 'is not enabled' do
      stub_env('ENABLE_BULLET', nil)

      expect(described_class.enabled?).to be(false)
    end

    it 'is correctly aliased for #extra_logging_enabled?' do
      expect(described_class.method(:extra_logging_enabled?).original_name).to eq(:enabled?)
    end
  end

  describe '#configure_bullet?' do
    context 'with ENABLE_BULLET true' do
      before do
        stub_env('ENABLE_BULLET', true)
      end

      it 'is configurable' do
        expect(described_class.configure_bullet?).to be(true)
      end
    end

    context 'with ENABLE_BULLET falsey' do
      before do
        stub_env('ENABLE_BULLET', nil)
      end

      it 'is not configurable' do
        expect(described_class.configure_bullet?).to be(false)
      end

      it 'is configurable in development' do
        allow(Rails).to receive_message_chain(:env, :development?).and_return(true)

        expect(described_class.configure_bullet?).to be(true)
      end
    end
  end
end
