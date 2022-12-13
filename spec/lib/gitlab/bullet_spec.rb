# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Bullet do
  context 'with bullet installed' do
    before do
      stub_env('ENABLE_BULLET', nil)
      stub_const('::Bullet', double)
    end

    describe '#enabled?' do
      context 'with env enabled' do
        before do
          stub_env('ENABLE_BULLET', true)
          allow(Gitlab.config.bullet).to receive(:enabled).and_return(false)
        end

        it 'is enabled' do
          expect(described_class.enabled?).to be(true)
        end
      end

      context 'with env disabled' do
        before do
          stub_env('ENABLE_BULLET', false)
          allow(Gitlab.config.bullet).to receive(:enabled).and_return(true)
        end

        it 'is not enabled' do
          expect(described_class.enabled?).to be(false)
        end
      end
    end

    describe '#configure_bullet?' do
      context 'with config enabled' do
        before do
          allow(Gitlab.config.bullet).to receive(:enabled).and_return(true)
        end

        it 'is configurable' do
          expect(described_class.configure_bullet?).to be(true)
        end
      end

      context 'with config disabled' do
        before do
          allow(Gitlab.config.bullet).to receive(:enabled).and_return(false)
        end

        it 'is not configurable' do
          expect(described_class.configure_bullet?).to be(false)
        end
      end
    end
  end
end
