# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SilentMode, feature_category: :geo_replication do
  before do
    stub_application_setting(silent_mode_enabled: silent_mode)
  end

  describe '.enabled?' do
    context 'when silent mode is enabled' do
      let(:silent_mode) { true }

      it { expect(described_class.enabled?).to be_truthy }
    end

    context 'when silent mode is disabled' do
      let(:silent_mode) { false }

      it { expect(described_class.enabled?).to be_falsey }
    end
  end

  describe '.log_info' do
    let(:log_args) do
      {
        message: 'foo',
        bar: 'baz'
      }
    end

    let(:expected_log_args) { log_args.merge(silent_mode_enabled: silent_mode) }

    context 'when silent mode is enabled' do
      let(:silent_mode) { true }

      it 'logs to AppJsonLogger and adds the current state of silent mode' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(expected_log_args)

        described_class.log_info(log_args)
      end
    end

    context 'when silent mode is disabled' do
      let(:silent_mode) { false }

      it 'logs to AppJsonLogger and adds the current state of silent mode' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(expected_log_args)

        described_class.log_info(log_args)
      end

      it 'overwrites silent_mode_enabled log key if call already contains it' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(expected_log_args)

        described_class.log_info(log_args.merge(silent_mode_enabled: 'foo'))
      end
    end
  end

  describe '.log_debug' do
    let(:log_args) do
      {
        message: 'foo',
        bar: 'baz'
      }
    end

    let(:expected_log_args) { log_args.merge(silent_mode_enabled: silent_mode) }

    context 'when silent mode is enabled' do
      let(:silent_mode) { true }

      it 'logs to AppJsonLogger and adds the current state of silent mode' do
        expect(Gitlab::AppJsonLogger).to receive(:debug).with(expected_log_args)

        described_class.log_debug(log_args)
      end
    end

    context 'when silent mode is disabled' do
      let(:silent_mode) { false }

      it 'logs to AppJsonLogger and adds the current state of silent mode' do
        expect(Gitlab::AppJsonLogger).to receive(:debug).with(expected_log_args)

        described_class.log_debug(log_args)
      end

      it 'overwrites silent_mode_enabled log key if call already contains it' do
        expect(Gitlab::AppJsonLogger).to receive(:debug).with(expected_log_args)

        described_class.log_debug(log_args.merge(silent_mode_enabled: 'foo'))
      end
    end
  end
end
