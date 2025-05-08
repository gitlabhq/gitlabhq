# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Bullet, feature_category: :shared do
  context 'with bullet installed' do
    before do
      stub_env('ENABLE_BULLET', nil)
    end

    around do |example|
      bullet_enabled = ::Bullet.enabled?
      example.run
      ::Bullet.enable = bullet_enabled
    end

    describe '#enabled?' do
      context 'with env enabled' do
        before do
          stub_env('ENABLE_BULLET', true)
        end

        it 'is enabled' do
          expect(described_class).to be_enabled
        end
      end

      context 'with env disabled' do
        before do
          stub_env('ENABLE_BULLET', false)
        end

        it 'is not enabled' do
          expect(described_class).not_to be_enabled
        end
      end
    end

    describe '#configure_bullet?' do
      context 'with Bullet not defined' do
        before do
          allow(described_class).to receive(:defined?).with(::Bullet).and_return(false)
        end

        it 'is not configurable' do
          expect(described_class.configure_bullet?).to be(false)
        end
      end

      context 'with Bullet defined' do
        before do
          stub_const('::Bullet', class_double(::Bullet))
        end

        context 'when enabled? == true' do
          before do
            allow(described_class).to receive(:enabled?).and_return(true)
          end

          it 'is configurable' do
            expect(described_class).to be_configure_bullet
          end
        end

        context 'when enabled? == false' do
          context 'with config enabled' do
            before do
              allow(Gitlab.config.bullet).to receive(:enabled).and_return(true)
            end

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

    describe '#skip_bullet' do
      context 'with configure_bullet? == true' do
        before do
          allow(described_class).to receive(:configure_bullet?).and_return(true)
          ::Bullet.enable = true
        end

        it 'disables Bullet in the block' do
          bullet_enabled_in_block = described_class.skip_bullet { ::Bullet.enabled? }

          expect(bullet_enabled_in_block).to be false
        end

        it 'does not change the enable state of Bullet' do
          expect { described_class.skip_bullet { 42 } }.not_to change { ::Bullet.enabled? }
        end
      end

      context 'with configure_bullet? == false' do
        before do
          allow(described_class).to receive(:configure_bullet?).and_return(false)
        end

        it 'does not disable Bullet in the block' do
          expect(::Bullet).not_to receive(:enable=)

          result = described_class.skip_bullet { 42 }

          expect(result).to eq(42)
        end

        it 'does not change the enable state of Bullet' do
          expect { described_class.skip_bullet { 42 } }.not_to change { ::Bullet.enabled? }
        end
      end
    end
  end
end
