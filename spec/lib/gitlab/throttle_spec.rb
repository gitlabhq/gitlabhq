# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Throttle do
  describe '.protected_paths_enabled?' do
    subject { described_class.protected_paths_enabled? }

    context 'when omnibus protected paths throttle should be used' do
      before do
        expect(described_class).to receive(:should_use_omnibus_protected_paths?).and_return(true)
      end

      it { is_expected.to be_falsey }
    end

    context 'when omnibus protected paths throttle should not be used' do
      before do
        expect(described_class).to receive(:should_use_omnibus_protected_paths?).and_return(false)
      end

      it 'returns Application Settings throttle_protected_paths_enabled?' do
        expect(Gitlab::CurrentSettings.current_application_settings).to receive(:throttle_protected_paths_enabled?)

        subject
      end
    end
  end

  describe '.should_use_omnibus_protected_paths?' do
    subject { described_class.should_use_omnibus_protected_paths? }

    context 'when rack_attack.admin_area_protected_paths_enabled config is unspecified' do
      context 'when the omnibus protected paths throttle has been recently used (it has data)' do
        before do
          expect(described_class).to receive(:omnibus_protected_paths_present?).and_return(true)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the omnibus protected paths throttle has not been recently used' do
        before do
          expect(described_class).to receive(:omnibus_protected_paths_present?).and_return(false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when rack_attack.admin_area_protected_paths_enabled config is false' do
      before do
        stub_config(rack_attack: {
          admin_area_protected_paths_enabled: false
        })
      end

      context 'when the omnibus protected paths throttle has been recently used (it has data)' do
        before do
          expect(described_class).to receive(:omnibus_protected_paths_present?).and_return(true)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the omnibus protected paths throttle has not been recently used' do
        before do
          expect(described_class).to receive(:omnibus_protected_paths_present?).and_return(false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when rack_attack.admin_area_protected_paths_enabled config is true' do
      before do
        stub_config(rack_attack: {
          admin_area_protected_paths_enabled: true
        })

        expect(described_class).not_to receive(:omnibus_protected_paths_present?)
      end

      it { is_expected.to be_falsey }
    end
  end
end
