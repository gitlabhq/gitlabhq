# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Bullet, feature_category: :shared do
  context 'with bullet installed' do
    around do |example|
      bullet_enabled = ::Bullet.enabled?
      example.run
      ::Bullet.enable = bullet_enabled
    end

    describe '#enabled?' do
      it 'delegates to Gitlab.config.bullet.enabled' do
        allow(Gitlab.config.bullet).to receive(:enabled).and_return('foo')

        expect(described_class.enabled?).to eq('foo')
      end
    end

    describe '#extra_logging_enabled?' do
      context 'with environment variable set' do
        before do
          stub_env('ENABLE_BULLET', 'true')
        end

        it 'is true' do
          expect(described_class.extra_logging_enabled?).to be(true)
        end
      end

      context 'with environment variable not set' do
        before do
          stub_env('ENABLE_BULLET', nil)
        end

        it 'is false' do
          expect(described_class.extra_logging_enabled?).to be(false)
        end
      end
    end

    describe '#configure_bullet?' do
      before do
        allow(Gitlab.config.bullet).to receive(:enabled).and_return(true)
      end

      context 'with Bullet not defined' do
        before do
          allow(Object).to receive(:const_defined?).with(:Bullet).and_return(false)
        end

        it 'is not configurable' do
          expect(described_class.configure_bullet?).to be(false)
        end
      end

      context 'with Bullet defined' do
        before do
          stub_const('::Bullet', class_double(::Bullet))
        end

        context 'with config enabled' do
          it 'is configurable' do
            expect(described_class).to be_configure_bullet
          end
        end

        context 'with config disabled' do
          before do
            allow(Gitlab.config.bullet).to receive(:enabled).and_return(false)
          end

          it 'is not configurable' do
            expect(described_class).not_to be_configure_bullet
          end
        end
      end
    end
  end
end
